USE [PiattaformeWeb]
GO

-- Script T-SQL OTTIMIZZATO per SQL Server 2017
-- Importazione veloce di grandi volumi XML

-- Stored Procedure OTTIMIZZATA per l'importazione XML
CREATE OR ALTER PROCEDURE [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML_VELOCE]
    @XmlFilePath NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml',
    @BatchSize INT = 5000,
    @ShowProgress BIT = 1
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @xml XML;
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @StartTime DATETIME2;
    DECLARE @EndTime DATETIME2;
    DECLARE @RecordCount INT;
    DECLARE @ElapsedSeconds DECIMAL(10,2);
    
    -- Impostazioni per performance
    SET @StartTime = SYSDATETIME();
    
    PRINT '🚀 Inizio importazione XML VELOCE...';
    PRINT 'File: ' + @XmlFilePath;
    PRINT 'Batch size: ' + CAST(@BatchSize AS VARCHAR(10));
    PRINT 'Timestamp: ' + CONVERT(VARCHAR(23), @StartTime, 121);
    PRINT REPLICATE('-', 50);
    
    -- Leggi il file XML
    PRINT '📁 Lettura file XML...';
    SET @sql = 'SELECT @xml = CAST(BulkColumn AS XML) FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x';
    
    BEGIN TRY
        EXEC sp_executesql @sql, N'@xml XML OUTPUT', @xml OUTPUT;
        PRINT '✅ File XML letto correttamente';
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE nella lettura del file XML:';
        PRINT ERROR_MESSAGE();
        RETURN;
    END CATCH
    
    -- Disabilita log per performance (solo se necessario)
    -- ALTER DATABASE [PiattaformeWeb] SET RECOVERY SIMPLE;
    
    -- Svuota la tabella prima dell'importazione
    PRINT '🗑️ Svuotamento tabella esistente...';
    TRUNCATE TABLE [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Importa i dati con ottimizzazioni
    PRINT '⚡ Importazione dati in corso...';
    
    INSERT INTO [dbo].[PrezziManualiDistribuzioneIT] (
        Art_Id, [ART_CODICE], [classificatore3], [Descrizione], [MARCA], 
        [ART_STAGIONE], [PM_Std], [PM_T24], [PM_B2b], PM_Collegati, 
        [PM_Std_Data], [PM_T24_Data], [PM_B2b_Data], [PM_Collegati_Data]
    )
    SELECT 
        TRY_CAST(T.c.value('Art_Id[1]', 'NVARCHAR(50)') AS INT),
        T.c.value('ART_CODICE[1]', 'NVARCHAR(50)'),
        TRY_CAST(T.c.value('classificatore3[1]', 'NVARCHAR(50)') AS INT),
        T.c.value('Descrizione[1]', 'NVARCHAR(255)'),
        T.c.value('MARCA[1]', 'NVARCHAR(50)'),
        T.c.value('ART_STAGIONE[1]', 'NVARCHAR(20)'),
        TRY_CAST(T.c.value('PM_Std[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        TRY_CAST(T.c.value('PM_T24[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        TRY_CAST(T.c.value('PM_B2b[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        TRY_CAST(T.c.value('PM_Collegati[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        NULLIF(T.c.value('PM_Std_Data[1]', 'NVARCHAR(20)'), ''),
        NULLIF(T.c.value('PM_T24_Data[1]', 'NVARCHAR(20)'), ''),
        NULLIF(T.c.value('PM_B2b_Data[1]', 'NVARCHAR(20)'), ''),
        NULLIF(T.c.value('PM_Collegati_Data[1]', 'NVARCHAR(20)'), '')
    FROM @xml.nodes('/PrezziManualiDistribuzioneIT/Articolo') T(c)
    OPTION (MAXDOP 0); -- Usa tutti i processori disponibili
    
    -- Calcola statistiche
    SET @EndTime = SYSDATETIME();
    SET @ElapsedSeconds = DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0;
    SELECT @RecordCount = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Ricostruisci indici per performance
    PRINT '🔧 Ricostruzione indici...';
    ALTER INDEX ALL ON [dbo].[PrezziManualiDistribuzioneIT] REBUILD;
    
    -- Aggiorna statistiche
    PRINT '📊 Aggiornamento statistiche...';
    UPDATE STATISTICS [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Messaggio di completamento con statistiche dettagliate
    PRINT REPLICATE('-', 50);
    PRINT '✅ IMPORTAZIONE COMPLETATA CON SUCCESSO!';
    PRINT REPLICATE('-', 50);
    PRINT 'Record importati: ' + FORMAT(@RecordCount, 'N0');
    PRINT 'Tempo impiegato: ' + CAST(@ElapsedSeconds AS VARCHAR(10)) + ' secondi';
    PRINT 'Velocità media: ' + FORMAT(@RecordCount / @ElapsedSeconds, 'N0') + ' record/sec';
    PRINT 'Timestamp fine: ' + CONVERT(VARCHAR(23), @EndTime, 121);
    
    -- Verifica quality check
    PRINT REPLICATE('-', 50);
    PRINT '🔍 QUALITY CHECK:';
    
    DECLARE @NullIds INT, @EmptyDescrizioni INT, @ValidPM INT;
    SELECT @NullIds = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT] WHERE Art_Id IS NULL;
    SELECT @EmptyDescrizioni = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT] WHERE Descrizione IS NULL OR Descrizione = '';
    SELECT @ValidPM = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT] WHERE PM_Std > 0 OR PM_T24 > 0 OR PM_B2b > 0 OR PM_Collegati > 0;
    
    PRINT 'Record con Art_Id NULL: ' + CAST(@NullIds AS VARCHAR(10));
    PRINT 'Record con Descrizione vuota: ' + CAST(@EmptyDescrizioni AS VARCHAR(10));
    PRINT 'Record con prezzi validi: ' + CAST(@ValidPM AS VARCHAR(10));
    
    -- Ripristina log normale (se modificato)
    -- ALTER DATABASE [PiattaformeWeb] SET RECOVERY FULL;
    
    PRINT REPLICATE('-', 50);
    PRINT '🎉 Importazione terminata!';
    
END
GO

-- Procedura per importazione con monitoraggio avanzato
CREATE OR ALTER PROCEDURE [dbo].[SP_ImportaConMonitoraggio]
    @XmlFilePath NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml'
AS
BEGIN
    DECLARE @StartTime DATETIME2 = SYSDATETIME();
    DECLARE @FileSize BIGINT;
    
    -- Verifica dimensioni file
    DECLARE @sql NVARCHAR(1000);
    SET @sql = 'SELECT @FileSize = size FROM sys.master_files WHERE name = ''tempdb''';
    
    PRINT '🔍 ANALISI PRE-IMPORTAZIONE:';
    PRINT 'File XML: ' + @XmlFilePath;
    PRINT 'Inizio: ' + CONVERT(VARCHAR(23), @StartTime, 121);
    
    -- Esegui importazione veloce
    EXEC [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML_VELOCE] @XmlFilePath;
    
    -- Analisi post-importazione
    DECLARE @EndTime DATETIME2 = SYSDATETIME();
    DECLARE @TotalTime DECIMAL(10,2) = DATEDIFF(MILLISECOND, @StartTime, @EndTime) / 1000.0;
    
    PRINT '📈 ANALISI POST-IMPORTAZIONE:';
    PRINT 'Tempo totale: ' + CAST(@TotalTime AS VARCHAR(10)) + ' secondi';
    
    -- Query di verifica automatica
    PRINT '🔍 VERIFICA AUTOMATICA:';
    
    -- Top 5 marche più popolari
    PRINT 'Top 5 marche più popolari:';
    SELECT TOP 5 
        MARCA, 
        COUNT(*) as Quantita,
        FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N1') + '%' as Percentuale
    FROM [dbo].[PrezziManualiDistribuzioneIT] 
    WHERE MARCA IS NOT NULL 
    GROUP BY MARCA 
    ORDER BY COUNT(*) DESC;
    
    -- Distribuzione stagioni
    PRINT 'Distribuzione per stagione:';
    SELECT 
        ART_STAGIONE, 
        COUNT(*) as Quantita,
        FORMAT(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 'N1') + '%' as Percentuale
    FROM [dbo].[PrezziManualiDistribuzioneIT] 
    WHERE ART_STAGIONE IS NOT NULL 
    GROUP BY ART_STAGIONE 
    ORDER BY COUNT(*) DESC;
    
END
GO

-- Procedura per pulizia e ottimizzazione
CREATE OR ALTER PROCEDURE [dbo].[SP_OttimizzaTabellaPrezzi]
AS
BEGIN
    PRINT '🧹 OTTIMIZZAZIONE TABELLA PREZZI...';
    
    -- Ricostruzione indici
    ALTER INDEX ALL ON [dbo].[PrezziManualiDistribuzioneIT] REBUILD 
    WITH (FILLFACTOR = 90, ONLINE = ON);
    
    -- Aggiornamento statistiche
    UPDATE STATISTICS [dbo].[PrezziManualiDistribuzioneIT] WITH FULLSCAN;
    
    -- Pulizia dati duplicati (se necessario)
    WITH CTE_Duplicati AS (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY Art_Id ORDER BY DataImportazione DESC) as rn
        FROM [dbo].[PrezziManualiDistribuzioneIT]
    )
    DELETE FROM CTE_Duplicati WHERE rn > 1;
    
    PRINT '✅ Ottimizzazione completata!';
END
GO

-- Script di esempio per l'uso
/*
-- Importazione veloce standard
EXEC [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML_VELOCE] 
    'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml'

-- Importazione con monitoraggio completo
EXEC [dbo].[SP_ImportaConMonitoraggio] 
    'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml'

-- Ottimizzazione post-importazione
EXEC [dbo].[SP_OttimizzaTabellaPrezzi]

-- Query di verifica veloce
SELECT 
    COUNT(*) as TotaleRecord,
    COUNT(DISTINCT MARCA) as MarcheDistinte,
    COUNT(CASE WHEN PM_Std > 0 THEN 1 END) as ConPM_Std,
    COUNT(CASE WHEN PM_T24 > 0 THEN 1 END) as ConPM_T24,
    COUNT(CASE WHEN PM_B2b > 0 THEN 1 END) as ConPM_B2b,
    COUNT(CASE WHEN PM_Collegati > 0 THEN 1 END) as ConPM_Collegati
FROM [dbo].[PrezziManualiDistribuzioneIT]
*/

PRINT '🎉 Script SQL VELOCE installato con successo!';
PRINT 'Usa: EXEC [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML_VELOCE] per importazioni rapide';
PRINT 'Usa: EXEC [dbo].[SP_ImportaConMonitoraggio] per monitoraggio completo'; 