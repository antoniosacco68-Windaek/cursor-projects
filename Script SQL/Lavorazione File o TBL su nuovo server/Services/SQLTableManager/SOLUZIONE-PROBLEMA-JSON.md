# SOLUZIONE PROBLEMA JSON CASE

## PROBLEMA IDENTIFICATO
Il sistema riscrive automaticamente il file `users.json` convertendo le chiavi da **PascalCase** (Username, PasswordHash, etc.) a **camelCase** (username, passwordHash, etc.) dopo il login, causando problemi di autenticazione.

## CAUSA
Il serializzatore JSON di ASP.NET Core converte automaticamente le chiavi in camelCase per default.

## SOLUZIONI IMPLEMENTATE

### 1. File di Configurazione Modificati
- ✅ `appsettings.json` - Aggiunta configurazione JsonSerializer
- ✅ `appsettings.Production.json` - Aggiunta configurazione JsonSerializer

### 2. Script di Correzione
- ✅ `FIX-JSON-CASE.ps1` - Corregge manualmente il file users.json
- ✅ `MONITOR-JSON-CASE.ps1` - Monitora e corregge automaticamente

## COME USARE

### Correzione Immediata
```powershell
# Esegui lo script di correzione
.\FIX-JSON-CASE.ps1
```

### Monitoraggio Continuo
```powershell
# Monitora ogni 30 secondi
.\MONITOR-JSON-CASE.ps1

# Monitora ogni 60 secondi
.\MONITOR-JSON-CASE.ps1 -CheckInterval 60

# Esegui una sola volta
.\MONITOR-JSON-CASE.ps1 -RunOnce
```

### Riavvio del Servizio
```powershell
# Riavvia il servizio dopo la correzione
Restart-Service -Name "SQLTableManager.API" -Force
```

## VERIFICA
Dopo la correzione, il file `users.json` dovrebbe avere questo formato:
```json
[
  {
    "Username": "admin",
    "PasswordHash": "...",
    "Role": "Admin",
    "Permissions": [...],
    "CreatedAt": "...",
    "LastLogin": "...",
    "IsActive": true
  }
]
```

## PREVENZIONE
Per prevenire il problema in futuro:
1. Esegui il monitoraggio continuo: `.\MONITOR-JSON-CASE.ps1`
2. Oppure configura il servizio per usare sempre PascalCase

## NOTE
- Il backup del file originale viene creato automaticamente
- Lo script riavvia automaticamente il servizio se necessario
- Il monitoraggio continuo è consigliato in produzione 