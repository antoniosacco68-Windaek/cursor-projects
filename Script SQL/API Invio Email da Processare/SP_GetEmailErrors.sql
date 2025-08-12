USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailErrors]    Script Date: 09/05/2025 11:00:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:      Antonio Sacco
-- Create date: 09/05/2025
-- Description: Genera un report degli errori email e invia notifica
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_GetEmailErrors] 
    @StatisticID INT = NULL,
    @DataInizio DATETIME = NULL,
    @DataFine DATETIME = NULL,
    @InviaNotifica BIT = 1,
    @DestNotifica VARCHAR(255) = 'antonio.sacco@bolognagomme.com',
    @MittenteNotifica VARCHAR(255) = 'sql@bolognagomme.com',
    @NomeMittenteNotifica VARCHAR(255) = 'SQL Server Notifiche'
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Se non vengono specificati parametri, usa gli ultimi 7 giorni
    IF @DataInizio IS NULL
        SET @DataInizio = DATEADD(DAY, -0, GETDATE())
    
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
    
    -- Tabella temporanea per contenere le email con errori
    CREATE TABLE #ErroriEmail (
        ID uniqueidentifier,
        DataCreazione datetime,
        Mittente varchar(255),
        NomeMittente varchar(255),
        Destinatario varchar(255),
        Oggetto nvarchar(1000),
        ErroreDettaglio nvarchar(max),
        StatisticaID int,
        DataElaborazione datetime
    )
    
    -- Se è specificato un ID statistiche specifico, usa quello
    -- Altrimenti prendi tutte le statistiche nel periodo
    IF @StatisticID IS NOT NULL
    BEGIN
        -- Ottieni la lista di ID email con errori dalla riga di statistiche
        DECLARE @ErrorIDs nvarchar(MAX)
        DECLARE @StatRunDate datetime
        
        SELECT 
            @ErrorIDs = EmailConErrori,
            @StatRunDate = RunDate
        FROM 
            [dbo].[EmailStatistics] 
        WHERE ID = @StatisticID
        
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
            INSERT INTO #ErroriEmail (
                ID, DataCreazione, Mittente, NomeMittente, Destinatario, 
                Oggetto, ErroreDettaglio, StatisticaID, DataElaborazione
            )
            SELECT 
                e.ID,
                e.DataCreazione,
                e.Mittente,
                e.NomeMittente,
                e.Destinatario,
                e.Oggetto,
                e.Note AS ErroreDettaglio,
                @StatisticID,
                @StatRunDate
            FROM 
                [dbo].[EmailDataDaProcessare] e
            INNER JOIN 
                #TempErrorIDs t ON e.ID = t.EmailID
            WHERE
                e.Inviata = 0
                AND e.Note IS NOT NULL
                AND e.Note LIKE 'ERRORE%'
            
            DROP TABLE #TempErrorIDs
        END
    END
    ELSE
    BEGIN
        -- Ottieni le email con errori di tutte le statistiche nel periodo
        INSERT INTO #ErroriEmail (
            ID, DataCreazione, Mittente, NomeMittente, Destinatario, 
            Oggetto, ErroreDettaglio, StatisticaID, DataElaborazione
        )
        SELECT 
            e.ID,
            e.DataCreazione,
            e.Mittente,
            e.NomeMittente,
            e.Destinatario,
            e.Oggetto,
            e.Note AS ErroreDettaglio,
            s.ID AS StatisticaID,
            s.RunDate AS DataElaborazione
        FROM 
            [dbo].[EmailDataDaProcessare] e
        INNER JOIN
            [dbo].[EmailStatistics] s ON 
            s.RunDate BETWEEN @DataInizio AND @DataFine
            AND s.EmailConErrori LIKE '%' + CONVERT(nvarchar(50), e.ID) + '%'
        WHERE
            e.Inviata = 0
            AND e.Note IS NOT NULL
            AND e.Note LIKE 'ERRORE%'
    END
    
    -- Restituisci i dettagli degli errori
    SELECT * FROM #ErroriEmail ORDER BY DataElaborazione DESC, DataCreazione DESC
    
    -- Se ci sono errori e l'invio notifica è attivo, invia email
    DECLARE @NumErrori int
    SELECT @NumErrori = COUNT(*) FROM #ErroriEmail
    
    IF @NumErrori > 0 AND @InviaNotifica = 1 AND @DestNotifica IS NOT NULL
    BEGIN
        -- Prepara il corpo dell'email
        DECLARE @EmailBody nvarchar(max)
        DECLARE @EmailSubject nvarchar(255)
        
        SET @EmailSubject = 'NOTIFICA: ' + CAST(@NumErrori AS varchar(10)) + ' errori di invio email rilevati'
        
        -- Genera una tabella HTML con i dettagli degli errori
        SET @EmailBody = N'<html><body>
        <h2>Report Errori Invio Email</h2>
        <p>Sono stati rilevati ' + CAST(@NumErrori AS varchar(10)) + ' errori nell''invio delle email.</p>
        <table border="1" cellpadding="3" cellspacing="0" style="border-collapse: collapse; font-family: Arial; font-size: 12px;">
        <tr style="background-color: #CCCCCC; font-weight: bold;">
            <th>ID</th>
            <th>Data Creazione</th>
            <th>Mittente</th>
            <th>Destinatario</th>
            <th>Oggetto</th>
            <th>Errore</th>
        </tr>'
        
        -- Aggiungi righe per ogni email con errore
        DECLARE @EmailID uniqueidentifier
        DECLARE @EmailDataCreazione datetime
        DECLARE @EmailMittente varchar(255)
        DECLARE @EmailDestinatario varchar(255)
        DECLARE @EmailOggetto nvarchar(1000)
        DECLARE @EmailErrore nvarchar(max)
        
        DECLARE email_cursor CURSOR FOR 
        SELECT TOP 50 ID, DataCreazione, Mittente, Destinatario, Oggetto, ErroreDettaglio
        FROM #ErroriEmail
        ORDER BY DataElaborazione DESC, DataCreazione DESC
        
        OPEN email_cursor
        FETCH NEXT FROM email_cursor INTO @EmailID, @EmailDataCreazione, @EmailMittente, @EmailDestinatario, @EmailOggetto, @EmailErrore
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @EmailBody = @EmailBody + N'
            <tr>
                <td>' + CONVERT(nvarchar(50), @EmailID) + '</td>
                <td>' + CONVERT(nvarchar(50), @EmailDataCreazione, 120) + '</td>
                <td>' + ISNULL(@EmailMittente, 'N/A') + '</td>
                <td>' + ISNULL(@EmailDestinatario, 'N/A') + '</td>
                <td>' + ISNULL(@EmailOggetto, 'N/A') + '</td>
                <td>' + ISNULL(LEFT(@EmailErrore, 150), 'N/A') + '</td>
            </tr>'
            
            FETCH NEXT FROM email_cursor INTO @EmailID, @EmailDataCreazione, @EmailMittente, @EmailDestinatario, @EmailOggetto, @EmailErrore
        END
        
        CLOSE email_cursor
        DEALLOCATE email_cursor
        
        SET @EmailBody = @EmailBody + N'
        </table>
        <p>Questo è un messaggio automatico generato da SQL Server. Non rispondere a questa email.</p>
        </body></html>'
        
        -- Inserisci l'email di notifica nella coda di invio
        INSERT INTO [dbo].[EmailDataDaProcessare] (
            ID,
            DataCreazione,
            Mittente,
            Destinatario,
            Oggetto,
            Corpo,
            FormatoHTML,
            Inviata,
            NomeMittente
        ) VALUES (
            NEWID(),
            GETDATE(),
            @MittenteNotifica,
            @DestNotifica,
            @EmailSubject,
            @EmailBody,
            1,
            0,
            @NomeMittenteNotifica
        )
    END
    
    DROP TABLE #ErroriEmail
END
GO

-- Esempio di utilizzo:
-- EXEC [dbo].[SP_GetEmailErrors] -- Mostra statistiche degli ultimi 7 giorni e invia notifica
-- EXEC [dbo].[SP_GetEmailErrors] @StatisticID = 1 -- Mostra dettagli delle email con errori per statistiche ID=1
-- EXEC [dbo].[SP_GetEmailErrors] @InviaNotifica = 0 -- Mostra statistiche senza inviare notifica
-- EXEC [dbo].[SP_GetEmailErrors] @DestNotifica = 'altro.indirizzo@domain.com' -- Invia notifica a un indirizzo diverso 