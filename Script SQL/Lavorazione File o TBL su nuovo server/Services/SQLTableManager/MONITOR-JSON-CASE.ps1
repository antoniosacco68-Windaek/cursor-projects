# Script di monitoraggio per mantenere PascalCase nel file users.json
# Questo script controlla continuamente il file e lo corregge se necessario

param(
    [int]$CheckInterval = 30,  # Controlla ogni 30 secondi
    [switch]$RunOnce = $false  # Esegue una sola volta se specificato
)

Write-Host "=== MONITOR JSON CASE ===" -ForegroundColor Yellow
Write-Host "Controllo ogni $CheckInterval secondi" -ForegroundColor Cyan

# Percorso del file users.json
$usersFile = Join-Path $PSScriptRoot "Data\users.json"

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

# Funzione per controllare e correggere il file
function Check-And-Fix-Json {
    if (Test-Path $usersFile) {
        $content = Get-Content $usersFile -Raw
        $originalContent = $content
        
        # Controlla se ci sono chiavi in camelCase
        if ($content -match '"username"|"passwordHash"|"role"|"permissions"|"createdAt"|"lastLogin"|"isActive"') {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - Trovate chiavi in camelCase, correggendo..." -ForegroundColor Yellow
            
            # Corregge il case
            $fixedContent = Fix-JsonCase $content
            
            # Salva il file corretto
            $fixedContent | Set-Content $usersFile -Encoding UTF8
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - File corretto e salvato" -ForegroundColor Green
            
            return $true
        } else {
            Write-Host "$(Get-Date -Format 'HH:mm:ss') - File OK (PascalCase)" -ForegroundColor Green
            return $false
        }
    } else {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') - File users.json non trovato!" -ForegroundColor Red
        return $false
    }
}

# Loop principale
do {
    $fixed = Check-And-Fix-Json
    
    if ($RunOnce) {
        break
    }
    
    if ($fixed) {
        Write-Host "Attendendo $CheckInterval secondi prima del prossimo controllo..." -ForegroundColor Cyan
    }
    
    Start-Sleep -Seconds $CheckInterval
    
} while (-not $RunOnce)

Write-Host "=== MONITOR COMPLETATO ===" -ForegroundColor Green 