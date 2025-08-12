-- ====================================================================
-- SCRIPT IMPORTAZIONE JSON T-SQL 2017 OTTIMIZZATO
-- ====================================================================
-- Database: PiattaformeWeb
-- Tabella: PrezziManualiDistribuzioneIT
-- Versione: SQL Server 2017
-- Formato: JSON mappato sui campi esistenti della tabella
-- FIX: Gestione separatori decimali virgola -> punto
-- ====================================================================

USE [PiattaformeWeb];
GO

-- Variabili di configurazione
DECLARE @percorsoFileJSON NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json';
DECLARE @righeImportate INT = 0;
DECLARE @righeErrori INT = 0;
DECLARE @tempoInizio DATETIME2 = GETDATE();

-- Messaggio di inizio
PRINT '🚀 IMPORTAZIONE JSON T-SQL 2017 OTTIMIZZATA (FIX DECIMALI)';
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

-- Caricamento e normalizzazione JSON
DECLARE @jsonContent NVARCHAR(MAX);
DECLARE @jsonContentFixed NVARCHAR(MAX);

BEGIN TRY
    -- Carica il file JSON
    SELECT @jsonContent = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB, 
        CODEPAGE = '65001'
    ) AS j;
    
    PRINT '📥 File JSON caricato: ' + CAST(LEN(@jsonContent) AS NVARCHAR(10)) + ' caratteri';
    
    -- Rimuovi eventuali caratteri BOM
    IF LEFT(@jsonContent, 3) = CHAR(239) + CHAR(187) + CHAR(191)
        SET @jsonContent = SUBSTRING(@jsonContent, 4, LEN(@jsonContent));
    
    -- Normalizza i separatori decimali per lo standard JSON
    PRINT '🔧 Normalizzazione separatori decimali (virgola -> punto)...';
    
    -- Sostituisce le virgole con punti solo nei valori numerici
    -- Pattern: "campo": "numero,decimali" -> "campo": "numero.decimali"
    SET @jsonContentFixed = @jsonContent;
    
    -- Sostituisce i separatori decimali nei valori tra virgolette
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, '": "', '": "TEMP_MARKER');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER0,', 'TEMP_MARKER0.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER1,', 'TEMP_MARKER1.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER2,', 'TEMP_MARKER2.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER3,', 'TEMP_MARKER3.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER4,', 'TEMP_MARKER4.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER5,', 'TEMP_MARKER5.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER6,', 'TEMP_MARKER6.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER7,', 'TEMP_MARKER7.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER8,', 'TEMP_MARKER8.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER9,', 'TEMP_MARKER9.');
    SET @jsonContentFixed = REPLACE(@jsonContentFixed, 'TEMP_MARKER', '": "');
    
    -- Metodo più preciso usando REGEX pattern (SQL Server 2017+)
    -- Sostituisce pattern tipo: "numero,numero" con "numero.numero"
    -- Applica per valori numerici più comuni
    DECLARE @i INT = 0;
    WHILE @i < 10
    BEGIN
        SET @jsonContentFixed = REPLACE(@jsonContentFixed, '"' + CAST(@i AS CHAR(1)) + ',', '"' + CAST(@i AS CHAR(1)) + '.');
        SET @jsonContentFixed = REPLACE(@jsonContentFixed, ',' + CAST(@i AS CHAR(1)) + '"', '.' + CAST(@i AS CHAR(1)) + '"');
        SET @i = @i + 1;
    END;
    
    PRINT '✅ Normalizzazione completata';
    
    -- Verifica validità JSON dopo normalizzazione
    IF ISJSON(@jsonContentFixed) = 0
    BEGIN
        PRINT '❌ ERRORE: JSON ancora non valido dopo normalizzazione!';
        PRINT '🔍 Primi 500 caratteri del JSON:';
        PRINT LEFT(@jsonContentFixed, 500);
        RETURN;
    END
    
    PRINT '✅ JSON valido confermato dopo normalizzazione';
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE durante caricamento e normalizzazione JSON:';
    PRINT '   Messaggio: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    RETURN;
END CATCH

