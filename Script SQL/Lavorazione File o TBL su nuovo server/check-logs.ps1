# Script per controllare i log dell'applicazione
# Esegui questo script nella cartella dell'applicazione sul server

Write-Host "=== CHECK APPLICATION LOGS ===" -ForegroundColor Green
Write-Host ""

# 1. Verifica se ci sono file di log
Write-Host "1. Cerca file di log..." -ForegroundColor Yellow
$logFiles = Get-ChildItem -Path "." -Filter "*.log" -Recurse
if ($logFiles) {
    Write-Host "   OK: Trovati $($logFiles.Count) file di log:" -ForegroundColor Green
    foreach ($file in $logFiles) {
        Write-Host "   - $($file.FullName)" -ForegroundColor Cyan
    }
} else {
    Write-Host "   ATTENZIONE: Nessun file .log trovato" -ForegroundColor Yellow
}

# 2. Controlla i log di Windows Event Viewer
Write-Host ""
Write-Host "2. Controlla Windows Event Log..." -ForegroundColor Yellow
try {
    $events = Get-WinEvent -LogName "Application" -MaxEvents 10 | Where-Object { $_.Message -like "*Backend*" -or $_.Message -like "*SQLTableManager*" }
    if ($events) {
        Write-Host "   OK: Trovati eventi recenti:" -ForegroundColor Green
        foreach ($event in $events) {
            Write-Host "   [$($event.TimeCreated)] $($event.Message)" -ForegroundColor White
        }
    } else {
        Write-Host "   ATTENZIONE: Nessun evento trovato per l'applicazione" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ERRORE: Errore nel leggere Event Log: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Controlla se l'applicazione scrive su console
Write-Host ""
Write-Host "3. Controlla output console..." -ForegroundColor Yellow
$process = Get-Process -Name "Backend" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "   OK: Processo Backend attivo (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "   Se l'applicazione e avviata da console, controlla la finestra per i log" -ForegroundColor Cyan
} else {
    Write-Host "   ERRORE: Processo Backend non trovato" -ForegroundColor Red
}

# 4. Suggerimenti per il debug
Write-Host ""
Write-Host "4. Suggerimenti per il debug:" -ForegroundColor Yellow
Write-Host "   - Avvia l'applicazione da console: .\Backend.exe" -ForegroundColor Cyan
Write-Host "   - Controlla l'output della console per errori" -ForegroundColor Cyan
Write-Host "   - Esegui: .\enable-debug-logging.ps1 per abilitare logging dettagliato" -ForegroundColor Cyan
Write-Host "   - Esegui: .\debug-login.ps1 per testare il login" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== FINE CHECK LOGS ===" -ForegroundColor Green 