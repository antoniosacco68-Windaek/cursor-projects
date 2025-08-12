# Script per inviare email tramite Gmail API - Chiamato da SQL Server

# Parametri in ingresso
param(
    [Parameter(Mandatory=$true)]
    [string]$EmailID
)

# Pre-carica le DLL necessarie per evitare caricamenti ripetuti
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
            Write-Error "ERRORE: Impossibile caricare $dll - $($_.Exception.Message)"
            exit 1
        }
    }
}

# Carica assembly SqlClient se non già caricato
if (-not ([System.Management.Automation.PSTypeName]'System.Data.SqlClient.SqlConnection').Type) {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Data")
}

try {
    # Inizializza variabili
    $connection = $null
    $CorpoFile = $null
    
    # Connessione al database con timeout maggiore
    $connectionString = "Server=localhost;Database=I24DB;Trusted_Connection=True;Connection Timeout=30;Pooling=true;Min Pool Size=5;Max Pool Size=100;"
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    # Query per ottenere i dati dell'email - selezioniamo solo i campi necessari
    $command = New-Object System.Data.SqlClient.SqlCommand
    $command.Connection = $connection
    $command.CommandText = "SELECT [Mittente], [NomeMittente], [Destinatario], [Oggetto], [Corpo], [CC], [CCN], [FormatoHTML], [Allegato] FROM [dbo].[EmailDataDaProcessare] WHERE [ID] = @Id"
    $command.Parameters.AddWithValue("@Id", $EmailID)
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
        
        # Chiudi il reader il prima possibile
        $reader.Close()
        
        # Non creiamo il file temporaneo a meno che non sia necessario
        # Il corpo è già in memoria, non serve scriverlo su disco
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
    
    # Usa StringBuilder per una costruzione più efficiente delle stringhe
    $contentBuilder = New-Object System.Text.StringBuilder(1024)
    
    # Inizializza gli header di base
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
    
    # Ottieni il contenuto dell'email
    $emailContent = $contentBuilder.ToString()
    
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
    Write-Output "Tempo di esecuzione: $($stopwatch.ElapsedMilliseconds)ms"
    
    # Aggiorna lo stato dell'email nel database
    $updateCmd = New-Object System.Data.SqlClient.SqlCommand
    $updateCmd.Connection = $connection
    $updateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Inviata] = 1, [DataInvio] = GETDATE(), [EmailID] = @EmailID WHERE [ID] = @Id"
    $updateCmd.Parameters.AddWithValue("@EmailID", $response.Id)
    $updateCmd.Parameters.AddWithValue("@Id", $EmailID)
    $updateCmd.CommandTimeout = 30
    $updateCmd.ExecuteNonQuery()
    
    # Restituisci l'ID del messaggio per SQL Server in formato che Access possa interpretare
    Write-Output "SUCCESSO|$($response.Id)|Email inviata correttamente a $Destinatario"
    
    # Chiudi la connessione al database
    if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
        $connection.Close()
    }
    
    exit 0
    
} catch {
    $errorMsg = $_.Exception.Message
    
    # Aggiorna il database con l'errore se la connessione è ancora aperta
    try {
        if ($connection -and $connection.State -eq [System.Data.ConnectionState]::Open) {
            $errorUpdateCmd = New-Object System.Data.SqlClient.SqlCommand
            $errorUpdateCmd.Connection = $connection
            $errorUpdateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Note] = @ErrorMsg WHERE [ID] = @Id"
            $errorUpdateCmd.Parameters.AddWithValue("@ErrorMsg", "ERRORE: $errorMsg")
            $errorUpdateCmd.Parameters.AddWithValue("@Id", $EmailID)
            $errorUpdateCmd.CommandTimeout = 30
            $errorUpdateCmd.ExecuteNonQuery()
            
            # Chiudi la connessione al database
            $connection.Close()
        }
    } catch {}
    
    # In caso di errore restituiamo un messaggio formattato per Access
    Write-Output "ERRORE|$($EmailID)|$errorMsg"
    
    exit 1
} finally {
    if ($contentBuilder) { $contentBuilder.Clear() }
    if ($reader) { $reader.Dispose() }
    if ($command) { $command.Dispose() }
    if ($connection) { $connection.Dispose() }
} 