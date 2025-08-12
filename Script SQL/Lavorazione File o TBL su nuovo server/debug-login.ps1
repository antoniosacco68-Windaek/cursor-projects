# Script di debug per testare il login
# Esegui questo script nella cartella dell'applicazione sul server

Write-Host "=== DEBUG LOGIN SCRIPT ===" -ForegroundColor Green
Write-Host ""

# 1. Verifica che l'applicazione sia in esecuzione
Write-Host "1. Verifica processo Backend..." -ForegroundColor Yellow
$process = Get-Process -Name "Backend" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "   OK: Backend in esecuzione (PID: $($process.Id))" -ForegroundColor Green
} else {
    Write-Host "   ERRORE: Backend non in esecuzione" -ForegroundColor Red
    Write-Host "   Avvia l'applicazione con: .\Backend.exe" -ForegroundColor Cyan
    exit 1
}

# 2. Verifica che il file users.json esista
Write-Host ""
Write-Host "2. Verifica file users.json..." -ForegroundColor Yellow
$usersFile = "Data\users.json"
if (Test-Path $usersFile) {
    Write-Host "   OK: File users.json trovato" -ForegroundColor Green
    $content = Get-Content $usersFile -Raw
    Write-Host "   Contenuto del file:" -ForegroundColor Cyan
    Write-Host $content -ForegroundColor White
} else {
    Write-Host "   ERRORE: File users.json non trovato" -ForegroundColor Red
}

# 3. Test con credenziali sbagliate
Write-Host ""
Write-Host "3. Test con credenziali sbagliate..." -ForegroundColor Yellow
$wrongCredentials = @{
    Username = "admin"
    Password = "wrongpassword"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8003/api/Auth/login" -Method POST -Body $wrongCredentials -ContentType "application/json" -TimeoutSec 10
    Write-Host "   ERRORE: dovrebbe dare 401 ma ha dato successo" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "   OK: Corretto: 401 Unauthorized con credenziali sbagliate" -ForegroundColor Green
    } else {
        Write-Host "   ATTENZIONE: Errore inaspettato: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# 4. Test con credenziali corrette
Write-Host ""
Write-Host "4. Test con credenziali corrette..." -ForegroundColor Yellow
$correctCredentials = @{
    Username = "admin"
    Password = "admin123"
} | ConvertTo-Json

Write-Host "   Invio richiesta con: $correctCredentials" -ForegroundColor Cyan

try {
    $response = Invoke-RestMethod -Uri "http://localhost:8003/api/Auth/login" -Method POST -Body $correctCredentials -ContentType "application/json" -TimeoutSec 10
    Write-Host "   SUCCESSO! Login riuscito" -ForegroundColor Green
    Write-Host "   Token ricevuto: $($response.Token.Substring(0, 50))..." -ForegroundColor Cyan
    Write-Host "   Username: $($response.Username)" -ForegroundColor Cyan
    Write-Host "   Role: $($response.Role)" -ForegroundColor Cyan
    Write-Host "   ExpiresAt: $($response.ExpiresAt)" -ForegroundColor Cyan
} catch {
    Write-Host "   ERRORE: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode
        Write-Host "   Status Code: $statusCode" -ForegroundColor Red
        
        # Leggi il contenuto della risposta di errore
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "   Response Body: $responseBody" -ForegroundColor Red
    }
}

# 5. Test di connessione generale
Write-Host ""
Write-Host "5. Test connessione generale..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8003/swagger" -Method GET -TimeoutSec 5
    Write-Host "   OK: Swagger accessibile" -ForegroundColor Green
} catch {
    Write-Host "   ERRORE: Swagger non accessibile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== FINE DEBUG ===" -ForegroundColor Green 