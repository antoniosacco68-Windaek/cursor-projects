@echo off
echo ========================================
echo   MONITOR JSON CASE
echo ========================================
echo.

REM Verifica se PowerShell è disponibile
powershell -Command "Get-Host" >nul 2>&1
if %errorlevel% neq 0 (
    echo ERRORE: PowerShell non è disponibile!
    pause
    exit /b 1
)

echo Avvio monitoraggio continuo...
echo Per fermare: CTRL+C
echo.

powershell -ExecutionPolicy Bypass -File "%~dp0MONITOR-JSON-CASE.ps1"

echo.
echo Monitoraggio terminato.
pause 