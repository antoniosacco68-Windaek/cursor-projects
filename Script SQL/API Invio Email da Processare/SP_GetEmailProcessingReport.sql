USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailProcessingReport]    Script Date: 09/05/2025 11:00:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antonio Sacco
-- Create date: 09/05/2025
-- Description: Genera un report dettagliato degli invii email
-- =============================================
CREATE PROCEDURE [dbo].[SP_GetEmailProcessingReport] 
    @BatchID UNIQUEIDENTIFIER = NULL,
    @DataInizio DATETIME = NULL,
    @DataFine DATETIME = NULL,
    @SoloErrori BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Se non vengono specificati parametri, usa gli ultimi 7 giorni
    IF @DataInizio IS NULL
        SET @DataInizio = DATEADD(DAY, -7, GETDATE())
    
    IF @DataFine IS NULL
        SET @DataFine = GETDATE()
    
    -- Report di riepilogo per batch
    SELECT 
        s.BatchID,
        s.RunDate AS DataElaborazione,
        s.EmailsProcessed AS EmailTotali,
        s.SuccessCount AS EmailInviate,
        s.FailureCount AS EmailFallite,
        s.TotalDurationMs AS TempoElaborazioneMs,
        s.Notes AS NoteAggiuntive
    FROM 
        [dbo].[EmailStatistics] s
    WHERE 
        (@BatchID IS NULL OR s.BatchID = @BatchID)
        AND s.RunDate BETWEEN @DataInizio AND @DataFine
    ORDER BY 
        s.RunDate DESC
    
    -- Report dettagliato per singola email
    SELECT 
        l.ID,
        l.EmailID,
        l.BatchID,
        l.ProcessingTime AS DataElaborazione,
        l.Mittente,
        l.Destinatario,
        l.Oggetto,
        l.Stato,
        l.DettaglioStato,
        l.GmailMessageId,
        l.TempoElaborazioneMs,
        e.DataInvio
    FROM 
        [dbo].[EmailProcessingLog] l
    LEFT JOIN 
        [dbo].[EmailDataDaProcessare] e ON l.EmailID = e.ID
    WHERE 
        (@BatchID IS NULL OR l.BatchID = @BatchID)
        AND l.ProcessingTime BETWEEN @DataInizio AND @DataFine
        AND (@SoloErrori = 0 OR l.Stato = 'ERRORE')
    ORDER BY 
        l.ProcessingTime DESC, l.Stato
    
    -- Report completo delle ultime email con errori
    IF @SoloErrori = 1
    BEGIN
        SELECT TOP 50
            e.ID,
            e.DataCreazione,
            e.Mittente,
            e.NomeMittente,
            e.Destinatario,
            e.Oggetto,
            e.Note AS ErroreDettaglio,
            l.ProcessingTime AS UltimoTentativo,
            l.BatchID
        FROM 
            [dbo].[EmailDataDaProcessare] e
        LEFT JOIN 
            [dbo].[EmailProcessingLog] l ON e.ID = l.EmailID
        WHERE 
            e.Inviata = 0
            AND e.Note IS NOT NULL
            AND e.Note LIKE 'ERRORE%'
            AND (@BatchID IS NULL OR l.BatchID = @BatchID)
        ORDER BY 
            e.DataCreazione DESC
    END
END
GO

-- Esempio di utilizzo:
-- EXEC [dbo].[SP_GetEmailProcessingReport] -- Tutti gli invii degli ultimi 7 giorni
-- EXEC [dbo].[SP_GetEmailProcessingReport] @SoloErrori = 1 -- Solo errori degli ultimi 7 giorni
-- EXEC [dbo].[SP_GetEmailProcessingReport] @BatchID = '3F2504E0-4F89-41D3-9A0C-0305E82C3301' -- Specifico batch
-- EXEC [dbo].[SP_GetEmailProcessingReport] @DataInizio = '2025-05-01', @DataFine = '2025-05-10' -- Intervallo di date 