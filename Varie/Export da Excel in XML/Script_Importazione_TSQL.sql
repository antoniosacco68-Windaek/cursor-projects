USE [PiattaformeWeb]
-- Script T-SQL per SQL Server 2017
-- Importazione XML PrezziManuali

-- Creazione della tabella PrezziManualiDistribuzioneIT
CREATE TABLE [dbo].[PrezziManualiDistribuzioneIT](
    Art_Id [int] NULL,
    [ART_CODICE] [varchar](50) NULL,
    [classificatore3] [int] NULL,
    [Descrizione] [varchar](255) NULL,
    [MARCA] [varchar](50) NULL,
    [ART_STAGIONE] [varchar](20) NULL,
    [PM_Std] [decimal](18,2) NULL,
    [PM_T24] [decimal](18,2) NULL,
    [PM_B2b] [decimal](18,2) NULL,
	[PM_Collegati] [decimal](18,2) NULL,
    [PM_Std_Data] [varchar](20) NULL,
    [PM_T24_Data] [varchar](20) NULL,
    [PM_B2b_Data] [varchar](20) NULL,
	[PM_Collegati_Data] [varchar](20) NULL,
    [DataImportazione] [datetime] DEFAULT GETDATE()
)
GO

-- Stored Procedure per l'importazione XML
CREATE OR ALTER PROCEDURE [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML]
    @XmlFilePath NVARCHAR(500) = 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @xml XML;
    DECLARE @sql NVARCHAR(MAX);
    
    -- Leggi il file XML
    SET @sql = 'SELECT @xml = BulkColumn FROM OPENROWSET(BULK ''' + @XmlFilePath + ''', SINGLE_BLOB) AS x';
    EXEC sp_executesql @sql, N'@xml XML OUTPUT', @xml OUTPUT;
    
    -- Svuota la tabella prima dell'importazione
    TRUNCATE TABLE [dbo].[PrezziManualiDistribuzioneIT];
    
    -- Importa i dati dall'XML
    INSERT INTO [dbo].[PrezziManualiDistribuzioneIT] (
        Art_Id, [ART_CODICE], [classificatore3], [Descrizione], [MARCA], 
        [ART_STAGIONE],[PM_Std], [PM_T24], [PM_B2b],PM_Collegati, [PM_Std_Data], 
        [PM_T24_Data], [PM_B2b_Data],[PM_Collegati_Data]
    )
    SELECT 
        CASE WHEN ISNUMERIC(T.c.value('Art_Id[1]', 'NVARCHAR(50)')) = 1 
             THEN TRY_CAST(T.c.value('Art_Id[1]', 'NVARCHAR(50)') AS INT)
             ELSE NULL END,
        T.c.value('ART_CODICE[1]', 'NVARCHAR(50)'),
        CASE WHEN ISNUMERIC(T.c.value('classificatore3[1]', 'NVARCHAR(50)')) = 1 
             THEN TRY_CAST(T.c.value('classificatore3[1]', 'NVARCHAR(50)') AS INT) 
             ELSE NULL END,
        T.c.value('Descrizione[1]', 'NVARCHAR(255)'),
        T.c.value('MARCA[1]', 'NVARCHAR(50)'),
        T.c.value('ART_STAGIONE[1]', 'NVARCHAR(20)'),
        TRY_CAST(T.c.value('PM_Std[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        TRY_CAST(T.c.value('PM_T24[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        TRY_CAST(T.c.value('PM_B2b[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
		TRY_CAST(T.c.value('PM_Collegati[1]', 'NVARCHAR(50)') AS DECIMAL(18,2)),
        T.c.value('PM_Std_Data[1]', 'NVARCHAR(20)'),
        T.c.value('PM_T24_Data[1]', 'NVARCHAR(20)'),
        T.c.value('PM_B2b_Data[1]', 'NVARCHAR(20)'),
        T.c.value('PM_Collegati_Data[1]', 'NVARCHAR(20)')
    FROM @xml.nodes('/PrezziManualiDistribuzioneIT/Articolo') T(c);
    
    -- Messaggio di conferma
    DECLARE @RecordCount INT;
    SELECT @RecordCount = COUNT(*) FROM [dbo].[PrezziManualiDistribuzioneIT];
    
    PRINT 'Importazione completata con successo!';
    PRINT 'Record importati: ' + CAST(@RecordCount AS VARCHAR(10));
    
END
GO

-- Script per eseguire l'importazione
    -- EXEC [dbo].[SP_ImportaPrezziManualiDistribuzioneIT_XML] 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneCSV\PrezziManualiDistribuzioneIT.xml'

-- Query di verifica
-- SELECT TOP 10 * FROM [dbo].[PrezziManualiDistribuzioneIT] ORDER BY Art_Id

-- Indice per migliorare le performance
CREATE INDEX IX_PrezziManuali_ART_CODICE ON [dbo].[PrezziManualiDistribuzioneIT] ([ART_CODICE])
CREATE INDEX IX_PrezziManuali_IdDiArtico ON [dbo].[PrezziManualiDistribuzioneIT] ([Art_Id])
CREATE INDEX IX_PrezziManuali_MARCA ON [dbo].[PrezziManualiDistribuzioneIT] ([MARCA])
GO

PRINT 'Setup completato! Tabella e stored procedure create con successo.' 