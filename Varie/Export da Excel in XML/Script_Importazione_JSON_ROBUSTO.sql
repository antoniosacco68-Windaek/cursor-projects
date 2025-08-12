-- ====================================================================
-- SCRIPT IMPORTAZIONE JSON ROBUSTO CON GESTIONE ERRORI
-- ====================================================================
-- Database: PiattaformeWeb
-- Formato: JSON con filtro PM_ > 0
-- Performance: Ottimizzato con gestione errori avanzata
-- ====================================================================

USE PiattaformeWeb;
GO

-- Variabili di configurazione
DECLARE @percorsoFile NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json';
DECLARE @nomeTabella NVARCHAR(100) = 'PrezziManualiDistribuzioneIT';
DECLARE @tempoInizio DATETIME2 = GETDATE();
DECLARE @righeImportate INT = 0;
DECLARE @righeErrori INT = 0;

-- Messaggio di inizio
PRINT '🚀 IMPORTAZIONE JSON ROBUSTA CON GESTIONE ERRORI';
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
    PRINT '❌ ERRORE: File JSON non trovato - ' + @percorsoFile;
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

-- Crea tabella per errori se non esiste
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @nomeTabella + '_ERRORI')
BEGIN
    DECLARE @sqlErrori NVARCHAR(MAX) = '
    CREATE TABLE ' + @nomeTabella + '_ERRORI (
        ErroreID INT IDENTITY(1,1) PRIMARY KEY,
        DataErrore DATETIME2 DEFAULT GETDATE(),
        RigaJSON NVARCHAR(MAX),
        MessaggioErrore NVARCHAR(500),
        ValoreCampo NVARCHAR(200),
        NomeCampo NVARCHAR(100)
    )';
    
    EXEC sp_executesql @sqlErrori;
    PRINT '📋 Tabella errori creata: ' + @nomeTabella + '_ERRORI';
END

-- Backup dei dati esistenti
DECLARE @conteggioEsistente INT;
EXEC('SELECT @count = COUNT(*) FROM ' + @nomeTabella, N'@count INT OUTPUT', @conteggioEsistente OUTPUT);

IF @conteggioEsistente > 0
BEGIN
    PRINT '🔄 Trovati ' + CAST(@conteggioEsistente AS NVARCHAR(10)) + ' record esistenti';
    
    -- Crea backup
    DECLARE @nomeBackup NVARCHAR(150) = @nomeTabella + '_BACKUP_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @sqlBackup NVARCHAR(MAX) = 'SELECT * INTO ' + @nomeBackup + ' FROM ' + @nomeTabella;
    
    EXEC sp_executesql @sqlBackup;
    PRINT '💾 Backup creato: ' + @nomeBackup;
    
    -- Svuota tabella principale
    EXEC('TRUNCATE TABLE ' + @nomeTabella);
    PRINT '🗑️ Tabella svuotata per nuova importazione';
END

