# Script di debug per l'invio di email tramite Gmail API
# Salvare questo file in C:\Temp\InvioEmailDebug.ps1

# Configurazione
$logFile = "C:\Temp\email_debug_log.txt"

# Inizializza il log
"=============================================" | Out-File -FilePath $logFile -Force
"DEBUG LOG - $(Get-Date)" | Out-File -FilePath $logFile -Append
"=============================================" | Out-File -FilePath $logFile -Append

# Parametri di test
$mittente = "antonio.sacco@i24.it"
$destinatario = "antonio.sacco@i24.it"
$oggetto = "Test debug email - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$corpo = "Questo è un messaggio di test per il debug dell'invio email.`r`n`r`nCaratteri speciali: àèìòù € § ° ç @`r`n`r`nData: $(Get-Date)"
$isHtml = $false

# Scrivi i parametri nel log
"Parametri:" | Out-File -FilePath $logFile -Append
"- Mittente: $mittente" | Out-File -FilePath $logFile -Append
"- Destinatario: $destinatario" | Out-File -FilePath $logFile -Append
"- Oggetto: $oggetto" | Out-File -FilePath $logFile -Append
"- HTML: $isHtml" | Out-File -FilePath $logFile -Append
"- Corpo: $corpo" | Out-File -FilePath $logFile -Append

try {
    # Verifica le DLL richieste
    "Verifica delle DLL necessarie:" | Out-File -FilePath $logFile -Append
    $dllPaths = @(
        "C:\Antonio\GoogleApi\lib\Newtonsoft.Json.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Core.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Auth.dll",
        "C:\Antonio\GoogleApi\lib\Google.Apis.Gmail.v1.dll"
    )
    
    foreach ($dll in $dllPaths) {
        if (Test-Path $dll) {
            "- $dll : TROVATO" | Out-File -FilePath $logFile -Append
        } else {
            "- $dll : NON TROVATO" | Out-File -FilePath $logFile -Append
            throw "DLL mancante: $dll"
        }
    }
    
    # Carica le DLL
    "Caricamento delle DLL..." | Out-File -FilePath $logFile -Append
    foreach ($dll in $dllPaths) {
        try {
            Add-Type -Path $dll
            "- $dll : Caricato con successo" | Out-File -FilePath $logFile -Append
        } catch {
            "- $dll : ERRORE durante il caricamento: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
            throw "Errore nel caricamento di $dll : $($_.Exception.Message)"
        }
    }
    
    # Verifica file delle credenziali
    $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"
    if (Test-Path $serviceAccountKeyPath) {
        "File delle credenziali trovato: $serviceAccountKeyPath" | Out-File -FilePath $logFile -Append
    } else {
        "File delle credenziali NON trovato: $serviceAccountKeyPath" | Out-File -FilePath $logFile -Append
        throw "File delle credenziali mancante"
    }
    
    # Autentica con Google
    "Autenticazione con Google..." | Out-File -FilePath $logFile -Append
    $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
    "- Credenziale creata" | Out-File -FilePath $logFile -Append
    
    $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
    "- Scope impostato" | Out-File -FilePath $logFile -Append
    
    $delegated = $scoped.CreateWithUser($mittente)
    "- Delega utente impostata: $mittente" | Out-File -FilePath $logFile -Append
    
    $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
    $initializer.HttpClientInitializer = $delegated
    $initializer.ApplicationName = "Email Debug"
    "- Inizializzatore creato" | Out-File -FilePath $logFile -Append
    
    $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer
    "- Servizio Gmail creato" | Out-File -FilePath $logFile -Append
    
    # Costruisci l'email
    "Costruzione dell'email..." | Out-File -FilePath $logFile -Append
    $headers = @()
    $headers += "From: $mittente"
    $headers += "To: $destinatario"
    $headers += "Subject: $oggetto"
    
    if ($isHtml) {
        $headers += "Content-Type: text/html; charset=UTF-8"
    } else {
        $headers += "Content-Type: text/plain; charset=UTF-8"
    }
    
    $emailContent = $headers -join "`r`n"
    $emailContent += "`r`n`r`n"
    $emailContent += $corpo
    
    "- Intestazioni email create" | Out-File -FilePath $logFile -Append
    $firstChars = $emailContent.Substring(0, [Math]::Min(100, $emailContent.Length))
    "- Contenuto email (primi 100 caratteri): $firstChars" | Out-File -FilePath $logFile -Append
    
    # Codifica l'email
    "Codifica dell'email..." | Out-File -FilePath $logFile -Append
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($emailContent)
    $rawMessage = [System.Convert]::ToBase64String($bytes)
    $rawMessage = $rawMessage.Replace("+", "-").Replace("/", "_").Replace("=", "")
    "- Email codificata in Base64" | Out-File -FilePath $logFile -Append
    
    # Prepara il messaggio
    $msg = New-Object Google.Apis.Gmail.v1.Data.Message
    $msg.Raw = $rawMessage
    "- Oggetto messaggio creato" | Out-File -FilePath $logFile -Append
    
    # Invia l'email
    "Invio dell'email in corso..." | Out-File -FilePath $logFile -Append
    try {
        $response = $service.Users.Messages.Send($msg, "me").Execute()
        "- Email inviata con successo!" | Out-File -FilePath $logFile -Append
        "- ID messaggio: $($response.Id)" | Out-File -FilePath $logFile -Append
        
        Write-Output "SUCCESS: Email inviata con successo! ID: $($response.Id)"
        Write-Output "Log dettagliato: $logFile"
        exit 0
    } catch {
        "- ERRORE durante l'invio: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
        if ($_.Exception.InnerException) {
            "- Inner Exception: $($_.Exception.InnerException.Message)" | Out-File -FilePath $logFile -Append
        }
        throw "Errore nell'invio dell'email: $($_.Exception.Message)"
    }
} catch {
    "ERRORE FATALE: $($_.Exception.Message)" | Out-File -FilePath $logFile -Append
    Write-Error "ERRORE: $($_.Exception.Message)"
    Write-Output "Controlla il log per maggiori dettagli: $logFile"
    exit 1
} 