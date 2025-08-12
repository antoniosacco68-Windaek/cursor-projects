param (
    [Parameter(Mandatory=$true)]
    [string]$Mittente,
    
    [Parameter(Mandatory=$true)]
    [string]$Destinatari,
    
    [Parameter(Mandatory=$true)]
    [string]$Oggetto,
    
    [Parameter(Mandatory=$true)]
    [string]$Corpo,
    
    [Parameter(Mandatory=$false)]
    [string]$Allegato = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CC = "",
    
    [Parameter(Mandatory=$false)]
    [string]$CCN = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$FormatoHTML = $false
)

# Imposta la directory contenente le DLL
$dllPath = "C:\Antonio\GoogleApi\lib"

# Carica le DLL necessarie
try {
    Add-Type -Path "$dllPath\Newtonsoft.Json.dll"
    Add-Type -Path "$dllPath\Google.Apis.Core.dll"
    Add-Type -Path "$dllPath\Google.Apis.dll"
    Add-Type -Path "$dllPath\Google.Apis.Auth.dll" 
    Add-Type -Path "$dllPath\Google.Apis.Gmail.v1.dll"
} catch {
    Write-Error "Errore nel caricamento delle librerie: $_"
    # Restituisci un oggetto con lo stato di errore
    $risultato = @{
        Successo = $false
        Errore = "Errore nel caricamento delle librerie: $_"
        Data = Get-Date
        EmailID = $null
    }
    return $risultato
}

# Percorso del file JSON del service account
$serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"

try {
    # Carica le credenziali
    $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
    $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
    $delegated = $scoped.CreateWithUser($Mittente)

    # Crea il servizio Gmail
    $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
    $initializer.HttpClientInitializer = $delegated
    $initializer.ApplicationName = "BG MailSender"
    $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer

    # Prepara l'email
    $headers = @(
        "From: $Mittente",
        "To: $Destinatari"
    )
    
    # Aggiungi CC e CCN se forniti
    if (-not [string]::IsNullOrEmpty($CC)) {
        $headers += "Cc: $CC"
    }
    
    if (-not [string]::IsNullOrEmpty($CCN)) {
        $headers += "Bcc: $CCN"
    }
    
    $headers += "Subject: $Oggetto"
    
    # Imposta il tipo di contenuto appropriato
    if ($FormatoHTML) {
        $headers += "Content-Type: text/html; charset=UTF-8"
    } else {
        $headers += "Content-Type: text/plain; charset=UTF-8"
    }
    
    # Componi l'email
    $emailBody = $headers -join "`r`n"
    $emailBody += "`r`n`r`n" + $Corpo
    
    # Gestione allegati
    if (-not [string]::IsNullOrEmpty($Allegato)) {
        # Se c'è un allegato, crea un messaggio MIME multipart
        $boundary = [Guid]::NewGuid().ToString("N")
        
        $mimeMessage = @(
            "Content-Type: multipart/mixed; boundary=$boundary",
            ""
        )
        $mimeMessage += "--$boundary"
        
        # Parte del corpo del messaggio
        if ($FormatoHTML) {
            $mimeMessage += "Content-Type: text/html; charset=UTF-8"
        } else {
            $mimeMessage += "Content-Type: text/plain; charset=UTF-8"
        }
        $mimeMessage += "Content-Transfer-Encoding: 8bit"
        $mimeMessage += ""
        $mimeMessage += $Corpo
        $mimeMessage += ""
        
        # Percorsi degli allegati (possono essere multipli separati da ;)
        $allegati = $Allegato -split ";"
        
        foreach ($allegatoPath in $allegati) {
            if (Test-Path $allegatoPath.Trim()) {
                $nomeFile = [System.IO.Path]::GetFileName($allegatoPath.Trim())
                $contenutoFile = [System.IO.File]::ReadAllBytes($allegatoPath.Trim())
                $contenutoBase64 = [System.Convert]::ToBase64String($contenutoFile)
                
                # Determina il Content-Type
                $extension = [System.IO.Path]::GetExtension($allegatoPath.Trim()).ToLower()
                $contentType = "application/octet-stream"  # Default
                
                switch ($extension) {
                    ".pdf"  { $contentType = "application/pdf" }
                    ".txt"  { $contentType = "text/plain" }
                    ".jpg"  { $contentType = "image/jpeg" }
                    ".jpeg" { $contentType = "image/jpeg" }
                    ".png"  { $contentType = "image/png" }
                    ".gif"  { $contentType = "image/gif" }
                    ".doc"  { $contentType = "application/msword" }
                    ".docx" { $contentType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document" }
                    ".xls"  { $contentType = "application/vnd.ms-excel" }
                    ".xlsx" { $contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" }
                    ".csv"  { $contentType = "text/csv" }
                }
                
                # Aggiunge l'allegato al messaggio MIME
                $mimeMessage += "--$boundary"
                $mimeMessage += "Content-Type: $contentType; name=""$nomeFile"""
                $mimeMessage += "Content-Disposition: attachment; filename=""$nomeFile"""
                $mimeMessage += "Content-Transfer-Encoding: base64"
                $mimeMessage += ""
                
                # Divide il contenuto Base64 in righe di 76 caratteri
                for ($i = 0; $i -lt $contenutoBase64.Length; $i += 76) {
                    $length = [Math]::Min(76, $contenutoBase64.Length - $i)
                    $mimeMessage += $contenutoBase64.Substring($i, $length)
                }
                $mimeMessage += ""
            } else {
                Write-Warning "Allegato non trovato: $allegatoPath"
            }
        }
        
        # Chiudi il messaggio MIME
        $mimeMessage += "--$boundary--"
        
        # Sostituisci le intestazioni originali
        $emailBody = $headers -join "`r`n"
        $emailBody += "`r`n"
        $emailBody += $mimeMessage -join "`r`n"
    }
    
    # Codifica il messaggio in base64 per l'API Gmail
    $rawMessage = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($emailBody))
    $rawMessage = $rawMessage.Replace('+', '-').Replace('/', '_').Replace('=', '')

    $msg = New-Object Google.Apis.Gmail.v1.Data.Message
    $msg.Raw = $rawMessage

    # Invia l'email
    $response = $service.Users.Messages.Send($msg, "me").Execute()
    
    # Restituisci un oggetto con lo stato di successo
    $risultato = @{
        Successo = $true
        Errore = $null
        Data = Get-Date
        EmailID = $response.Id
    }
    
    Write-Host "✅ Email inviata con successo! ID: $($response.Id)"
    return $risultato
    
} catch {
    $errorMessage = "❌ Errore durante l'invio dell'email: $_"
    
    # Includi dettagli dell'errore interno se disponibili
    if ($_.Exception.InnerException) {
        $errorMessage += "`nDettaglio errore interno: $($_.Exception.InnerException.Message)"
    }
    
    Write-Error $errorMessage
    
    # Restituisci un oggetto con lo stato di errore
    $risultato = @{
        Successo = $false
        Errore = $errorMessage
        Data = Get-Date
        EmailID = $null
    }
    
    return $risultato
} 