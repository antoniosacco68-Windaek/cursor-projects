# Script ottimizzato per inviare email in batch tramite Gmail API
# Versione batch che supporta elaborazione parallela

# Parametri in ingresso
param(
    [Parameter(Mandatory=$true, ParameterSetName="SingleEmail")]
    [string]$EmailID,
    
    [Parameter(Mandatory=$true, ParameterSetName="BatchFile")]
    [string]$BatchFile,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrentJobs = 5
)

# Imposta timeout più elevato per le operazioni di lunga durata
$OperationTimeout = 120 # secondi

# Inizializza logging
$logFile = "C:\Antonio\Logs\email_processing_$(Get-Date -Format 'yyyyMMdd').log"
$logDir = Split-Path -Path $logFile -Parent

if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO",
        [string]$EmailID = ""
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] "
    
    if (-not [string]::IsNullOrEmpty($EmailID)) {
        $logEntry += "[$EmailID] "
    }
    
    $logEntry += $Message
    
    Add-Content -Path $logFile -Value $logEntry
    
    # Output per SQL Server
    if ($Level -eq "ERROR" -or $Level -eq "SUCCESS") {
        Write-Output "$Level|$EmailID|$Message"
    }
}

# Pre-carica le DLL necessarie una sola volta
Write-Log "Caricamento delle librerie necessarie"
if (-not ([System.Management.Automation.PSTypeName]'Google.Apis.Gmail.v1.GmailService').Type) {
    $dllPaths = @(
        "C:\Antonio\GoogleApi\lib\Newtonsoft.Json.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Core.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Auth.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Gmail.v1.dll"
    )
    
    foreach ($dll in $dllPaths) {
        try {
            Add-Type -Path $dll -ErrorAction Stop
        } catch {
            $errorMsg = "Impossibile caricare $dll - $($_.Exception.Message)"
            Write-Log $errorMsg "ERROR"
            Write-Output "ERRORE||$errorMsg"
            exit 1
        }
    }
}

# Carica assembly SqlClient 
if (-not ([System.Management.Automation.PSTypeName]'System.Data.SqlClient.SqlConnection').Type) {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Data")
}