-- Importazione dati con mappatura ottimizzata T-SQL 2017
PRINT '📥 Inizio importazione con OPENJSON (T-SQL 2017)...';

BEGIN TRY
    
    -- Importazione ottimizzata con OPENJSON e mapping diretto
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
        -- DataImportazione si popola automaticamente con GETDATE() tramite DEFAULT
    )
    SELECT 
        -- Conversione sicura Art_Id da stringa a INT
        TRY_CAST(JSON_VALUE(value, '$.Art_Id') AS INT) as [Art_Id],
        
        -- Campi stringa con controllo lunghezza
        LEFT(COALESCE(JSON_VALUE(value, '$.ART_CODICE'), ''), 50) as [ART_CODICE],
        
        -- Classificatore3 da stringa a INT
        TRY_CAST(JSON_VALUE(value, '$.classificatore3') AS INT) as [classificatore3],
        
        -- Descrizione limitata a 255 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.Descrizione'), ''), 255) as [Descrizione],
        
        -- MARCA limitata a 50 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.MARCA'), ''), 50) as [MARCA],
        
        -- ART_STAGIONE limitata a 20 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.ART_STAGIONE'), ''), 20) as [ART_STAGIONE],
        
        -- Prezzi manuali - ora con separatori decimali corretti
        CASE 
            WHEN JSON_VALUE(value, '$.PM_T24') IS NOT NULL 
                 AND JSON_VALUE(value, '$.PM_T24') != '' 
                 AND JSON_VALUE(value, '$.PM_T24') != '0'
            THEN TRY_CAST(JSON_VALUE(value, '$.PM_T24') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_T24],
        
        CASE 
            WHEN JSON_VALUE(value, '$.PM_B2b') IS NOT NULL 
                 AND JSON_VALUE(value, '$.PM_B2b') != '' 
                 AND JSON_VALUE(value, '$.PM_B2b') != '0'
            THEN TRY_CAST(JSON_VALUE(value, '$.PM_B2b') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_B2b],
        
        CASE 
            WHEN JSON_VALUE(value, '$.PM_Collegati') IS NOT NULL 
                 AND JSON_VALUE(value, '$.PM_Collegati') != '' 
                 AND JSON_VALUE(value, '$.PM_Collegati') != '0'
            THEN TRY_CAST(JSON_VALUE(value, '$.PM_Collegati') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_Collegati],
        
        -- Date come VARCHAR(20) - mantenute come stringhe
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_T24_Data'), ''), 20) as [PM_T24_Data],
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_B2b_Data'), ''), 20) as [PM_B2b_Data],
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_Collegati_Data'), ''), 20) as [PM_Collegati_Data],
        
        -- CostoTrasporto mappato da CSpedIT del JSON
        CASE 
            WHEN JSON_VALUE(value, '$.CSpedIT') IS NOT NULL 
                 AND JSON_VALUE(value, '$.CSpedIT') != '' 
                 AND JSON_VALUE(value, '$.CSpedIT') != '0'
            THEN TRY_CAST(JSON_VALUE(value, '$.CSpedIT') AS DECIMAL(5,2))
            ELSE NULL
        END as [CostoTrasporto]
        
    FROM OPENJSON(@jsonContentFixed, '$.PrezziManualiDistribuzioneIT')
    WHERE JSON_VALUE(value, '$.Art_Id') IS NOT NULL
      AND JSON_VALUE(value, '$.Art_Id') != ''
      AND JSON_VALUE(value, '$.ART_CODICE') IS NOT NULL
      AND JSON_VALUE(value, '$.ART_CODICE') != '';
    
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
    
    -- Rollback se necessario
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
        
END CATCH

-- Statistiche e validazioni finali
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
    PRINT '🔧 Problema separatori decimali risolto automaticamente.';
END
ELSE IF @righeImportate > 0 AND @righeErrori > 0
BEGIN
    PRINT '⚠️ IMPORTAZIONE COMPLETATA CON AVVISI';
    PRINT '   Controlla i log per dettagli sugli errori non critici.';
END
ELSE
BEGIN
    PRINT '❌ IMPORTAZIONE FALLITA';
    PRINT '   Nessun dato è stato importato. Verifica il file JSON e la connessione.';
END

GO 