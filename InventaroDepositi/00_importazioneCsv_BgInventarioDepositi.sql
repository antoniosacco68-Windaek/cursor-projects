USE I24DB

/*

Importazione del file CSV "BgInventarioDepositi.csv"
USANDO IL PACKAGE SSIS PER MANTENERE L'ORDINE

*/

-- Abilitazione di xp_cmdshell (necessario per eseguire SSIS)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Dichiarazione delle variabili
DECLARE @PackagePath NVARCHAR(500);
DECLARE @CMD NVARCHAR(1000);
DECLARE @ReturnCode INT;

-- Percorso del package SSIS (CORRETTO)
SET @PackagePath = N'C:\Users\Antonio\Documents\SQL Server Management Studio\Projects\IVDepositi\ImportaDaQui_BgInventarioDepositi_csv.dtsx';

-- Cancellazione dati precedenti
TRUNCATE TABLE Inventario_Depositi

-- Costruzione del comando per eseguire il package SSIS con parametri di sicurezza
SET @CMD = N'dtexec /FILE "' + @PackagePath + '" /CHECKPOINTING OFF /REPORTING EW';

-- Stampa del comando che verrà eseguito
PRINT 'Esecuzione package SSIS: ' + @CMD;

-- Esecuzione del package SSIS tramite xp_cmdshell
EXEC @ReturnCode = xp_cmdshell @CMD;

-- Verifica del risultato
IF @ReturnCode = 0
BEGIN
    PRINT 'Package SSIS eseguito con successo. Ordine mantenuto.';
END
ELSE
BEGIN
    PRINT 'Errore nell''esecuzione del package SSIS. Codice errore: ' + CAST(@ReturnCode AS NVARCHAR(10));
    PRINT 'SOLUZIONI POSSIBILI:';
    PRINT '1. Verificare che il file .dtsx esista nel percorso specificato';
    PRINT '2. Copiare il file .dtsx in una cartella con permessi completi (es: C:\Temp\)';
    PRINT '3. Eseguire SQL Server Management Studio come Amministratore';
END

-- Verifica dei dati importati (prime 10 righe)
SELECT TOP 10 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NumeroRiga,
    Targa
FROM Inventario_Depositi;

-- Conteggio totale record importati
SELECT COUNT(*) as TotaleRecordImportati
FROM Inventario_Depositi;
