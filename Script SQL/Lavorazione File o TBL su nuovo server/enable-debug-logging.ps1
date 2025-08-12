# Script per abilitare il logging dettagliato
# Esegui questo script nella cartella dell'applicazione sul server

Write-Host "=== ENABLE DEBUG LOGGING ===" -ForegroundColor Green
Write-Host ""

# 1. Backup del file appsettings.json
Write-Host "1. Backup appsettings.json..." -ForegroundColor Yellow
if (Test-Path "appsettings.json") {
    Copy-Item "appsettings.json" "appsettings.json.backup"
    Write-Host "   OK: Backup creato: appsettings.json.backup" -ForegroundColor Green
} else {
    Write-Host "   ERRORE: File appsettings.json non trovato" -ForegroundColor Red
    exit 1
}

# 2. Aggiorna appsettings.json con logging dettagliato
Write-Host ""
Write-Host "2. Aggiorna logging..." -ForegroundColor Yellow
$appSettings = Get-Content "appsettings.json" | ConvertFrom-Json

# Aggiungi logging dettagliato
$appSettings.Logging.LogLevel.Default = "Debug"
$appSettings.Logging.LogLevel."Microsoft.AspNetCore" = "Information"
$appSettings.Logging.LogLevel."Backend" = "Debug"
$appSettings.Logging.LogLevel."Backend.Services.AuthService" = "Debug"
$appSettings.Logging.LogLevel."Backend.Controllers.AuthController" = "Debug"

# Salva il file aggiornato
$appSettings | ConvertTo-Json -Depth 10 | Set-Content "appsettings.json"
Write-Host "   OK: Logging abilitato per Debug" -ForegroundColor Green

# 3. Mostra il contenuto aggiornato
Write-Host ""
Write-Host "3. Contenuto aggiornato appsettings.json:" -ForegroundColor Yellow
Get-Content "appsettings.json" | Write-Host -ForegroundColor Cyan

Write-Host ""
Write-Host "=== RIAVVIA L'APPLICAZIONE PER APPLICARE LE MODIFICHE ===" -ForegroundColor Green
Write-Host "1. Ferma l'applicazione corrente" -ForegroundColor Cyan
Write-Host "2. Riavvia con: .\Backend.exe" -ForegroundColor Cyan
Write-Host "3. Esegui: .\debug-login.ps1" -ForegroundColor Cyan 