# Funzione per inviare una singola email
function Send-SingleEmail {
    param (
        [Parameter(Mandatory=$true)]
        [string]$EmailID
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        # Connessione al database ottimizzata con connection pooling
        $connectionString = "Server=localhost;Database=I24DB;Trusted_Connection=True;Connection Timeout=30;Pooling=true;Min Pool Size=5;Max Pool Size=100;"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
    
        # Ottimizzazione: recupera tutti i dati con una sola query
        $command = New-Object System.Data.SqlClient.SqlCommand
        $command.Connection = $connection
        $command.CommandText = "SELECT [Mittente], ISNULL([NomeMittente], '') AS NomeMittente, 
                                     [Destinatario], [Oggetto], [Corpo], 
                                     ISNULL([CC], '') AS CC, ISNULL([CCN], '') AS CCN, 
                                     ISNULL([FormatoHTML], 1) AS FormatoHTML, 
                                     ISNULL([Allegato], '') AS Allegato 
                               FROM [dbo].[EmailDataDaProcessare] 
                               WHERE [ID] = @Id"
        $command.Parameters.AddWithValue("@Id", $EmailID)
        $command.CommandTimeout = $OperationTimeout
        
        # Utilizzo di DataAdapter per recuperare risultati più velocemente
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataTable = New-Object System.Data.DataTable
        $adapter.Fill($dataTable)
        
        if ($dataTable.Rows.Count -eq 0) {
            throw "Email ID non trovato nel database: $EmailID"
        }
        
        $row = $dataTable.Rows[0]
        
        # Lettura dati
        $Mittente = $row["Mittente"]
        $NomeMittente = $row["NomeMittente"]
        $Destinatario = $row["Destinatario"]
        $Oggetto = $row["Oggetto"]
        $Corpo = $row["Corpo"]
        $CC = $row["CC"]
        $CCN = $row["CCN"]
        $isHtml = $row["FormatoHTML"]
        $Allegato = $row["Allegato"]
        
        # Validazione email
        if ([string]::IsNullOrWhiteSpace($Destinatario) -or $Destinatario -notlike "*@*.*") {
            throw "Indirizzo email destinatario non valido: $Destinatario"
        }
        
        Write-Log "Preparazione email per $Destinatario" "INFO" $EmailID
        
        # Autentica con Google - cache credenziali per velocizzare
        $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"
        
        if (-not (Test-Path $serviceAccountKeyPath)) {
            throw "File delle credenziali non trovato: $serviceAccountKeyPath"
        }
        
        # Inizializzazione servizio Gmail
        $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
        $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
        $delegated = $scoped.CreateWithUser($Mittente)
        
        $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
        $initializer.HttpClientInitializer = $delegated
        $initializer.ApplicationName = "SQL Email Sender Batch"
        
        $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer
        
        # Ottimizzazione della creazione dell'email con StringBuilder
        $boundary = [System.Guid]::NewGuid().ToString().Replace("-","")
        $hasAttachments = -not [string]::IsNullOrEmpty($Allegato)
        $contentBuilder = New-Object System.Text.StringBuilder(4096) # Dimensione iniziale maggiore
        
        # Header email
        [void]$contentBuilder.AppendLine("MIME-Version: 1.0")
        [void]$contentBuilder.AppendLine("From: `"$NomeMittente`" <$Mittente>")
        [void]$contentBuilder.AppendLine("To: $Destinatario")
        
        if (-not [string]::IsNullOrEmpty($CC)) {
            [void]$contentBuilder.AppendLine("Cc: $CC")
        }
        
        if (-not [string]::IsNullOrEmpty($CCN)) {
            [void]$contentBuilder.AppendLine("Bcc: $CCN")
        }
        
        [void]$contentBuilder.AppendLine("Subject: $Oggetto")
        
        # Costruisci l'email in base al tipo
        if ($hasAttachments) {
            [void]$contentBuilder.AppendLine("Content-Type: multipart/mixed; boundary=`"$boundary`"")
        } elseif ($isHtml) {
            [void]$contentBuilder.AppendLine("Content-Type: text/html; charset=UTF-8")
            [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
        } else {
            [void]$contentBuilder.AppendLine("Content-Type: text/plain; charset=UTF-8")
            [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
        }
        
        [void]$contentBuilder.AppendLine("")
        [void]$contentBuilder.AppendLine("")
        
        # Corpo email
        if ($hasAttachments) {
            if ($isHtml) {
                [void]$contentBuilder.AppendLine("--$boundary")
                [void]$contentBuilder.AppendLine("Content-Type: text/html; charset=UTF-8")
                [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
                [void]$contentBuilder.AppendLine("")
                [void]$contentBuilder.AppendLine($Corpo)
                [void]$contentBuilder.AppendLine("")
            } else {
                [void]$contentBuilder.AppendLine("--$boundary")
                [void]$contentBuilder.AppendLine("Content-Type: text/plain; charset=UTF-8")
                [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
                [void]$contentBuilder.AppendLine("")
                [void]$contentBuilder.AppendLine($Corpo)
                [void]$contentBuilder.AppendLine("")
            }
            
            # Processa allegati in modo più efficiente
            $allegati = $Allegato -split ";"
            
            foreach ($path in $allegati) {
                if ([string]::IsNullOrWhiteSpace($path)) { continue }
                
                $path = $path.Trim()
                
                if (Test-Path $path) {
                    $fileName = [System.IO.Path]::GetFileName($path)
                    
                    # Ottimizzazione lettura file
                    $fileBytes = [System.IO.File]::ReadAllBytes($path)
                    $fileBase64 = [System.Convert]::ToBase64String($fileBytes)
                    
                    # Mappa MIME type
                    $extension = [System.IO.Path]::GetExtension($path).ToLower()
                    $mimeTypes = @{
                        ".pdf"  = "application/pdf"
                        ".txt"  = "text/plain"
                        ".csv"  = "text/csv"
                        ".doc"  = "application/msword"
                        ".docx" = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
                        ".xls"  = "application/vnd.ms-excel"
                        ".xlsx" = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        ".png"  = "image/png"
                        ".jpg"  = "image/jpeg"
                        ".jpeg" = "image/jpeg"
                        ".gif"  = "image/gif"
                        ".zip"  = "application/zip"
                    }
                    
                    $mimeType = $mimeTypes[$extension]
                    if (-not $mimeType) { $mimeType = "application/octet-stream" }
                    
                    [void]$contentBuilder.AppendLine("--$boundary")
                    [void]$contentBuilder.AppendLine("Content-Type: $mimeType; name=`"$fileName`"")
                    [void]$contentBuilder.AppendLine("Content-Disposition: attachment; filename=`"$fileName`"")
                    [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: base64")
                    [void]$contentBuilder.AppendLine("")
                    
                    # Formattazione Base64 ottimizzata
                    for ($i = 0; $i -lt $fileBase64.Length; $i += 76) {
                        if ($i + 76 -le $fileBase64.Length) {
                            [void]$contentBuilder.AppendLine($fileBase64.Substring($i, 76))
                        } else {
                            [void]$contentBuilder.AppendLine($fileBase64.Substring($i))
                        }
                    }
                    
                    [void]$contentBuilder.AppendLine("")
                    
                    # Libera memoria
                    $fileBytes = $null
                    $fileBase64 = $null
                    [System.GC]::Collect()
                } else {
                    Write-Log "File allegato non trovato: $path" "WARNING" $EmailID
                }
            }
            
            [void]$contentBuilder.AppendLine("--$boundary--")
        } else {
            [void]$contentBuilder.Append($Corpo)
        }
        
        # Ottieni il contenuto dell'email
        $emailContent = $contentBuilder.ToString()
        
        # Codifica Base64 RFC 2045
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($emailContent)
        $rawMessage = [System.Convert]::ToBase64String($bytes)
        $rawMessage = $rawMessage.Replace("+", "-").Replace("/", "_")
        
        # Invio dell'email con retry
        $maxRetries = 3
        $retryCount = 0
        $success = $false
        
        while (-not $success -and $retryCount -lt $maxRetries) {
            try {
                $msg = New-Object Google.Apis.Gmail.v1.Data.Message
                $msg.Raw = $rawMessage
                
                $response = $service.Users.Messages.Send($msg, "me").Execute()
                $success = $true
                
                Write-Log "Email inviata correttamente a $Destinatario" "SUCCESS" $EmailID
                
                # Aggiorna il database con il successo
                $updateCmd = New-Object System.Data.SqlClient.SqlCommand
                $updateCmd.Connection = $connection
                $updateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Inviata] = 1, [DataInvio] = GETDATE(), [EmailID] = @EmailID, [Note] = NULL WHERE [ID] = @Id"
                $updateCmd.Parameters.AddWithValue("@EmailID", $response.Id)
                $updateCmd.Parameters.AddWithValue("@Id", $EmailID)
                $updateCmd.CommandTimeout = 30
                $updateCmd.ExecuteNonQuery()
                
                return "SUCCESSO|$($response.Id)|Email inviata correttamente a $Destinatario"
            } catch {
                $retryCount++
                $errorMsg = $_.Exception.Message
                
                if ($retryCount -lt $maxRetries) {
                    Write-Log "Tentativo $retryCount/$maxRetries fallito: $errorMsg" "WARNING" $EmailID
                    Start-Sleep -Seconds (2 * $retryCount) # Backoff esponenziale
                } else {
                    Write-Log "Invio fallito dopo $maxRetries tentativi: $errorMsg" "ERROR" $EmailID
                    
                    # Aggiorna il database con l'errore
                    if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
                        $errorUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
                        $errorUpdateCmd.Connection = $connection
                        $errorUpdateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Note] = @ErrorMsg WHERE [ID] = @Id"
                        $errorUpdateCmd.Parameters.AddWithValue("@ErrorMsg", "ERRORE: $errorMsg")
                        $errorUpdateCmd.Parameters.AddWithValue("@Id", $EmailID)
                        $errorUpdateCmd.CommandTimeout = 30
                        $errorUpdateCmd.ExecuteNonQuery()
                    }
                    
                    return "ERRORE|$($EmailID)|$errorMsg"
                }
            }
        }
    } catch {
        $errorMsg = $_.Exception.Message
        Write-Log "Errore: $errorMsg" "ERROR" $EmailID
        
        # Aggiorna il database con l'errore
        try {
            if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
                $errorUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
                $errorUpdateCmd.Connection = $connection
                $errorUpdateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Note] = @ErrorMsg WHERE [ID] = @Id"
                $errorUpdateCmd.Parameters.AddWithValue("@ErrorMsg", "ERRORE: $errorMsg")
                $errorUpdateCmd.Parameters.AddWithValue("@Id", $EmailID)
                $errorUpdateCmd.CommandTimeout = 30
                $errorUpdateCmd.ExecuteNonQuery()
            }
        } catch {
            # In caso di errore di aggiornamento DB, logga ma continua
            Write-Log "Errore aggiornamento DB: $($_.Exception.Message)" "ERROR" $EmailID
        }
        
        return "ERRORE|$($EmailID)|$errorMsg"
    } finally {
        # Pulizia risorse
        $stopwatch.Stop()
        
        if ($adapter) { $adapter.Dispose() }
        if ($command) { $command.Dispose() }
        if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
            $connection.Close()
            $connection.Dispose()
        }
        
        if ($contentBuilder) { $contentBuilder.Clear() }
        
        Write-Log "Elaborazione completata in $($stopwatch.ElapsedMilliseconds)ms" "INFO" $EmailID
        
        # Forza garbage collection
        [System.GC]::Collect()
    }
}

