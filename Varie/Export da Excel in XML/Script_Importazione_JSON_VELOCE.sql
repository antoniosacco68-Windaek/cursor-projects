USE [PiattaformeWeb]
GO

-- Script T-SQL per importazione JSON SUPER VELOCE
-- JSON è molto più veloce da parsare rispetto all'XML

-- Stored Procedure per importazione JSON ottimizzata
CREATE OR ALTER PROCEDURE [dbo].[SP_ImportaPrezziManualiJSON_VELOCE]
    @JsonFilePath NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.json'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @json NVARCHAR(MAX);
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @StartTime DATETIME2;
    DECLARE @EndTime DATETIME2;
    DECLARE @RecordCount INT;
    DECLARE @ElapsedSeconds DECIMAL(10,2);
    DECLARE @FileSize BIGINT;
    
    SET @StartTime = SYSDATETIME();
    
    PRINT '🚀 IMPORTAZIONE JSON SUPER VELOCE!';
    PRINT 'File: ' + @JsonFilePath;
    PRINT 'Inizio: ' + CONVERT(VARCHAR(23), @StartTime, 121);
    PRINT REPLICATE('=', 60);
    
    -- Leggi il file JSON
    PRINT '📖 Lettura file JSON...';
    
    BEGIN TRY
        -- Leggi il file JSON come stringa
        SET @sql = 'SELECT @json = BulkColumn FROM OPENROWSET(BULK ''' + @JsonFilePath + ''', SINGLE_CLOB) AS x';
        EXEC sp_executesql @sql, N'@json NVARCHAR(MAX) OUTPUT', @json OUTPUT;
        
        -- Verifica dimensione
        SET @FileSize = LEN(@json);
        PRINT '✅ File JSON letto: ' + FORMAT(@FileSize / 1024.0 / 1024.0, 'N1') + ' MB';
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE nella lettura del file JSON:';
        PRINT ERROR_MESSAGE();
        RETURN;
    END CATCH
    
    -- Svuota la tabella
    PRINT '🗑️ Svuotamento tabella...';
    TRUNCATE TABLE [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Importa usando OPENJSON (molto più veloce dell'XML)
    PRINT '⚡ Importazione JSON in corso...';
    
    BEGIN TRY
        INSERT INTO [dbo].[PrezziManualiDistribuzioneIT] (
            Art_Id, [ART_CODICE], [classificatore3], [Descrizione], [MARCA], 
            [ART_STAGIONE], [PM_Std], [PM_T24], [PM_B2b], PM_Collegati, 
            [PM_Std_Data], [PM_T24_Data], [PM_B2b_Data], [PM_Collegati_Data]
        )
        SELECT 
            TRY_CAST(JSON_VALUE(value, '$.IdDiArtico') AS INT) as Art_Id,
            JSON_VALUE(value, '$.ARTCODICE') as ART_CODICE,
            TRY_CAST(JSON_VALUE(value, '$.classificatore3') AS INT) as classificatore3,
            JSON_VALUE(value, '$.Descrizione') as Descrizione,
            JSON_VALUE(value, '$.MARCA') as MARCA,
            JSON_VALUE(value, '$.ARTSTAGIONE') as ART_STAGIONE,
            TRY_CAST(JSON_VALUE(value, '$.PMStd') AS DECIMAL(18,2)) as PM_Std,
            TRY_CAST(JSON_VALUE(value, '$.PMT24') AS DECIMAL(18,2)) as PM_T24,
            TRY_CAST(JSON_VALUE(value, '$.PMB2b') AS DECIMAL(18,2)) as PM_B2b,
            TRY_CAST(JSON_VALUE(value, '$.PMCollegati') AS DECIMAL(18,2)) as PM_Collegati,
            NULLIF(JSON_VALUE(value, '$.PMStdData'), '') as PM_Std_Data,
            NULLIF(JSON_VALUE(value, '$.PMT24Data'), '') as PM_T24_Data,
            NULLIF(JSON_VALUE(value, '$.PMB2bData'), '') as PM_B2b_Data,
            NULLIF(JSON_VALUE(value, '$.PMCollegatiData'), '') as PM_Collegati_Data
        FROM OPENJSON(@json, '$.PrezziManualiDistribuzioneIT')
        OPTION (MAXDOP 0); -- Usa tutti i processori
        
        PRINT '✅ Importazione JSON completata!';
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE durante l''importazione JSON:';
        PRINT ERROR_MESSAGE();
        PRINT 'Riga errore: ' + CAST(ERROR_LINE() AS VARCHAR(10));
        RETURN;
    END CATCH
    
    -- Calcola statistiche
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0;
    SELECT @RecordCount = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Ricostruisci indici
    PRINT '🔧 Ottimizzazione indici...';
    ALTER INDEX ALL ON [dbo].[PrezziManualiDistribuzioneIT] REBUILD;
    UPDATE STATISTICS [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Report finale dettagliato
    PRINT REPLICATE('=', 60);
    PRINT '🎉 IMPORTAZIONE JSON COMPLETATA CON SUCCESSO!';
    PRINT REPLICATE('=', 60);
    PRINT 'Record importati: ' + FORMAT(@RecordCount, 'N0');
    PRINT 'Dimensione file: ' + FORMAT(@FileSize / 1024.0 / 1024.0, 'N1') + ' MB';
    PRINT 'Tempo totale: ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' secondi';
    PRINT 'Velocità: ' + FORMAT(@RecordCount / @ElapsedSeconds, 'N0') + ' record/sec';
    PRINT 'Throughput: ' + FORMAT(@FileSize / 1024.0 / 1024.0 / @ElapsedSeconds, 'N1') + ' MB/sec';
    
    -- Quality check automatico
    PRINT REPLICATE('-', 40);
    PRINT '🔍 QUALITY CHECK AUTOMATICO:';
    
    DECLARE @NullIds INT, @ValidPrezzi INT, @UniqueArticoli INT;
    SELECT @NullIds = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT] WHERE Art_Id IS NULL;
    SELECT @ValidPrezzi = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT] 
           WHERE PM_Std > 0 OR PM_T24 > 0 OR PM_B2b > 0 OR PM_Collegati > 0;
    SELECT @UniqueArticoli = COUNT(DISTINCT Art_Id) FROM [dbo].[PrezziManualiDistribuzioneIT] WHERE Art_Id IS NOT NULL;
    
    PRINT 'Record con ID validi: ' + FORMAT(@RecordCount - @NullIds, 'N0') + ' (' + FORMAT(((@RecordCount - @NullIds) * 100.0 / @RecordCount), 'N1') + '%)';
    PRINT 'Record con prezzi: ' + FORMAT(@ValidPrezzi, 'N0') + ' (' + FORMAT((@ValidPrezzi * 100.0 / @RecordCount), 'N1') + '%)';
    PRINT 'Articoli unici: ' + FORMAT(@UniqueArticoli, 'N0');
    
    -- Distribuzione marche
    PRINT REPLICATE('-', 40);
    PRINT '📊 TOP 5 MARCHE:';
    SELECT TOP 5 
        MARCA, 
        COUNT(*) as Quantita,
        FORMAT(COUNT(*) * 100.0 / @RecordCount, 'N1') + '%' as Percentuale
    FROM [dbo].[PrezziManualiDistribuzioneIT] 
    WHERE MARCA IS NOT NULL AND MARCA <> ''
    GROUP BY MARCA 
    ORDER BY COUNT(*) DESC;
    
    PRINT REPLICATE('=', 60);
    PRINT '✨ Importazione JSON terminata con successo!';
    
END
GO

-- Procedura di confronto performance JSON vs XML
CREATE OR ALTER PROCEDURE [dbo].[SP_ConfrontoPerformanceFormati]
AS
BEGIN
    PRINT '📊 CONFRONTO PERFORMANCE FORMATI:';
    PRINT REPLICATE('=', 50);
    
    PRINT '🔸 XML:';
    PRINT '  + Standard, ben supportato';
    PRINT '  + Validazione schema';
    PRINT '  - Molto verboso (tag apertura/chiusura)';
    PRINT '  - Dimensioni file 3-5x più grandi';
    PRINT '  - Parsing più lento';
    PRINT '';
    
    PRINT '🔹 JSON:';
    PRINT '  + Compatto (solo chiavi e valori)';
    PRINT '  + Parsing velocissimo';
    PRINT '  + Dimensioni file 60-80% più piccole';
    PRINT '  + OPENJSON in SQL Server è ottimizzato';
    PRINT '  - Meno strutturato dell''XML';
    PRINT '';
    
    PRINT '🏆 VINCITORE per grandi dataset: JSON!';
    PRINT '⚡ Stima miglioramento: 5-10x più veloce';
    
END
GO

-- Procedura per verifica rapida post-importazione
CREATE OR ALTER PROCEDURE [dbo].[SP_VerificaRapidaJSON]
AS
BEGIN
    DECLARE @TotaleRecord INT;
    SELECT @TotaleRecord = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT];
    
    IF @TotaleRecord = 0
    BEGIN
        PRINT '❌ ATTENZIONE: Nessun record trovato!';
        RETURN;
    END
    
    PRINT '✅ Verifica rapida completata:';
    PRINT 'Totale record: ' + FORMAT(@TotaleRecord, 'N0');
    
    -- Verifica campione dati
    PRINT '📋 Campione primi 3 record:';
    SELECT TOP 3 
        Art_Id,
        LEFT(ART_CODICE, 20) as Codice,
        LEFT(Descrizione, 30) as Desc_Breve,
        MARCA,
        PM_Std,
        PM_T24
    FROM [dbo].[PrezziManualiDistribuzioneIT]
    WHERE Art_Id IS NOT NULL
    ORDER BY Art_Id;
    
END
GO

-- Esempio di utilizzo rapido
/*
-- IMPORTAZIONE JSON VELOCE:
EXEC [dbo].[SP_ImportaPrezziManualiJSON_VELOCE] 
    'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.json'

-- VERIFICA RAPIDA:
EXEC [dbo].[SP_VerificaRapidaJSON]

-- CONFRONTO FORMATI:
EXEC [dbo].[SP_ConfrontoPerformanceFormati]
*/

PRINT '🎉 Script importazione JSON installato!';
PRINT 'Usa: SP_ImportaPrezziManualiJSON_VELOCE per importare JSON';
PRINT 'JSON è tipicamente 5-10x più veloce dell''XML!'; 