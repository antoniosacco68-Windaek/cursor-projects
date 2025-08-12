# Installazione e Utilizzo - Nuova Soluzione PowerShell per Tyre24

## Panoramica

Questa soluzione sostituisce il download tramite SQL Server con una soluzione PowerShell più robusta e affidabile per il download degli ordini Tyre24.

## File Creati/Modificati

### 1. `DownloadLatestOrdersT24.ps1`
Script PowerShell per il download degli ordini da Tyre24 API.

### 2. `SP_ScaricoUltimoOrdineT24_PowerShell.sql`
Stored procedure che richiama lo script PowerShell.

### 3. `Ant_ImportOrdiniTyre24.sql` (Modificato)
Script principale modificato per utilizzare la nuova soluzione PowerShell.

## Installazione

### 1. Copiare i File
```
# Creare la cartella script se non esiste
C:\Antonio\Tyre24\Scripts\

# Copiare lo script PowerShell
DownloadLatestOrdersT24.ps1 → C:\Antonio\Tyre24\Scripts\DownloadLatestOrdersT24.ps1
```

### 2. Creare la Stored Procedure
Eseguire il file `SP_ScaricoUltimoOrdineT24_PowerShell.sql` sul database Tyre24.

### 3. Configurare le API Key
Nel file `Ant_ImportOrdiniTyre24.sql`, sostituire i segnaposto con le API key reali:

```sql
-- Linea ~52 - Account principale (già configurato)
SET @ApyKey = 'YTc3NjQ0MzViNTNjZGExM2I3N2UwNGI5ZWUxYzAwNzY1NDllMWY3M2MxZGFhMjkzMTRjZTMyZDJlYjY4OTQ4ZGViNmZhODUyNTE5MGY4NTRhOWI5NGZjNDNkNDY0NDhjNjY5MmE1MWEwN2U5ZTA='

-- Linea ~158 - Account 2
DECLARE @ApyKey2 VARCHAR(400) = 'INSERIRE_QUI_API_KEY_ACCOUNT_2'

-- Linea ~298 - Account 3  
DECLARE @ApyKey3 VARCHAR(400) = 'INSERIRE_QUI_API_KEY_ACCOUNT_3'
```

### 4. Creare le Cartelle di Destinazione
```
C:\Antonio\Tyre24\72H_Account2\
C:\Antonio\Tyre24\72H_Account3\
```

## Parametri dello Script PowerShell

Lo script `DownloadLatestOrdersT24.ps1` accetta i seguenti parametri:

- `apiKey` (obbligatorio): API Key per l'autenticazione
- `country` (default: 'it'): Codice paese
- `counter` (default: 0): Contatore per il recupero ordini
- `no_tagging` (default: 0): Flag per il tagging degli ordini
- `tracking_number` (default: 0): Filtro per numero tracking
- `order_role` (default: 'SELLER'): Ruolo ordine
- `demo` (default: 0): Modalità demo

## Vantaggi della Nuova Soluzione

1. **Maggiore Affidabilità**: PowerShell gestisce meglio le risposte JSON lunghe
2. **Gestione Errori**: Migliore handling degli errori e logging
3. **Flessibilità**: Facile aggiunta di nuovi parametri e account
4. **Debugging**: Possibilità di testare manualmente gli script
5. **Performance**: Migliori prestazioni nel download

## Test Manuale

Per testare manualmente il download:

```powershell
# Eseguire da PowerShell
C:\Antonio\Tyre24\Scripts\DownloadLatestOrdersT24.ps1 -apiKey "TUA_API_KEY"
```

## Troubleshooting

### Errori Comuni

1. **Execution Policy**: Se si verificano errori di policy, eseguire:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Connessione Database**: Verificare che il server SQL "Impresa24" sia raggiungibile.

3. **API Key Invalida**: Controllare che le API key siano corrette e valide.

4. **Permessi File**: Assicurarsi che l'utente SQL Server abbia i permessi per eseguire xp_cmdshell.

### Log degli Errori

Gli errori vengono gestiti tramite:
- Output di PowerShell per errori di script
- Exception handling nella stored procedure
- Email di notifica in caso di errori (già implementata nel main script)

## Configurazione Account Multipli

La soluzione supporta 3 account:
- **Account 1**: TipoOrdine = 'Tyre24_72H' (configurazione originale)
- **Account 2**: TipoOrdine = 'Tyre24_72H_Account2'
- **Account 3**: TipoOrdine = 'Tyre24_72H_Account3'

Ogni account può avere:
- API Key differente
- Cartella di destinazione differente  
- Categoria fornitore differente

## Monitoraggio

Per monitorare il funzionamento:

1. Controllare la tabella `Tyre24.dbo.Tjson_BGD` per i dati scaricati
2. Verificare che il campo `Elaborato` sia impostato a 1 dopo l'elaborazione
3. Controllare i log di SQL Server per eventuali errori

## Backup

Prima di implementare in produzione:
1. Fare backup della stored procedure originale `SP_ScaricoUltimoOrdineT24`
2. Fare backup dello script `Ant_ImportOrdiniTyre24.sql` originale
 