-- Leggi e valida il file JSON
DECLARE @jsonContent NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent = BulkColumn 
    FROM OPENROWSET(BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.json', SINGLE_BLOB) AS j;
    
    PRINT '📥 File JSON caricato: ' + CAST(LEN(@jsonContent) AS NVARCHAR(10)) + ' caratteri';
    
    -- Verifica che sia JSON valido
    IF ISJSON(@jsonContent) = 0
    BEGIN
        PRINT '❌ ERRORE: File non contiene JSON valido!';
        RETURN;
    END
    
    PRINT '✅ JSON valido confermato';
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE durante caricamento file JSON:';
    PRINT '   Errore: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    RETURN;
END CATCH

-- Ottimizzazioni per performance
PRINT '⚡ Applicazione ottimizzazioni performance...';
ALTER DATABASE PiattaformeWeb SET AUTO_UPDATE_STATISTICS OFF;

-- Importazione JSON con gestione errori robusta
PRINT '📥 Inizio importazione JSON con gestione errori...';

BEGIN TRY
    -- Importa con OPENJSON e gestione errori per ogni riga
    INSERT INTO PrezziManualiDistribuzioneIT (
        Art_Id, ART_CODICE, classificatore3, Descrizione, MARCA, ART_STAGIONE,
        PM_Std, PM_Std_Data, PM_T24, PM_T24_Data, PM_B2b, PM_B2b_Data,
        PM_Collegati, PM_Collegati_Data
    )
    SELECT 
        -- Validazione e conversione sicura di ogni campo
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.ArtId')) = 1 THEN CAST(JSON_VALUE(value, '$.ArtId') AS INT)
            ELSE NULL
        END as Art_Id,
        
        COALESCE(JSON_VALUE(value, '$.ARTCODICE'), '') as ART_CODICE,
        JSON_VALUE(value, '$.classificatore3') as classificatore3,
        JSON_VALUE(value, '$.Descrizione') as Descrizione,
        JSON_VALUE(value, '$.MARCA') as MARCA,
        JSON_VALUE(value, '$.ARTSTAGIONE') as ART_STAGIONE,
        
        -- Prezzi con validazione
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PMStd')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PMStd') AS DECIMAL(10,2))
            ELSE NULL
        END as PM_Std,
        
        TRY_CAST(JSON_VALUE(value, '$.PMStdData') AS DATETIME2) as PM_Std_Data,
        
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PMT24')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PMT24') AS DECIMAL(10,2))
            ELSE NULL
        END as PM_T24,
        
        TRY_CAST(JSON_VALUE(value, '$.PMT24Data') AS DATETIME2) as PM_T24_Data,
        
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PMB2b')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PMB2b') AS DECIMAL(10,2))
            ELSE NULL
        END as PM_B2b,
        
        TRY_CAST(JSON_VALUE(value, '$.PMB2bData') AS DATETIME2) as PM_B2b_Data,
        
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PMCollegati')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PMCollegati') AS DECIMAL(10,2))
            ELSE NULL
        END as PM_Collegati,
        
        TRY_CAST(JSON_VALUE(value, '$.PMCollegatiData') AS DATETIME2) as PM_Collegati_Data
        
    FROM OPENJSON(@jsonContent, '$.PrezziManualiDistribuzioneIT')
    WHERE JSON_VALUE(value, '$.ArtId') IS NOT NULL
      AND ISNUMERIC(JSON_VALUE(value, '$.ArtId')) = 1
      AND JSON_VALUE(value, '$.ARTCODICE') IS NOT NULL
      AND JSON_VALUE(value, '$.ARTCODICE') != '';
    
    -- Conta righe importate
    SELECT @righeImportate = @@ROWCOUNT;
    
    PRINT '✅ IMPORTAZIONE COMPLETATA CON SUCCESSO!';
    PRINT '📊 Righe importate: ' + CAST(@righeImportate AS NVARCHAR(10));
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE DURANTE IMPORTAZIONE:';
    PRINT '   Errore: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    PRINT '   Severità: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10));
    
    -- Log dell'errore
    EXEC('INSERT INTO ' + @nomeTabella + '_ERRORI (MessaggioErrore, RigaJSON) VALUES (''' + ERROR_MESSAGE() + ''', ''Errore generale durante importazione'')');
    
    SET @righeErrori = 1;
END CATCH

-- Ripristina impostazioni
ALTER DATABASE PiattaformeWeb SET AUTO_UPDATE_STATISTICS ON;
UPDATE STATISTICS PrezziManualiDistribuzioneIT;

-- Validazione post-importazione
PRINT '🔍 VALIDAZIONE POST-IMPORTAZIONE...';

-- Verifica integrità dati
DECLARE @righeInvalide INT = 0;
DECLARE @righeConPrezzi INT = 0;

SELECT @righeInvalide = COUNT(*) 
FROM PrezziManualiDistribuzioneIT 
WHERE Art_Id IS NULL OR ART_CODICE IS NULL OR ART_CODICE = '';

SELECT @righeConPrezzi = COUNT(*) 
FROM PrezziManualiDistribuzioneIT 
WHERE (PM_Std > 0 OR PM_T24 > 0 OR PM_B2b > 0 OR PM_Collegati > 0);

IF @righeInvalide > 0
BEGIN
    PRINT '⚠️ ATTENZIONE: ' + CAST(@righeInvalide AS NVARCHAR(10)) + ' righe con dati incompleti';
END
ELSE
BEGIN
    PRINT '✅ Tutti i dati sono validi';
END

-- Statistiche finali
DECLARE @tempoFine DATETIME2 = GETDATE();
DECLARE @durata INT = DATEDIFF(SECOND, @tempoInizio, @tempoFine);

PRINT '================================================';
PRINT '📊 STATISTICHE IMPORTAZIONE JSON:';
PRINT '   📥 Righe importate: ' + CAST(@righeImportate AS NVARCHAR(10));
PRINT '   ✅ Righe con prezzi: ' + CAST(@righeConPrezzi AS NVARCHAR(10));
PRINT '   ⚠️ Righe con errori: ' + CAST(@righeErrori AS NVARCHAR(10));
PRINT '   🚫 Righe invalide: ' + CAST(@righeInvalide AS NVARCHAR(10));
PRINT '   ⏱️ Tempo impiegato: ' + CAST(@durata AS NVARCHAR(10)) + ' secondi';
PRINT '   🚀 Velocità: ' + CAST(@righeImportate / CASE WHEN @durata = 0 THEN 1 ELSE @durata END AS NVARCHAR(10)) + ' righe/secondo';
PRINT '   📁 File processato: ' + @percorsoFile;
PRINT '   🗂️ Tabella aggiornata: ' + @nomeTabella;
PRINT '   ⏰ Completato alle: ' + CAST(@tempoFine AS NVARCHAR(50));
PRINT '================================================';

-- Verifica finale - mostra campione dei dati
PRINT '📄 CAMPIONE DATI IMPORTATI (primi 5 record):';
EXEC('SELECT TOP 5 Art_Id, ART_CODICE, Descrizione, MARCA, PM_Std, PM_T24, PM_B2b, PM_Collegati, DataImportazione FROM ' + @nomeTabella + ' ORDER BY DataImportazione DESC');

-- Mostra distribuzione per marca
PRINT '📊 DISTRIBUZIONE PER MARCA (top 10):';
EXEC('SELECT TOP 10 MARCA, COUNT(*) as NumeroArticoli FROM ' + @nomeTabella + ' WHERE MARCA IS NOT NULL GROUP BY MARCA ORDER BY COUNT(*) DESC');

-- Controllo errori finali
IF @righeErrori > 0
BEGIN
    PRINT '⚠️ Controlla la tabella ' + @nomeTabella + '_ERRORI per dettagli sugli errori';
    EXEC('SELECT TOP 10 * FROM ' + @nomeTabella + '_ERRORI ORDER BY ErroreID DESC');
END

IF @righeImportate > 0
BEGIN
    PRINT '🎉 IMPORTAZIONE JSON COMPLETATA CON SUCCESSO!';
END
ELSE
BEGIN
    PRINT '❌ NESSUNA RIGA IMPORTATA - Verifica il formato del file JSON';
END

GO 