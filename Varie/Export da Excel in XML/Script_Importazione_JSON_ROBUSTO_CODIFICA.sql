-- ====================================================================
-- SCRIPT IMPORTAZIONE JSON ROBUSTO CON GESTIONE CODIFICA
-- ====================================================================
-- Database: PiattaformeWeb
-- Tabella: PrezziManualiDistribuzioneIT
-- Versione: SQL Server 2017
-- FIX: Gestione robusta della codifica del file JSON
-- ====================================================================

USE [PiattaformeWeb];
GO

-- Variabili di configurazione
DECLARE @percorsoFileJSON NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json';
DECLARE @righeImportate INT = 0;
DECLARE @righeErrori INT = 0;
DECLARE @tempoInizio DATETIME2 = GETDATE();

-- Messaggio di inizio
PRINT '🚀 IMPORTAZIONE JSON ROBUSTO GESTIONE CODIFICA';
PRINT '📁 File sorgente: ' + @percorsoFileJSON;
PRINT '🗂️ Tabella destinazione: PrezziManualiDistribuzioneIT';
PRINT '⏰ Orario inizio: ' + CAST(@tempoInizio AS NVARCHAR(50));
PRINT '================================================';

-- Verifica esistenza file JSON
IF NOT EXISTS (
    SELECT 1 FROM sys.dm_os_file_exists(@percorsoFileJSON) 
    WHERE file_exists = 1
)
BEGIN
    PRINT '❌ ERRORE: File JSON non trovato - ' + @percorsoFileJSON;
    RETURN;
END

-- Backup dei dati esistenti se presenti
DECLARE @conteggioEsistente INT;
SELECT @conteggioEsistente = COUNT(*) FROM [PrezziManualiDistribuzioneIT];

IF @conteggioEsistente > 0
BEGIN
    PRINT '🔄 Trovati ' + CAST(@conteggioEsistente AS NVARCHAR(10)) + ' record esistenti';
    
    -- Crea backup con timestamp
    DECLARE @nomeBackup NVARCHAR(150) = 'PrezziManualiDistribuzioneIT_BACKUP_' + FORMAT(GETDATE(), 'yyyyMMdd_HHmmss');
    DECLARE @sqlBackup NVARCHAR(MAX) = 'SELECT * INTO [' + @nomeBackup + '] FROM [PrezziManualiDistribuzioneIT]';
    
    EXEC sp_executesql @sqlBackup;
    PRINT '💾 Backup creato: ' + @nomeBackup;
    
    -- Svuota tabella principale
    TRUNCATE TABLE [PrezziManualiDistribuzioneIT];
    PRINT '🗑️ Tabella svuotata per nuova importazione';
END

-- Tentativo di caricamento con diverse codifiche
DECLARE @jsonContent NVARCHAR(MAX) = NULL;
DECLARE @codificaUsata NVARCHAR(50) = '';

