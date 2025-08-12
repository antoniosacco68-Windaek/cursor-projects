# Script per inviare email tramite Gmail API

# Parametri in ingresso
param(
    [Parameter(Mandatory=$true)]
    [string]$EmailID,
    [Parameter(Mandatory=$false)]
    [int]$RitardoMinuti = 0
)

# Funzione per registrare il log
function Write-Log {
    param($Message)
    $logPath = "C:\Antonio\ScriptPowershell\EmailLog.txt"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logPath -Append
}

# Pre-carica le DLL necessarie
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
            Write-Log "DLL caricata: $dll"
        } catch {
            $errorMsg = "ERRORE: Impossibile caricare $dll - $($_.Exception.Message)"
            Write-Log $errorMsg
            throw $errorMsg
        }
    }
}

# Carica assembly SqlClient
if (-not ([System.Management.Automation.PSTypeName]'System.Data.SqlClient.SqlConnection').Type) {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Data")
}

try {
    # Registra l'inizio del processo
    Write-Log "Inizio processo per EmailID: $EmailID con ritardo di $RitardoMinuti minuti"
    
    # Attendi il tempo specificato
    Start-Sleep -Seconds ($RitardoMinuti * 60)
    
    # Inizializza variabili
    $connection = $null
    $CorpoFile = $null
    
    # Connessione al database
    $connectionString = "Server=localhost;Database=I24DB;Trusted_Connection=True;Connection Timeout=30;Pooling=true;Min Pool Size=5;Max Pool Size=100;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    # Query per ottenere i dati dell'email
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = "SELECT [Mittente], [NomeMittente], [Destinatario], [Oggetto], [Corpo], [CC], [CCN], [FormatoHTML], [Allegato] FROM [dbo].[EmailData] WHERE [ID] = @EmailGuid"
    $command.Parameters.AddWithValue("@EmailGuid", $EmailID)
    $command.CommandTimeout = 30
    
    $reader = $command.ExecuteReader()
    
    if ($reader.Read()) {
        # Leggi i dati dell'email
        $Mittente = $reader["Mittente"]
        $NomeMittente = if ($reader["NomeMittente"] -eq [DBNull]::Value) { "" } else { $reader["NomeMittente"] }
        $Destinatario = $reader["Destinatario"]
        $Oggetto = $reader["Oggetto"]
        $Corpo = $reader["Corpo"]
        $CC = if ($reader["CC"] -eq [DBNull]::Value) { "" } else { $reader["CC"] }
        $CCN = if ($reader["CCN"] -eq [DBNull]::Value) { "" } else { $reader["CCN"] }
        $isHtml = $reader["FormatoHTML"]
        $Allegato = if ($reader["Allegato"] -eq [DBNull]::Value) { "" } else { $reader["Allegato"] }
        
        # Chiudi il reader
        $reader.Close()
    } else {
        Write-Error "ERRORE: Email ID non trovato nel database: $EmailID"
        $reader.Close()
        $connection.Close()
        exit 1
    }
    
    # Autentica con Google
    $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"
    
    if (-not (Test-Path $serviceAccountKeyPath)) {
        Write-Error "ERRORE: File delle credenziali non trovato: $serviceAccountKeyPath"
        exit 1
    }
    
    # Creazione delle credenziali
    $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
    $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
    $delegated = $scoped.CreateWithUser($Mittente)
    
    $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
    $initializer.HttpClientInitializer = $delegated
    $initializer.ApplicationName = "SQL Email Sender"
    
    $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer
    
    # Genera un boundary per il MIME multipart
    $boundary = [System.Guid]::NewGuid().ToString().Replace("-","")
    
    # Verifica se ci sono allegati
    $hasAttachments = -not [string]::IsNullOrEmpty($Allegato)
    
    # Usa StringBuilder
    $contentBuilder = New-Object System.Text.StringBuilder(1024)
    
    # Inizializza gli header di base
    [void]$contentBuilder.AppendLine("MIME-Version: 1.0")
    
    # Debug del nome mittente
    Write-Log "Debug - Nome Mittente originale: '$NomeMittente', Mittente: '$Mittente'"
    
    # Gestione del nome mittente nell'header From
    if ([string]::IsNullOrEmpty($NomeMittente)) {
        [void]$contentBuilder.AppendLine("From: $Mittente")
        Write-Log "Header From: $Mittente"
    } else {
        # Formattazione RFC 2047 per l'header From - Codifica per nomi con caratteri non ASCII
        $nomeMittenteFormattato = "=?UTF-8?B?$([Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($NomeMittente)))?="
        [void]$contentBuilder.AppendLine("From: $nomeMittenteFormattato <$Mittente>")
        
        # Aggiungi ulteriori header per aumentare la probabilità che Gmail utilizzi il nome corretto
        [void]$contentBuilder.AppendLine("Sender: $Mittente")
        [void]$contentBuilder.AppendLine("Reply-To: $nomeMittenteFormattato <$Mittente>")
        [void]$contentBuilder.AppendLine("Disposition-Notification-To: $nomeMittenteFormattato <$Mittente>")
        
        Write-Log "Header From (codificato): $nomeMittenteFormattato <$Mittente>"
    }
    
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
        # Email con allegati
        [void]$contentBuilder.AppendLine("Content-Type: multipart/mixed; boundary=`"$boundary`"")
    } elseif ($isHtml) {
        # Email in HTML senza allegati
        [void]$contentBuilder.AppendLine("Content-Type: text/html; charset=UTF-8")
        [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
    } else {
        # Email in testo semplice senza allegati
        [void]$contentBuilder.AppendLine("Content-Type: text/plain; charset=UTF-8")
        [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
    }
    
    # Aggiungi spazio vuoto dopo gli header
    [void]$contentBuilder.AppendLine("")
    [void]$contentBuilder.AppendLine("")
    
    # Gestisci il corpo dell'email
    if ($hasAttachments) {
        # Per email con allegati
        if ($isHtml) {
            # Parte HTML
            [void]$contentBuilder.AppendLine("--$boundary")
            [void]$contentBuilder.AppendLine("Content-Type: text/html; charset=UTF-8")
            [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
            [void]$contentBuilder.AppendLine("")
            [void]$contentBuilder.AppendLine($Corpo)
            [void]$contentBuilder.AppendLine("")
        } else {
            # Parte Testo
            [void]$contentBuilder.AppendLine("--$boundary")
            [void]$contentBuilder.AppendLine("Content-Type: text/plain; charset=UTF-8")
            [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: 8bit")
            [void]$contentBuilder.AppendLine("")
            [void]$contentBuilder.AppendLine($Corpo)
            [void]$contentBuilder.AppendLine("")
        }
        
        # Processa gli allegati
        $allegati = $Allegato -split ";"

        foreach ($path in $allegati) {
            if ([string]::IsNullOrWhiteSpace($path)) { continue }
            
            $path = $path.Trim()
            
            if (Test-Path $path) {
                try {
                    $fileName = [System.IO.Path]::GetFileName($path)
                    $fileBytes = [System.IO.File]::ReadAllBytes($path)
                    $fileBase64 = [System.Convert]::ToBase64String($fileBytes)
                    
                    # Determina il MIME type del file
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
                    
                    $extension = [System.IO.Path]::GetExtension($path).ToLower()
                    $mimeType = $mimeTypes[$extension]
                    
                    if (-not $mimeType) {
                        $mimeType = "application/octet-stream"
                    }
                    
                    [void]$contentBuilder.AppendLine("--$boundary")
                    [void]$contentBuilder.AppendLine("Content-Type: $mimeType; name=`"$fileName`"")
                    [void]$contentBuilder.AppendLine("Content-Disposition: attachment; filename=`"$fileName`"")
                    [void]$contentBuilder.AppendLine("Content-Transfer-Encoding: base64")
                    [void]$contentBuilder.AppendLine("")
                    
                    # Formatta il Base64 in linee da 76 caratteri
                    for ($i = 0; $i -lt $fileBase64.Length; $i += 76) {
                        if ($i + 76 -le $fileBase64.Length) {
                            [void]$contentBuilder.AppendLine($fileBase64.Substring($i, 76))
                        } else {
                            [void]$contentBuilder.AppendLine($fileBase64.Substring($i))
                        }
                    }
                    
                    [void]$contentBuilder.AppendLine("")
                } catch {
                    Write-Error "Errore durante il processing dell'allegato $path : $($_.Exception.Message)"
                    throw
                }
            } else {
                Write-Error "File allegato non trovato: $path"
                throw
            }
        }
        
        # Chiudi il MIME multipart
        [void]$contentBuilder.AppendLine("--$boundary--")
    } else {
        # Email senza allegati
        [void]$contentBuilder.Append($Corpo)
    }
    
    # Ottieni il contenuto dell'email e registra gli header per debug
    $emailContent = $contentBuilder.ToString()
    
    # Mostra gli header per debug
    $headerLines = $emailContent.Split("`n") | Where-Object { $_ -match '^[A-Za-z-]+:' }
    Write-Log "Header dell'email:"
    foreach ($line in $headerLines) {
        Write-Log "  $line"
    }
    
    # Codifica Base64 RFC 2045
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($emailContent)
    $rawMessage = [System.Convert]::ToBase64String($bytes)
    $rawMessage = $rawMessage.Replace("+", "-").Replace("/", "_")
    
    # Invio dell'email
    $msg = New-Object Google.Apis.Gmail.v1.Data.Message
    $msg.Raw = $rawMessage
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $response = $service.Users.Messages.Send($msg, "me").Execute()
    $stopwatch.Stop()
    Write-Log "Tempo di esecuzione: $($stopwatch.ElapsedMilliseconds)ms"
    
    # Aggiorna lo stato di elaborazione
    $updateCmd = New-Object System.Data.SqlClient.SqlCommand
    $updateCmd.Connection = $connection
    $updateCmd.CommandText = "UPDATE [dbo].[EmailData] SET [StatoElaborazione] = 'In Elaborazione' WHERE [ID] = @EmailGuid"
    $updateCmd.Parameters.AddWithValue("@EmailGuid", $EmailID)
    $updateCmd.ExecuteNonQuery()
    
    # Aggiorna lo stato finale - crea un nuovo oggetto command per evitare problemi di parametri duplicati
    $finalUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
    $finalUpdateCmd.Connection = $connection
    $finalUpdateCmd.CommandText = "UPDATE [dbo].[EmailData] SET [Inviata] = 1, [DataInvio] = GETDATE(), [EmailID] = @GmailID, [StatoElaborazione] = 'Completata' WHERE [ID] = @EmailGuid"
    $finalUpdateCmd.Parameters.AddWithValue("@GmailID", $response.Id)
    $finalUpdateCmd.Parameters.AddWithValue("@EmailGuid", $EmailID)
    $finalUpdateCmd.ExecuteNonQuery()

    Write-Log "Email inviata con successo: $EmailID"
    Write-Output "SUCCESSO|$($response.Id)|Email inviata correttamente a $Destinatario"
    
    # Chiudi la connessione al database
    if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
    }
    
    exit 0
    
} catch {
    $errorMsg = $_.Exception.Message
    Write-Log "ERRORE: $errorMsg"
    
    try {
        if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
            $errorUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
            $errorUpdateCmd.Connection = $connection
            $errorUpdateCmd.CommandText = "UPDATE [dbo].[EmailData] SET [Note] = @ErrorMsg, [StatoElaborazione] = 'Errore' WHERE [ID] = @EmailGuid"
            $errorUpdateCmd.Parameters.AddWithValue("@ErrorMsg", "ERRORE: $errorMsg")
            $errorUpdateCmd.Parameters.AddWithValue("@EmailGuid", $EmailID)
            $errorUpdateCmd.ExecuteNonQuery()
        }
    } catch {
        Write-Log "ERRORE nell'aggiornamento del database: $($_.Exception.Message)"
    }
    
    Write-Output "ERRORE|$($EmailID)|$errorMsg"
    
    exit 1
} finally {
    if ($contentBuilder) { $contentBuilder.Clear() }
    if ($reader) { $reader.Dispose() }
    if ($command) { $command.Dispose() }
    if ($connection) { $connection.Dispose() }
}  
