-- ====================================================================
-- SCRIPT IMPORTAZIONE CSV CON STRUTTURA FISSA - SUPER VELOCE
-- ====================================================================
-- Database: PiattaformeWeb
-- Tabella: PrezziManualiDistribuzioneIT
-- Formato: CSV con header fisso e struttura predefinita
-- Performance: Ottimizzato per 120.000+ righe
-- ====================================================================

USE PiattaformeWeb;
GO

-- Variabili di configurazione
DECLARE @percorsoFile NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.csv';
DECLARE @nomeTabella NVARCHAR(100) = 'PrezziManualiDistribuzioneIT';
DECLARE @tempoInizio DATETIME2 = GETDATE();
DECLARE @righeImportate INT = 0;

-- Messaggio di inizio
PRINT '🚀 INIZIO IMPORTAZIONE CSV CON STRUTTURA FISSA';
PRINT '📁 File sorgente: ' + @percorsoFile;
PRINT '🗂️ Tabella destinazione: ' + @nomeTabella;
PRINT '⏰ Orario inizio: ' + CAST(@tempoInizio AS NVARCHAR(50));
PRINT '================================================';

-- Verifica esistenza file
IF NOT EXISTS (
    SELECT 1 FROM sys.dm_os_file_exists(@percorsoFile) 
    WHERE file_exists = 1
)
BEGIN
    PRINT '❌ ERRORE: File non trovato - ' + @percorsoFile;
    RETURN;
END

-- Crea tabella se non esiste
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @nomeTabella)
BEGIN
    PRINT '📋 Creazione tabella ' + @nomeTabella + '...';
    
    CREATE TABLE PrezziManualiDistribuzioneIT (
        Art_Id INT PRIMARY KEY,
        ART_CODICE NVARCHAR(50) NOT NULL,
        classificatore3 NVARCHAR(100),
        Descrizione NVARCHAR(500),
        MARCA NVARCHAR(100),
        ART_STAGIONE NVARCHAR(50),
        PM_Std DECIMAL(10,2),
        PM_Std_Data DATETIME2,
        PM_T24 DECIMAL(10,2),
        PM_T24_Data DATETIME2,
        PM_B2b DECIMAL(10,2),
        PM_B2b_Data DATETIME2,
        PM_Collegati DECIMAL(10,2),
        PM_Collegati_Data DATETIME2,
        -- Campi di sistema
        DataImportazione DATETIME2 DEFAULT GETDATE(),
        UtenteImportazione NVARCHAR(100) DEFAULT SYSTEM_USER
    );
    
    -- Crea indici per performance
    CREATE NONCLUSTERED INDEX IX_ART_CODICE ON PrezziManualiDistribuzioneIT(ART_CODICE);
    CREATE NONCLUSTERED INDEX IX_MARCA ON PrezziManualiDistribuzioneIT(MARCA);
    CREATE NONCLUSTERED INDEX IX_classificatore3 ON PrezziManualiDistribuzioneIT(classificatore3);
    CREATE NONCLUSTERED INDEX IX_DataImportazione ON PrezziManualiDistribuzioneIT(DataImportazione);
    
    PRINT '✅ Tabella creata con successo';
END
ELSE
BEGIN
    PRINT '📋 Tabella ' + @nomeTabella + ' già esistente';
END

-- Backup dei dati esistenti (opzionale)
DECLARE @conteggioEsistente INT;
SELECT @conteggioEsistente = COUNT(*) FROM PrezziManualiDistribuzioneIT;

IF @conteggioEsistente > 0
BEGIN
    PRINT '🔄 Trovati ' + CAST(@conteggioEsistente AS NVARCHAR(10)) + ' record esistenti';
    
    -- Crea tabella di backup
    DECLARE @nomeBackup NVARCHAR(150) = @nomeTabella + '_BACKUP_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @sqlBackup NVARCHAR(MAX) = 'SELECT * INTO ' + @nomeBackup + ' FROM ' + @nomeTabella;
    
    EXEC sp_executesql @sqlBackup;
    PRINT '💾 Backup creato: ' + @nomeBackup;
    
    -- Svuota tabella principale
    EXEC('TRUNCATE TABLE ' + @nomeTabella);
    PRINT '🗑️ Tabella svuotata per nuova importazione';
END

-- Ottimizzazioni per performance
PRINT '⚡ Applicazione ottimizzazioni performance...';

-- Disabilita statistiche automatiche temporaneamente
ALTER DATABASE PiattaformeWeb SET AUTO_UPDATE_STATISTICS OFF;

-- Disabilita controlli di integrità temporaneamente (se necessario)
-- ALTER TABLE PrezziManualiDistribuzioneIT NOCHECK CONSTRAINT ALL;

-- Imposta modalità di recupero semplice temporaneamente
DECLARE @recoveryModel NVARCHAR(20);
SELECT @recoveryModel = recovery_model_desc FROM sys.databases WHERE name = 'PiattaformeWeb';
IF @recoveryModel != 'SIMPLE'
BEGIN
    ALTER DATABASE PiattaformeWeb SET RECOVERY SIMPLE;
    PRINT '🔧 Modalità recovery impostata su SIMPLE';
END