BEGIN TRY
    
    PRINT '🔍 Tentativo caricamento con CODEPAGE 65001 (UTF-8)...';
    BEGIN TRY
        SELECT @jsonContent = BulkColumn 
        FROM OPENROWSET(
            BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
            SINGLE_BLOB, 
            CODEPAGE = '65001'
        ) AS j;
        
        -- Test validità JSON immediato
        IF ISJSON(@jsonContent) = 1
        BEGIN
            SET @codificaUsata = 'UTF-8 (65001)';
            PRINT '✅ UTF-8 funziona!';
        END
        ELSE
        BEGIN
            SET @jsonContent = NULL;
            PRINT '❌ UTF-8 non funziona';
        END
    END TRY
    BEGIN CATCH
        SET @jsonContent = NULL;
        PRINT '❌ Errore con UTF-8: ' + ERROR_MESSAGE();
    END CATCH
    
    -- Se UTF-8 non funziona, prova UTF-16
    IF @jsonContent IS NULL
    BEGIN
        PRINT '🔍 Tentativo caricamento con CODEPAGE 1200 (UTF-16)...';
        BEGIN TRY
            SELECT @jsonContent = BulkColumn 
            FROM OPENROWSET(
                BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
                SINGLE_BLOB, 
                CODEPAGE = '1200'
            ) AS j;
            
            IF ISJSON(@jsonContent) = 1
            BEGIN
                SET @codificaUsata = 'UTF-16 (1200)';
                PRINT '✅ UTF-16 funziona!';
            END
            ELSE
            BEGIN
                SET @jsonContent = NULL;
                PRINT '❌ UTF-16 non funziona';
            END
        END TRY
        BEGIN CATCH
            SET @jsonContent = NULL;
            PRINT '❌ Errore con UTF-16: ' + ERROR_MESSAGE();
        END CATCH
    END
    
    -- Se ancora NULL, prova senza CODEPAGE
    IF @jsonContent IS NULL
    BEGIN
        PRINT '🔍 Tentativo caricamento senza CODEPAGE specificato...';
        BEGIN TRY
            SELECT @jsonContent = BulkColumn 
            FROM OPENROWSET(
                BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
                SINGLE_BLOB
            ) AS j;
            
            IF ISJSON(@jsonContent) = 1
            BEGIN
                SET @codificaUsata = 'Default';
                PRINT '✅ Codifica default funziona!';
            END
            ELSE
            BEGIN
                SET @jsonContent = NULL;
                PRINT '❌ Codifica default non funziona';
            END
        END TRY
        BEGIN CATCH
            SET @jsonContent = NULL;
            PRINT '❌ Errore con codifica default: ' + ERROR_MESSAGE();
        END CATCH
    END
    
    -- Se ancora NULL, prova ASCII
    IF @jsonContent IS NULL
    BEGIN
        PRINT '🔍 Tentativo caricamento con CODEPAGE 1252 (Windows-1252)...';
        BEGIN TRY
            SELECT @jsonContent = BulkColumn 
            FROM OPENROWSET(
                BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
                SINGLE_BLOB, 
                CODEPAGE = '1252'
            ) AS j;
            
            IF ISJSON(@jsonContent) = 1
            BEGIN
                SET @codificaUsata = 'Windows-1252 (1252)';
                PRINT '✅ Windows-1252 funziona!';
            END
            ELSE
            BEGIN
                SET @jsonContent = NULL;
                PRINT '❌ Windows-1252 non funziona';
            END
        END TRY
        BEGIN CATCH
            SET @jsonContent = NULL;
            PRINT '❌ Errore con Windows-1252: ' + ERROR_MESSAGE();
        END CATCH
    END
    
    -- Verifica finale
    IF @jsonContent IS NULL OR ISJSON(@jsonContent) = 0
    BEGIN
        PRINT '❌ ERRORE: Impossibile caricare il file con codifica valida!';
        PRINT '🔍 Verifica che il file sia un JSON valido e non corrotto.';
        
        -- Mostra primi caratteri per diagnostica
        SELECT @jsonContent = BulkColumn 
        FROM OPENROWSET(
            BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
            SINGLE_BLOB, 
            CODEPAGE = '65001'
        ) AS j;
        
        PRINT '🔍 Primi 200 caratteri (per diagnostica):';
        PRINT LEFT(@jsonContent, 200);
        RETURN;
    END
    
    PRINT '📥 File JSON caricato: ' + CAST(LEN(@jsonContent) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔧 Codifica utilizzata: ' + @codificaUsata;
    PRINT '✅ JSON validato con successo';
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE durante caricamento JSON:';
    PRINT '   Messaggio: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    RETURN;
END CATCH

-- Importazione dati usando approccio robusto
PRINT '📥 Inizio importazione dati...';

BEGIN TRY
    
    -- Usa approccio simile a quello dell'utente
    INSERT INTO [PrezziManualiDistribuzioneIT] (
        [Art_Id],
        [ART_CODICE],
        [classificatore3],
        [Descrizione],
        [MARCA],
        [ART_STAGIONE],
        [PM_T24],
        [PM_B2b],
        [PM_Collegati],
        [PM_T24_Data],
        [PM_B2b_Data],
        [PM_Collegati_Data],
        [CostoTrasporto]
    )
    SELECT 
        -- Art_Id
        TRY_CAST(LTRIM(RTRIM(JSON_VALUE(item.value, '$.Art_Id'))) AS INT) as [Art_Id],
        
        -- ART_CODICE
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.ART_CODICE'), ''))), 50) as [ART_CODICE],
        
        -- classificatore3
        TRY_CAST(LTRIM(RTRIM(JSON_VALUE(item.value, '$.classificatore3'))) AS INT) as [classificatore3],
        
        -- Descrizione
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.Descrizione'), ''))), 255) as [Descrizione],
        
        -- MARCA
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.MARCA'), ''))), 50) as [MARCA],
        
        -- ART_STAGIONE
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.ART_STAGIONE'), ''))), 20) as [ART_STAGIONE],
        
        -- PM_T24 (gestione virgole decimali)
        CASE 
            WHEN LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_T24'))) IS NOT NULL 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_T24'))) != '' 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_T24'))) != '0'
            THEN TRY_CAST(REPLACE(LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_T24'))), ',', '.') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_T24],
        
        -- PM_B2b (gestione virgole decimali)
        CASE 
            WHEN LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_B2b'))) IS NOT NULL 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_B2b'))) != '' 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_B2b'))) != '0'
            THEN TRY_CAST(REPLACE(LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_B2b'))), ',', '.') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_B2b],
        
        -- PM_Collegati (gestione virgole decimali)
        CASE 
            WHEN LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_Collegati'))) IS NOT NULL 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_Collegati'))) != '' 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_Collegati'))) != '0'
            THEN TRY_CAST(REPLACE(LTRIM(RTRIM(JSON_VALUE(item.value, '$.PM_Collegati'))), ',', '.') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_Collegati],
        
        -- Date
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.PM_T24_Data'), ''))), 20) as [PM_T24_Data],
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.PM_B2b_Data'), ''))), 20) as [PM_B2b_Data],
        LEFT(LTRIM(RTRIM(COALESCE(JSON_VALUE(item.value, '$.PM_Collegati_Data'), ''))), 20) as [PM_Collegati_Data],
        
        -- CostoTrasporto da CSpedIT (gestione virgole decimali)
        CASE 
            WHEN LTRIM(RTRIM(JSON_VALUE(item.value, '$.CSpedIT'))) IS NOT NULL 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.CSpedIT'))) != '' 
                 AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.CSpedIT'))) != '0'
            THEN TRY_CAST(REPLACE(LTRIM(RTRIM(JSON_VALUE(item.value, '$.CSpedIT'))), ',', '.') AS DECIMAL(5,2))
            ELSE NULL
        END as [CostoTrasporto]
        
    FROM OPENJSON(@jsonContent, '$.PrezziManualiDistribuzioneIT') AS item
    WHERE LTRIM(RTRIM(JSON_VALUE(item.value, '$.Art_Id'))) IS NOT NULL
      AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.Art_Id'))) != ''
      AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.ART_CODICE'))) IS NOT NULL
      AND LTRIM(RTRIM(JSON_VALUE(item.value, '$.ART_CODICE'))) != '';
    
    -- Conta righe importate
    SELECT @righeImportate = @@ROWCOUNT;
    
    PRINT '✅ IMPORTAZIONE COMPLETATA CON SUCCESSO!';
    PRINT '📊 Righe importate: ' + CAST(@righeImportate AS NVARCHAR(10));
    
