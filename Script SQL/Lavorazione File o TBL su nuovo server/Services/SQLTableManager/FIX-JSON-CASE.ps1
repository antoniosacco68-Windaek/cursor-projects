# Script per correggere il problema del case delle chiavi JSON
# Questo script forza il mantenimento di PascalCase nel file users.json

Write-Host "=== CORREZIONE PROBLEMA JSON CASE ===" -ForegroundColor Yellow

# Percorso del file users.json
$usersFile = Join-Path $PSScriptRoot "Data\users.json"

# Backup del file originale
$backupFile = Join-Path $PSScriptRoot "Data\users.json.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
if (Test-Path $usersFile) {
    Copy-Item $usersFile $backupFile
    Write-Host "Backup creato: $backupFile" -ForegroundColor Green
}

# Funzione per correggere il case delle chiavi JSON
function Fix-JsonCase {
    param([string]$jsonContent)
    
    # Sostituisce le chiavi in camelCase con PascalCase
    $fixed = $jsonContent -replace '"username"', '"Username"'
    $fixed = $fixed -replace '"passwordHash"', '"PasswordHash"'
    $fixed = $fixed -replace '"role"', '"Role"'
    $fixed = $fixed -replace '"permissions"', '"Permissions"'
    $fixed = $fixed -replace '"createdAt"', '"CreatedAt"'
    $fixed = $fixed -replace '"lastLogin"', '"LastLogin"'
    $fixed = $fixed -replace '"isActive"', '"IsActive"'
    
    return $fixed
}

# Legge il file users.json
if (Test-Path $usersFile) {
    $content = Get-Content $usersFile -Raw
    Write-Host "File users.json letto" -ForegroundColor Green
    
    # Controlla se ci sono chiavi in camelCase
    if ($content -match '"username"|"passwordHash"|"role"|"permissions"|"createdAt"|"lastLogin"|"isActive"') {
        Write-Host "Trovate chiavi in camelCase, correggendo..." -ForegroundColor Yellow
        
        # Corregge il case
        $fixedContent = Fix-JsonCase $content
        
        # Salva il file corretto
        $fixedContent | Set-Content $usersFile -Encoding UTF8
        Write-Host "File users.json corretto e salvato" -ForegroundColor Green
    } else {
        Write-Host "Le chiavi sono già in PascalCase, nessuna correzione necessaria" -ForegroundColor Green
    }
} else {
    Write-Host "File users.json non trovato!" -ForegroundColor Red
}

# Riavvia il servizio se è in esecuzione
$serviceName = "SQLTableManager.API"
if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
    Write-Host "Riavvio del servizio $serviceName..." -ForegroundColor Yellow
    Restart-Service -Name $serviceName -Force
    Write-Host "Servizio riavviato" -ForegroundColor Green
} else {
    Write-Host "Servizio $serviceName non trovato" -ForegroundColor Yellow
}

Write-Host "=== CORREZIONE COMPLETATA ===" -ForegroundColor Green
Write-Host "Il file users.json ora mantiene PascalCase" -ForegroundColor Green 