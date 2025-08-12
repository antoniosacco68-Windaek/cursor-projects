# Sistema di Invio Email Ottimizzato

Questo sistema è progettato per l'invio di email in batch da SQL Server mediante PowerShell e l'API di Gmail.

## Componenti del Sistema

1. **Stored Procedure SQL**: `SP_ProcessoMailDaInviare`
   - Gestisce la selezione delle email da inviare
   - Valida gli indirizzi email prima dell'elaborazione
   - Può processare le email in batch

2. **Script PowerShell**: 
   - `InviaEmailSqlDaProcessare.ps1`: Script originale per invio singolo
   - `InviaEmailBatch.ps1`: **NUOVO** script ottimizzato per invio batch parallelo

3. **Tabelle Database**:
   - `EmailDataDaProcessare`: Tabella esistente per i dati delle email
   - `EmailStatistics`: **NUOVA** tabella per monitorare le statistiche di invio

## Migliorie Implementate

- **Validazione preventiva** degli indirizzi email
- **Processamento in batch** delle email
- **Elaborazione parallela** fino a 5 email contemporaneamente
- **Sistema di logging** completo
- **Meccanismo di retry** automatico (3 tentativi con backoff esponenziale)
- **Gestione ottimizzata delle risorse** di sistema
- **Raccolta di statistiche** dettagliate sull'invio
- **Migliore gestione degli errori**

## Configurazione

### Requisiti

- SQL Server con permessi xp_cmdshell
- PowerShell 5.1 o superiore
- Account Gmail configurato con credenziali Service Account
- Librerie Google API .NET installate

### Directory richieste:

```
C:\Antonio\GoogleApi\lib\         # Librerie Google API
C:\Antonio\GoogleApi\private-key.json   # File credenziali
C:\Antonio\ScriptPowershell\      # Script PowerShell
C:\Antonio\Logs\                  # Log di sistema
C:\Temp\                          # File temporanei
```

## Utilizzo

1. **Eseguire lo script `EmailStatistics.sql`** per creare la nuova tabella

2. **Eseguire la stored procedure**:
   ```sql
   EXEC [dbo].[SP_ProcessoMailDaInviare]
   ```

3. **Controllare le statistiche**:
   ```sql
   SELECT TOP 10 * FROM [dbo].[EmailStatistics] ORDER BY RunDate DESC
   ```

4. **Verificare lo stato delle email**:
   ```sql
   SELECT * FROM [dbo].[EmailDataDaProcessare] WHERE Inviata = 0
   ```

## Risoluzione Problemi

Se si verificano errori, consultare:

1. I log in `C:\Antonio\Logs\`
2. La colonna `Note` nella tabella `EmailDataDaProcessare`
3. La tabella `EmailStatistics` per statistiche di invio

## Note Operative

- Lo script verifica automaticamente la validità degli indirizzi email
- Gli errori sono gestiti e registrati sia nel database che nei file di log
- Le email con allegati incorretti verranno segnalate
- Lo script tenterà fino a 3 volte l'invio di un'email in caso di errore 