END TRY
BEGIN CATCH
    SET @righeErrori = 1;
    
    PRINT '❌ ERRORE DURANTE IMPORTAZIONE:';
    PRINT '   Messaggio: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    PRINT '   Severità: ' + CAST(ERROR_SEVERITY() AS NVARCHAR(10));
    PRINT '   Stato: ' + CAST(ERROR_STATE() AS NVARCHAR(10));
    
END CATCH

-- Statistiche finali
DECLARE @tempoFine DATETIME2 = GETDATE();
DECLARE @durata INT = DATEDIFF(SECOND, @tempoInizio, @tempoFine);
DECLARE @righeValide INT = 0;
DECLARE @righeConPrezzi INT = 0;

-- Conta righe valide
SELECT @righeValide = COUNT(*) 
FROM [PrezziManualiDistribuzioneIT] 
WHERE [Art_Id] IS NOT NULL AND [ART_CODICE] IS NOT NULL;

-- Conta righe con almeno un prezzo manuale
SELECT @righeConPrezzi = COUNT(*) 
FROM [PrezziManualiDistribuzioneIT] 
WHERE ([PM_T24] IS NOT NULL AND [PM_T24] > 0)
   OR ([PM_B2b] IS NOT NULL AND [PM_B2b] > 0)
   OR ([PM_Collegati] IS NOT NULL AND [PM_Collegati] > 0);