# Elaborazione principale
$batchStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    if ($PSCmdlet.ParameterSetName -eq "SingleEmail") {
        # Modalità email singola
        Write-Log "Elaborazione email singola: $EmailID" "INFO"
        $result = Send-SingleEmail -EmailID $EmailID
        Write-Output $result
    } else {
        # Modalità batch da file
        if (-not (Test-Path $BatchFile)) {
            throw "File batch non trovato: $BatchFile"
        }
        
        Write-Log "Elaborazione batch da file: $BatchFile" "INFO"
        $emailIDs = Get-Content $BatchFile
        
        if ($emailIDs.Count -eq 0) {
            Write-Log "Nessuna email da processare nel file batch" "WARNING"
            Write-Output "SUCCESSO||Nessuna email da processare"
            exit 0
        }
        
        Write-Log "Trovate $($emailIDs.Count) email da processare" "INFO"
        
        # Elaborazione parallela limitata
        $jobs = @()
        $results = @()
        $concurrent = [Math]::Min($MaxConcurrentJobs, $emailIDs.Count)
        
        Write-Log "Avvio elaborazione parallela con $concurrent job concorrenti" "INFO"
        
        # Crea uno script block riutilizzabile con tutte le funzioni necessarie
        $scriptBlock = {
            param($EmailID, $Functions)
            
            # Importa le funzioni
            . ([ScriptBlock]::Create($Functions))
            
            # Elabora l'email
            Send-SingleEmail -EmailID $EmailID
        }
        
        # Ottieni le definizioni delle funzioni
        $functionDefs = (Get-Command Send-SingleEmail).ScriptBlock.ToString()
        
        # Avvia i job paralleli con throttling
        $runningJobs = 0
        $processedEmails = 0
        
        foreach ($id in $emailIDs) {
            # Attendi se abbiamo raggiunto il massimo di job concorrenti
            while (($jobs | Where-Object { $_.State -eq 'Running' }).Count -ge $concurrent) {
                Start-Sleep -Milliseconds 200
                
                # Controlla se qualche job è completato
                foreach ($job in ($jobs | Where-Object { $_.State -eq 'Completed' })) {
                    $result = Receive-Job -Job $job
                    $results += $result
                    Remove-Job -Job $job
                    Write-Output $result
                    $processedEmails++
                }
                
                # Rimuovi i job completati dalla lista
                $jobs = $jobs | Where-Object { $_.State -ne 'Completed' }
            }
            
            # Avvia un nuovo job
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $id, $functionDefs
            $jobs += $job
            
            Write-Log "Avviato job per email ID: $id" "INFO"
        }
        
        # Attendi il completamento di tutti i job
        while ($jobs.Count -gt 0) {
            Start-Sleep -Milliseconds 500
            
            # Controlla se qualche job è completato
            foreach ($job in ($jobs | Where-Object { $_.State -eq 'Completed' })) {
                $result = Receive-Job -Job $job
                $results += $result
                Remove-Job -Job $job
                Write-Output $result
                $processedEmails++
            }
            
            # Gestisci job falliti
            foreach ($job in ($jobs | Where-Object { $_.State -eq 'Failed' })) {
                $error = Receive-Job -Job $job
                Write-Log "Job fallito: $error" "ERROR"
                Remove-Job -Job $job
            }
            
            # Rimuovi i job completati o falliti dalla lista
            $jobs = $jobs | Where-Object { $_.State -ne 'Completed' -and $_.State -ne 'Failed' }
        }
        
        # Statistiche finali
        $successCount = ($results | Where-Object { $_ -like "SUCCESSO*" }).Count
        $errorCount = ($results | Where-Object { $_ -like "ERRORE*" }).Count
        
        Write-Log "Elaborazione batch completata. Successi: $successCount, Errori: $errorCount" "INFO"
        Write-Output "SUCCESSO||Elaborazione batch completata. Successi: $successCount, Errori: $errorCount"
    }
} catch {
    $errorMsg = $_.Exception.Message
    Write-Log "Errore critico: $errorMsg" "ERROR"
    Write-Output "ERRORE||$errorMsg"
    exit 1
} finally {
    $batchStopwatch.Stop()
    Write-Log "Tempo totale di elaborazione: $($batchStopwatch.ElapsedMilliseconds)ms" "INFO"
} 