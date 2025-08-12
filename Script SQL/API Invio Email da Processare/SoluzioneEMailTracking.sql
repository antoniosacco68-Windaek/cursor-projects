USE [I24DB]
GO

-- =============================================
-- SOLUZIONE SEMPLIFICATA PER TRACCIAMENTO EMAIL
-- =============================================

-- 1. Modifica alla tabella EmailStatistics per aggiungere il riferimento alle email fallite
IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID(N'[dbo].[EmailStatistics]') AND name = 'EmailConErrori')
BEGIN
    ALTER TABLE [dbo].[EmailStatistics]
    ADD [EmailConErrori] [nvarchar](MAX) NULL
END
GO

-- 2. Stored procedure semplificata per ottenere i dettagli delle email fallite
CREATE OR ALTER PROCEDURE [dbo].[SP_GetEmailErrors]
    @StatisticID INT = NULL,
    @DataInizio DATETIME = NULL,
    @DataFine DATETIME = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Se non vengono specificati parametri, usa gli ultimi 7 giorni
    IF @DataInizio IS NULL
        SET @DataInizio = DATEADD(DAY, -7, GETDATE())
    
    IF @DataFine IS NULL
        SET @DataFine = GETDATE()
    
    -- Ottieni le statistiche degli ultimi invii
    SELECT 
        s.ID,
        s.RunDate AS DataElaborazione,
        s.EmailsProcessed AS EmailTotali,
        s.SuccessCount AS EmailInviate,
        s.FailureCount AS EmailFallite,
        s.TotalDurationMs AS TempoElaborazioneMs,
        s.EmailConErrori
    FROM 
        [dbo].[EmailStatistics] s
    WHERE 
        (@StatisticID IS NULL OR s.ID = @StatisticID)
        AND s.RunDate BETWEEN @DataInizio AND @DataFine
    ORDER BY 
        s.RunDate DESC;
    
    -- Se è specificato un ID statistiche specifico, mostra i dettagli degli errori
    IF @StatisticID IS NOT NULL
    BEGIN
        -- Ottieni la lista di ID email con errori dalla riga di statistiche
        DECLARE @ErrorIDs nvarchar(MAX)
        SELECT @ErrorIDs = EmailConErrori FROM [dbo].[EmailStatistics] WHERE ID = @StatisticID
        
        IF @ErrorIDs IS NOT NULL
        BEGIN
            -- Crea una tabella temporanea per ospitare gli ID
            CREATE TABLE #TempErrorIDs (EmailID uniqueidentifier)
            
            -- Popola la tabella temporanea dagli ID separati da virgola
            DECLARE @ID uniqueidentifier
            DECLARE @Pos int
            DECLARE @Delim nvarchar(1) = ','
            
            WHILE CHARINDEX(@Delim, @ErrorIDs) > 0
            BEGIN
                SET @Pos = CHARINDEX(@Delim, @ErrorIDs)
                SET @ID = CONVERT(uniqueidentifier, LTRIM(RTRIM(SUBSTRING(@ErrorIDs, 1, @Pos-1))))
                
                INSERT INTO #TempErrorIDs (EmailID) VALUES (@ID)
                SET @ErrorIDs = SUBSTRING(@ErrorIDs, @Pos+1, LEN(@ErrorIDs)-@Pos)
            END
            
            IF LEN(@ErrorIDs) > 0
            BEGIN
                SET @ID = CONVERT(uniqueidentifier, LTRIM(RTRIM(@ErrorIDs)))
                INSERT INTO #TempErrorIDs (EmailID) VALUES (@ID)
            END
            
            -- Ottieni i dettagli delle email con errori
            SELECT 
                e.ID,
                e.DataCreazione,
                e.Mittente,
                e.NomeMittente,
                e.Destinatario,
                e.Oggetto,
                e.Note AS ErroreDettaglio
            FROM 
                [dbo].[EmailDataDaProcessare] e
            INNER JOIN 
                #TempErrorIDs t ON e.ID = t.EmailID
            ORDER BY 
                e.DataCreazione DESC
            
            DROP TABLE #TempErrorIDs
        END
    END
END
GO

-- 3. Modifica alla SP_ProcessoMailDaInviare per salvare gli ID delle email con errori
-- Aggiungi questo codice alla fine della stored procedure, prima del DROP TABLE
/*
    -- Raccogli gli ID delle email con errori
    DECLARE @EmailConErrori nvarchar(MAX) = ''
    
    SELECT @EmailConErrori = COALESCE(@EmailConErrori + ',', '') + CONVERT(nvarchar(50), e.ID)
    FROM [dbo].[EmailDataDaProcessare] e
    WHERE [ID] IN (SELECT EmailID FROM #EmailBatch)
      AND [Note] IS NOT NULL 
      AND [Note] LIKE 'ERRORE%'
    
    -- Aggiorna la statistica con gli ID delle email con errori
    UPDATE [dbo].[EmailStatistics]
    SET EmailConErrori = @EmailConErrori
    WHERE RunDate = @StartTime
      AND BatchID = @BatchID
*/
GO

-- Esempio di utilizzo:
-- EXEC [dbo].[SP_GetEmailErrors] -- Mostra statistiche degli ultimi 7 giorni
-- EXEC [dbo].[SP_GetEmailErrors] @StatisticID = 1 -- Mostra dettagli delle email con errori per statistiche ID=1
-- EXEC [dbo].[SP_GetEmailErrors] @DataInizio = '2025-05-01', @DataFine = '2025-05-10' -- Intervallo di date 