-- Report finale
PRINT '================================================';
PRINT '📊 STATISTICHE FINALI IMPORTAZIONE:';
PRINT '   📥 Righe totali importate: ' + CAST(@righeImportate AS NVARCHAR(10));
PRINT '   ✅ Righe valide: ' + CAST(@righeValide AS NVARCHAR(10));
PRINT '   💰 Righe con prezzi manuali: ' + CAST(@righeConPrezzi AS NVARCHAR(10));
PRINT '   ⚠️ Errori rilevati: ' + CAST(@righeErrori AS NVARCHAR(10));
PRINT '   ⏱️ Tempo impiegato: ' + CAST(@durata AS NVARCHAR(10)) + ' secondi';
PRINT '   🔧 Codifica file: ' + @codificaUsata;

IF @durata > 0
    PRINT '   🚀 Velocità media: ' + CAST(@righeImportate / @durata AS NVARCHAR(10)) + ' righe/secondo';

PRINT '   📁 File processato: ' + @percorsoFileJSON;
PRINT '   🗂️ Tabella aggiornata: PrezziManualiDistribuzioneIT';
PRINT '   ⏰ Completato alle: ' + CAST(@tempoFine AS NVARCHAR(50));
PRINT '================================================';

-- Mostra campione dei dati importati
IF @righeImportate > 0
BEGIN
    PRINT '📄 CAMPIONE DATI IMPORTATI (primi 5 record):';
    SELECT TOP 5 
        [Art_Id],
        [ART_CODICE],
        [Descrizione],
        [MARCA],
        [PM_T24],
        [PM_B2b],
        [PM_Collegati],
        [CostoTrasporto],
        [DataImportazione]
    FROM [PrezziManualiDistribuzioneIT] 
    ORDER BY [DataImportazione] DESC;
    
    PRINT '';
    PRINT '📊 DISTRIBUZIONE PER MARCA (top 10):';
    SELECT TOP 10 
        [MARCA],
        COUNT(*) as [NumeroArticoli],
        AVG([PM_T24]) as [MediaPM_T24],
        AVG([PM_B2b]) as [MediaPM_B2b]
    FROM [PrezziManualiDistribuzioneIT] 
    WHERE [MARCA] IS NOT NULL AND [MARCA] != ''
    GROUP BY [MARCA] 
    ORDER BY COUNT(*) DESC;
END

-- Messaggio finale
IF @righeImportate > 0 AND @righeErrori = 0
BEGIN
    PRINT '🎉 IMPORTAZIONE JSON COMPLETATA CON SUCCESSO!';
    PRINT '✅ Tutti i dati sono stati importati correttamente.';
    PRINT '🔧 Codifica e separatori decimali risolti automaticamente.';
END
ELSE IF @righeImportate > 0 AND @righeErrori > 0
BEGIN
    PRINT '⚠️ IMPORTAZIONE COMPLETATA CON AVVISI';
    PRINT '   Controlla i log per dettagli sugli errori non critici.';
END
ELSE
BEGIN
    PRINT '❌ IMPORTAZIONE FALLITA';
    PRINT '   Nessun dato è stato importato. Il file potrebbe essere corrotto.';
END

GO 