-- IMPORTAZIONE BULK - SUPER VELOCE
PRINT '📥 Inizio importazione BULK...';

BEGIN TRY
    -- Importa CSV con struttura fissa
    BULK INSERT PrezziManualiDistribuzioneIT
    FROM 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.csv'
    WITH (
        FIELDTERMINATOR = ',',      -- Separatore di campo
        ROWTERMINATOR = '\n',       -- Separatore di riga
        FIRSTROW = 2,               -- Salta header
        CODEPAGE = 'ACP',           -- Codifica caratteri
        TABLOCK,                    -- Blocco tabella per performance
        ROWS_PER_BATCH = 10000,     -- Batch di 10k righe
        MAXERRORS = 10,             -- Massimo 10 errori
        ERRORFILE = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\errori_importazione.txt'
    );
    
    -- Conta righe importate
    SELECT @righeImportate = COUNT(*) FROM PrezziManualiDistribuzioneIT;
    
    PRINT '✅ IMPORTAZIONE COMPLETATA CON SUCCESSO!';
    PRINT '📊 Righe importate: ' + CAST(@righeImportate AS NVARCHAR(10));
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE DURANTE IMPORTAZIONE:';
    PRINT '   Errore: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    
    -- Ripristina impostazioni anche in caso di errore
    GOTO RIPRISTINA_IMPOSTAZIONI;
END CATCH

-- Ripristina impostazioni originali
RIPRISTINA_IMPOSTAZIONI:
PRINT '🔄 Ripristino impostazioni originali...';

-- Riabilita statistiche automatiche
ALTER DATABASE PiattaformeWeb SET AUTO_UPDATE_STATISTICS ON;

-- Riabilita controlli di integrità
-- ALTER TABLE PrezziManualiDistribuzioneIT CHECK CONSTRAINT ALL;

-- Ripristina modalità di recupero originale
IF @recoveryModel != 'SIMPLE'
BEGIN
    EXEC('ALTER DATABASE PiattaformeWeb SET RECOVERY ' + @recoveryModel);
    PRINT '🔧 Modalità recovery ripristinata: ' + @recoveryModel;
END

-- Aggiorna statistiche per prestazioni ottimali
PRINT '📈 Aggiornamento statistiche...';
UPDATE STATISTICS PrezziManualiDistribuzioneIT;

-- Statistiche finali
DECLARE @tempoFine DATETIME2 = GETDATE();
DECLARE @durata INT = DATEDIFF(SECOND, @tempoInizio, @tempoFine);

PRINT '================================================';
PRINT '📊 STATISTICHE IMPORTAZIONE:';
PRINT '   📥 Righe importate: ' + CAST(@righeImportate AS NVARCHAR(10));
PRINT '   ⏱️ Tempo impiegato: ' + CAST(@durata AS NVARCHAR(10)) + ' secondi';
PRINT '   🚀 Velocità: ' + CAST(@righeImportate / CASE WHEN @durata = 0 THEN 1 ELSE @durata END AS NVARCHAR(10)) + ' righe/secondo';
PRINT '   📁 File processato: ' + @percorsoFile;
PRINT '   🗂️ Tabella aggiornata: ' + @nomeTabella;
PRINT '   ⏰ Completato alle: ' + CAST(@tempoFine AS NVARCHAR(50));
PRINT '================================================';

-- Verifica finale dati
PRINT '🔍 VERIFICA FINALE DATI:';

-- Conta per marca (top 5)
PRINT '📋 Top 5 marche per numero di articoli:';
SELECT TOP 5 
    MARCA,
    COUNT(*) as NumeroArticoli
FROM PrezziManualiDistribuzioneIT 
WHERE MARCA IS NOT NULL
GROUP BY MARCA 
ORDER BY COUNT(*) DESC;

-- Conta articoli con prezzi
PRINT '💰 Articoli con prezzi definiti:';
SELECT 
    'PM_Std' as TipoPrezzo,
    COUNT(*) as Articoli
FROM PrezziManualiDistribuzioneIT 
WHERE PM_Std IS NOT NULL AND PM_Std > 0
UNION ALL
SELECT 
    'PM_T24' as TipoPrezzo,
    COUNT(*) as Articoli
FROM PrezziManualiDistribuzioneIT 
WHERE PM_T24 IS NOT NULL AND PM_T24 > 0
UNION ALL
SELECT 
    'PM_B2b' as TipoPrezzo,
    COUNT(*) as Articoli
FROM PrezziManualiDistribuzioneIT 
WHERE PM_B2b IS NOT NULL AND PM_B2b > 0
UNION ALL
SELECT 
    'PM_Collegati' as TipoPrezzo,
    COUNT(*) as Articoli
FROM PrezziManualiDistribuzioneIT 
WHERE PM_Collegati IS NOT NULL AND PM_Collegati > 0;

-- Ultimi 5 record importati
PRINT '📄 Ultimi 5 record importati:';
SELECT TOP 5 
    Art_Id,
    ART_CODICE,
    Descrizione,
    MARCA,
    PM_Std,
    DataImportazione
FROM PrezziManualiDistribuzioneIT 
ORDER BY DataImportazione DESC;

PRINT '🎉 IMPORTAZIONE CSV COMPLETATA CON SUCCESSO!';
GO 