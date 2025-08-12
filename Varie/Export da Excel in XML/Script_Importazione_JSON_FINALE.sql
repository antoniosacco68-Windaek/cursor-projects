-- ====================================================================
-- SCRIPT IMPORTAZIONE JSON FINALE - FUNZIONANTE
-- ====================================================================
-- Database: PiattaformeWeb
-- Tabella: PrezziManualiDistribuzioneIT
-- Metodo: SINGLE_CLOB + REPLACE per decimali
-- ====================================================================

USE [PiattaformeWeb];
GO

-- Variabili di configurazione
DECLARE @JsonFilePath VARCHAR(200) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json';
DECLARE @righeImportate INT = 0;
DECLARE @righeErrori INT = 0;
DECLARE @tempoInizio DATETIME2 = GETDATE();

-- Messaggio di inizio
PRINT '🚀 IMPORTAZIONE JSON FINALE (SINGLE_CLOB + REPLACE DECIMALI)';
PRINT '📁 File sorgente: ' + @JsonFilePath;
PRINT '🗂️ Tabella destinazione: PrezziManualiDistribuzioneIT';
PRINT '⏰ Orario inizio: ' + CAST(@tempoInizio AS NVARCHAR(50));
PRINT '================================================';

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

-- Caricamento JSON con metodo funzionante
DECLARE @json NVARCHAR(MAX);
DECLARE @jsonFixed NVARCHAR(MAX);
DECLARE @sql NVARCHAR(4000);

BEGIN TRY
    
    -- Leggi il contenuto del file JSON usando SINGLE_CLOB
    SET @sql = 'SELECT @json = BulkColumn FROM OPENROWSET (BULK ''' + @JsonFilePath + ''', SINGLE_CLOB) AS x';
    EXEC sp_executesql @sql, N'@json NVARCHAR(MAX) OUTPUT', @json = @json OUTPUT;
    
    PRINT '📥 File JSON caricato: ' + CAST(LEN(@json) AS NVARCHAR(10)) + ' caratteri';
    
    -- Sostituisci virgole con punti nei valori numerici
    PRINT '🔧 Sostituzione virgole decimali con punti...';
    
    -- Metodo più efficace per sostituire le virgole nei valori numerici
    SET @jsonFixed = @json;
    
    -- Sostituisce virgole con punti in valori numerici tra virgolette
    -- Pattern: "campo": "numero,decimali" -> "campo": "numero.decimali"
    DECLARE @pattern NVARCHAR(50);
    DECLARE @replacement NVARCHAR(50);
    DECLARE @i INT = 0;
    
    -- Sostituisce per ogni cifra da 0 a 9 prima e dopo la virgola
    WHILE @i <= 9
    BEGIN
        SET @pattern = CAST(@i AS NCHAR(1)) + ',';
        SET @replacement = CAST(@i AS NCHAR(1)) + '.';
        SET @jsonFixed = REPLACE(@jsonFixed, @pattern, @replacement);
        
        SET @pattern = ',' + CAST(@i AS NCHAR(1));
        SET @replacement = '.' + CAST(@i AS NCHAR(1));
        SET @jsonFixed = REPLACE(@jsonFixed, @pattern, @replacement);
        
        SET @i = @i + 1;
    END;
    
    PRINT '✅ Sostituzione completata';
    
    -- Verifica validità JSON
    IF ISJSON(@jsonFixed) = 0
    BEGIN
        PRINT '❌ ERRORE: JSON non valido dopo sostituzione decimali!';
        PRINT '🔍 Primi 500 caratteri:';
        PRINT LEFT(@jsonFixed, 500);
        RETURN;
    END
    
    PRINT '✅ JSON validato con successo';
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE durante caricamento JSON:';
    PRINT '   Messaggio: ' + ERROR_MESSAGE();
    PRINT '   Riga: ' + CAST(ERROR_LINE() AS NVARCHAR(10));
    RETURN;
END CATCH

-- Importazione dati nella tabella
PRINT '📥 Inizio importazione dati nella tabella...';

BEGIN TRY
    
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
        -- DataImportazione si popola automaticamente con DEFAULT
    )
    SELECT 
        -- Art_Id - conversione sicura da stringa a INT
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.Art_Id')) = 1 THEN 
                CAST(JSON_VALUE(value, '$.Art_Id') AS INT)
            ELSE NULL
        END as [Art_Id],
        
        -- ART_CODICE - limitato a 50 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.ART_CODICE'), ''), 50) as [ART_CODICE],
        
        -- classificatore3 - conversione a INT
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.classificatore3')) = 1 THEN 
                CAST(JSON_VALUE(value, '$.classificatore3') AS INT)
            ELSE NULL
        END as [classificatore3],
        
        -- Descrizione - limitata a 255 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.Descrizione'), ''), 255) as [Descrizione],
        
        -- MARCA - limitata a 50 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.MARCA'), ''), 50) as [MARCA],
        
        -- ART_STAGIONE - limitata a 20 caratteri
        LEFT(COALESCE(JSON_VALUE(value, '$.ART_STAGIONE'), ''), 20) as [ART_STAGIONE],
        
        -- PM_T24 - ora i decimali sono corretti (punti)
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PM_T24')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PM_T24') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_T24],
        
        -- PM_B2b - ora i decimali sono corretti (punti)
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PM_B2b')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PM_B2b') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_B2b],
        
        -- PM_Collegati - ora i decimali sono corretti (punti)
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.PM_Collegati')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.PM_Collegati') AS DECIMAL(18,2))
            ELSE NULL
        END as [PM_Collegati],
        
        -- Date come VARCHAR(20) - conversione sicura
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_T24_Data'), ''), 20) as [PM_T24_Data],
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_B2b_Data'), ''), 20) as [PM_B2b_Data],
        LEFT(COALESCE(JSON_VALUE(value, '$.PM_Collegati_Data'), ''), 20) as [PM_Collegati_Data],
        
        -- CostoTrasporto da CSpedIT - ora i decimali sono corretti (punti)
        CASE 
            WHEN ISNUMERIC(JSON_VALUE(value, '$.CSpedIT')) = 1 THEN 
                TRY_CAST(JSON_VALUE(value, '$.CSpedIT') AS DECIMAL(5,2))
            ELSE NULL
        END as [CostoTrasporto]
        
    FROM OPENJSON(@jsonFixed, '$.PrezziManualiDistribuzioneIT')
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

IF @durata > 0
    PRINT '   🚀 Velocità media: ' + CAST(@righeImportate / @durata AS NVARCHAR(10)) + ' righe/secondo';

PRINT '   📁 File processato: ' + @JsonFilePath;
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
        AVG([PM_B2b]) as [MediaPM_B2b],
        SUM(CASE WHEN [PM_T24] > 0 THEN 1 ELSE 0 END) as [ArticoliConPM_T24]
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
    PRINT '🔧 Separatori decimali corretti automaticamente (virgola → punto).';
    PRINT '📋 Metodo: SINGLE_CLOB + REPLACE per compatibilità SQL Server.';
END
ELSE IF @righeImportate > 0 AND @righeErrori > 0
BEGIN
    PRINT '⚠️ IMPORTAZIONE COMPLETATA CON AVVISI';
    PRINT '   Controlla i log per dettagli sugli errori non critici.';
END
ELSE
BEGIN
    PRINT '❌ IMPORTAZIONE FALLITA';
    PRINT '   Nessun dato è stato importato. Verifica file e configurazione.';
END

GO 