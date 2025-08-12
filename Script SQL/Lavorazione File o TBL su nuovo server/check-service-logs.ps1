# Script per controllare i log del servizio SQLTableManager
# Esegui questo script nella cartella dell'applicazione sul server

Write-Host "=== CHECK SERVICE LOGS ===" -ForegroundColor Green
Write-Host ""

# 1. Verifica stato del servizio
Write-Host "1. Stato del servizio SQLTableManager..." -ForegroundColor Yellow
$service = Get-Service -Name "SQLTableManager" -ErrorAction SilentlyContinue
if ($service) {
    Write-Host "   OK: Servizio trovato - Stato: $($service.Status)" -ForegroundColor Green
    Write-Host "   Tipo di avvio: $($service.StartType)" -ForegroundColor Cyan
} else {
    Write-Host "   ERRORE: Servizio SQLTableManager non trovato" -ForegroundColor Red
    exit 1
}

# 2. Controlla Windows Event Log per errori recenti
Write-Host ""
Write-Host "2. Controlla Event Log per errori recenti..." -ForegroundColor Yellow
try {
    $events = Get-WinEvent -LogName "Application" -MaxEvents 20 | Where-Object { 
        $_.Message -like "*SQLTableManager*" -or 
        $_.Message -like "*Backend*" -or 
        $_.Message -like "*Auth*" -or
        $_.Message -like "*JWT*" -or
        $_.Message -like "*500*" -or
        $_.Message -like "*Internal Server*"
    }
    
    if ($events) {
        Write-Host "   OK: Trovati eventi recenti:" -ForegroundColor Green
        foreach ($event in $events) {
            $level = switch ($event.Level) {
                1 { "Critical" }
                2 { "Error" }
                3 { "Warning" }
                4 { "Information" }
                default { "Unknown" }
            }
            Write-Host "   [$($event.TimeCreated)] [$level] $($event.Message)" -ForegroundColor White
        }
    } else {
        Write-Host "   ATTENZIONE: Nessun evento trovato per l'applicazione" -ForegroundColor Yellow
    }
} catch {
    Write-Host "   ERRORE: Errore nel leggere Event Log: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Controlla se ci sono file di log dell'applicazione
Write-Host ""
Write-Host "3. Cerca file di log dell'applicazione..." -ForegroundColor Yellow
$logFiles = Get-ChildItem -Path "." -Filter "*.log" -Recurse
if ($logFiles) {
    Write-Host "   OK: Trovati file di log:" -ForegroundColor Green
    foreach ($file in $logFiles) {
        Write-Host "   - $($file.FullName)" -ForegroundColor Cyan
        Write-Host "   Ultime 10 righe:" -ForegroundColor Yellow
        Get-Content $file.FullName -Tail 10 | ForEach-Object { Write-Host "     $_" -ForegroundColor White }
    }
} else {
    Write-Host "   ATTENZIONE: Nessun file .log trovato" -ForegroundColor Yellow
}

# 4. Controlla se l'applicazione scrive su console (se avviata manualmente)
Write-Host ""
Write-Host "4. Controlla processo Backend..." -ForegroundColor Yellow
$process = Get-Process -Name "Backend" -ErrorAction SilentlyContinue
if ($process) {
    Write-Host "   OK: Processo Backend attivo (PID: $($process.Id))" -ForegroundColor Green
    Write-Host "   Se l'applicazione e avviata da console, controlla la finestra per i log" -ForegroundColor Cyan
} else {
    Write-Host "   ATTENZIONE: Processo Backend non trovato (potrebbe essere gestito dal servizio)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== SUGGERIMENTI ===" -ForegroundColor Green
Write-Host "1. Se non vedi log dettagliati, prova ad avviare l'applicazione manualmente:" -ForegroundColor Cyan
Write-Host "   Stop-Service SQLTableManager" -ForegroundColor White
Write-Host "   .\Backend.exe" -ForegroundColor White
Write-Host "2. Poi esegui: .\debug-login.ps1" -ForegroundColor Cyan
Write-Host "3. Controlla l'output della console per errori dettagliati" -ForegroundColor Cyan

Write-Host ""
Write-Host "=== FINE CHECK SERVICE LOGS ===" -ForegroundColor Green 