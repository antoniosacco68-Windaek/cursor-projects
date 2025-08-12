 # Imposta la directory contenente le DLL
 $dllPath = "C:\Antonio\GoogleApi\lib"

 # Mostra i file DLL disponibili
 Write-Host "Verifico le DLL disponibili in $dllPath..."
 Get-ChildItem -Path $dllPath -Filter "*.dll" | ForEach-Object { Write-Host "- $($_.Name)" }
 
 # Carica Newtonsoft.Json prima delle altre DLL
 Add-Type -Path "$dllPath\Newtonsoft.Json.dll"
 
 # Carica le DLL disponibili in ordine
 Add-Type -Path "$dllPath\Google.Apis.dll"
 Add-Type -Path "$dllPath\Google.Apis.Auth.dll" 
 Add-Type -Path "$dllPath\Google.Apis.Gmail.v1.dll"
 
 # Percorso del file JSON del service account
 $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json"
 $impersonatedUser = "bg5team@bolognagomme.com"
 
 try {
     # Carica le credenziali
     $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath)
     $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send")
     $delegated = $scoped.CreateWithUser($impersonatedUser)
 
     # Crea il servizio Gmail
     $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer
     $initializer.HttpClientInitializer = $delegated
     $initializer.ApplicationName = "BG MailSender"
     $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer
 
     # Componi il messaggio
     $rawMessage = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(@"
 From: $impersonatedUser
 To: antoniosacco68@gmail.com
 Subject: Test da PowerShell con DLL Google
 
 Ciao! Email inviata con successo via Gmail API.
 "@))
 
     $rawMessage = $rawMessage.Replace('+', '-').Replace('/', '_').Replace('=', '')
 
     $msg = New-Object Google.Apis.Gmail.v1.Data.Message
     $msg.Raw = $rawMessage
 
     # Invia
     $response = $service.Users.Messages.Send($msg, "me").Execute()
     Write-Host "✅ Email inviata! ID: $($response.Id)"
 } catch {
     Write-Host "❌ Errore durante l'invio dell'email: $_"
     
     # Mostra informazioni dettagliate sull'errore
     if ($_.Exception.InnerException) {
         Write-Host "Dettagli errore interno: $($_.Exception.InnerException.Message)"
     }
 }
  
 