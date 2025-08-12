# Script PowerShell per inviare email tramite Gmail API
param(
    [Parameter(Mandatory=$true)]
    [string]$Mittente,
    
    [Parameter(Mandatory=$true)]
    [string]$Destinatario,
    
    [Parameter(Mandatory=$true)]
    [string]$Oggetto,
    
    [Parameter(Mandatory=$true)]
    [string]$CorpoBase64, # Corpo dell'email codificato in Base64
    
    [Parameter(Mandatory=$false)]
    [string]$CC = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CCN = "",
    
    [Parameter(Mandatory=$false)]
    [bool]$HTML = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$Allegato = ""
)

# Configurazione
$ErrorActionPreference = "Stop"

# Log delle operazioni
$logPath = "C:\Temp\email_log.txt"
try {
    "$(Get-Date) - Avvio invio email" | Out-File -FilePath $logPath -Append
    "Mittente: $Mittente" | Out-File -FilePath $logPath -Append
    "Destinatario: $Destinatario" | Out-File -FilePath $logPath -Append
    "Oggetto: $Oggetto" | Out-File -FilePath $logPath -Append
    "HTML: $HTML" | Out-File -FilePath $logPath -Append
} catch {
    # Ignora errori di log
}

# Decodifica il corpo dell'email da Base64
try {
    $bytes = [Convert]::FromBase64String($CorpoBase64)
    $Corpo = [System.Text.Encoding]::UTF8.GetString($bytes)
    "Corpo decodificato con successo" | Out-File -FilePath $logPath -Append
} catch {
    "Errore nella decodifica Base64: $_" | Out-File -FilePath $logPath -Append
    Write-Error "ERROR:Errore nella decodifica Base64: $_"
    exit 1
}

# Carica le DLL necessarie
try {
    Add-Type -Path "C:\Antonio\GoogleApi\lib\Newtonsoft.Json.dll"
    Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Core.dll"
    Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.dll"
    Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Auth.dll"
    Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Gmail.v1.dll"
    "DLL caricate con successo" | Out-File -FilePath $logPath -Append
} catch {
    "Errore nel caricamento delle DLL: $_" | Out-File -FilePath $logPath -Append
    Write-Error "ERROR:Errore nel caricamento delle DLL: $_"
    exit 1
}

# Configura l'autenticazione
try {
    $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"
    $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
    $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
    $delegated = $scoped.CreateWithUser($Mittente)

    $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
    $initializer.HttpClientInitializer = $delegated
    $initializer.ApplicationName = "BG MailSender"

    $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer
    "Autenticazione completata" | Out-File -FilePath $logPath -Append
} catch {
    "Errore nell'autenticazione: $_" | Out-File -FilePath $logPath -Append
    Write-Error "ERROR:Errore nell'autenticazione: $_"
    exit 1
}

# Costruisci l'email
try {
    $headers = @()
    $headers += "From: $Mittente"
    $headers += "To: $Destinatario"
    
    if (-not [string]::IsNullOrEmpty($CC)) {
        $headers += "Cc: $CC"
    }
    
    if (-not [string]::IsNullOrEmpty($CCN)) {
        $headers += "Bcc: $CCN"
    }
    
    $headers += "Subject: $Oggetto"
    
    if ($HTML) {
        $headers += "Content-Type: text/html; charset=UTF-8"
    } else {
        $headers += "Content-Type: text/plain; charset=UTF-8"
    }
    
    $emailContent = $headers -join "`r`n"
    $emailContent += "`r`n`r`n"
    $emailContent += $Corpo

    # Base64 encode dell'email
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($emailContent)
    $rawMessage = [System.Convert]::ToBase64String($bytes)
    $rawMessage = $rawMessage.Replace("+", "-").Replace("/", "_").Replace("=", "")

    # Crea il messaggio e invia
    $msg = New-Object Google.Apis.Gmail.v1.Data.Message
    $msg.Raw = $rawMessage

    "Email costruita, pronta per l'invio" | Out-File -FilePath $logPath -Append
    
    # Invia il messaggio
    $response = $service.Users.Messages.Send($msg, "me").Execute()
    "Email inviata con ID: $($response.Id)" | Out-File -FilePath $logPath -Append
    
    Write-Output "SUCCESS:$($response.Id)"
    exit 0
} catch {
    "Errore nell'invio dell'email: $_" | Out-File -FilePath $logPath -Append
    if ($_.Exception.InnerException) {
        "Inner Exception: $($_.Exception.InnerException.Message)" | Out-File -FilePath $logPath -Append
    }
    Write-Error "ERROR:$_"
    exit 1
} 