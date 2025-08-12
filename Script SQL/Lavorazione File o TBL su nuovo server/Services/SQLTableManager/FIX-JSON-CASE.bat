@echo off
echo ========================================
echo   CORREZIONE PROBLEMA JSON CASE
echo ========================================
echo.

REM Verifica se PowerShell è disponibile
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRORE: PowerShell non è disponibile!
    pause
    exit /b 1
)

echo Esecuzione script di correzione...
powershell -ExecutionPolicy Bypass -File "%~dp0FIX-JSON-CASE.ps1"

echo.
echo ========================================
echo   CORREZIONE COMPLETATA
echo ========================================
echo.
echo Se il problema persiste, esegui:
echo   powershell -ExecutionPolicy Bypass -File "%~dp0MONITOR-JSON-CASE.ps1"
echo.
pause 