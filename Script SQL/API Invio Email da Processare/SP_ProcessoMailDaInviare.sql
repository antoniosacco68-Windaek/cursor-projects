USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_ProcessoMailDaInviare]    Script Date: 08/05/2025 17:14:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:	
-- Create date: 05/04/2013
-- Description:	Stored procedure ottimizzata che legge la coda delle mail da inviare per i relativi B2b
-- =============================================
ALTER PROCEDURE [dbo].[SP_ProcessoMailDaInviare] 
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validazione indirizzi email prima dell'elaborazione
    UPDATE [dbo].[EmailDataDaProcessare]
    SET [Note] = 'ERRORE: Indirizzo email non valido'
    WHERE [Note] IS NULL AND [Inviata] = 0 
    AND (
        [Destinatario] IS NULL OR 
        [Destinatario] = '' OR
        [Destinatario] NOT LIKE '%_@__%.__%'
    )
    
    -- Variabili per il batch processing
    DECLARE @BatchSize INT = 10 -- Numero di email da elaborare in parallelo
    DECLARE @ProcessedCount INT = 0
    DECLARE @SuccessCount INT = 0
    DECLARE @FailCount INT = 0
    DECLARE @TotalToProcess INT
    DECLARE @StartTime DATETIME = GETDATE()
    DECLARE @BatchID UNIQUEIDENTIFIER = NEWID() -- ID univoco per questo batch
    
    -- Conteggio delle email da processare
    SELECT @TotalToProcess = COUNT(*) 
    FROM [dbo].[EmailDataDaProcessare] WITH(NOLOCK)
    WHERE [Inviata] = 0 AND ([Note] IS NULL OR [Note] = '')
    
    -- Se non ci sono email da inviare, usciamo
    IF @TotalToProcess = 0 GOTO Uscita
    
    -- Tabella temporanea per memorizzare i batch di email da processare
    CREATE TABLE #EmailBatch (
        RowID INT IDENTITY(1,1) PRIMARY KEY,
        EmailID varchar(100),
        Mittente varchar(50),
        Destinatario nvarchar(1000),
        Oggetto nvarchar(1000),
        Corpo nvarchar(max),
        Allegato nvarchar(400),
        NomeMittente varchar(80),
        ProcessingStatus TINYINT DEFAULT 0 -- 0=Da elaborare, 1=In elaborazione, 2=Completata
    )
    
    -- Tabella temporanea per gli output dei comandi
    CREATE TABLE #CommandOutput (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        EmailID varchar(100),
        Output NVARCHAR(MAX)
    )
    
    -- Seleziona le email da processare in batch
    INSERT INTO #EmailBatch (EmailID, Mittente, Destinatario, Oggetto, Corpo, Allegato)
    SELECT TOP (@BatchSize) 
        [id],
        e.Mittente,
        ISNULL((REPLACE(CAST(e.Destinatario AS nvarchar(1000)),',',';')),''),
        ISNULL(e.Oggetto,''),
        CASE 
            WHEN PATINDEX('%HTML%', UPPER(ISNULL(CAST(e.Corpo AS nvarchar(4000)),'') )) = 0 THEN 
                ISNULL((REPLACE(CAST(e.Corpo AS nvarchar(MAX)),'|',CHAR(13))),'')
            ELSE
                ISNULL((REPLACE(CAST(e.Corpo AS nvarchar(MAX)),'|','<BR>')),'')
        END,
        e.Allegato
    FROM [dbo].[EmailDataDaProcessare] e WITH(NOLOCK)
    WHERE e.Inviata = 0 AND (e.[Note] IS NULL OR e.[Note] = '')
    ORDER BY e.id
    
    -- Imposta il NomeMittente per ogni email
    UPDATE b
    SET NomeMittente = 
        CASE b.Mittente
            WHEN 'bg1team@bolognagomme.com' THEN 'Bologna Gomme 1 Team'
            WHEN 'bg2team@bolognagomme.com' THEN 'Bologna Gomme 2 Team'
            WHEN 'bg3team@bolognagomme.com' THEN 'Bologna Gomme 3 Team'
            WHEN 'bg4team@bolognagomme.com' THEN 'Bologna Gomme 4 Team'
            WHEN 'bg5team@bolognagomme.com' THEN 'Bologna Gomme 5 Team'
            WHEN 'bg6team@bolognagomme.com' THEN 'Bologna Gomme 6 Team'
            WHEN 'bg7team@bolognagomme.com' THEN 'Bologna Gomme 7 Team'
            WHEN 'donato.giove@bolognagomme.com' THEN 'Bologna Gomme Truck Team'
            ELSE 'Bologna Gomme Team'
        END
    FROM #EmailBatch b
    
    -- Percorso dello script PowerShell ottimizzato per batch
    DECLARE @ScriptPath VARCHAR(255) = 'C:\Antonio\ScriptPowershell\InviaEmailBatch.ps1'
    DECLARE @ScriptPathSingle VARCHAR(255) = 'C:\Antonio\ScriptPowershell\InviaEmailSqlDaProcessare.ps1'
    
    -- Verifica se esiste lo script batch ottimizzato
    DECLARE @UseBatchScript BIT = 0
    
    IF EXISTS (SELECT 1 FROM sys.objects WHERE type = 'X' AND name = 'xp_fileexist')
    BEGIN
        DECLARE @FileExists INT
        EXEC master.dbo.xp_fileexist @ScriptPath, @FileExists OUTPUT
        
        IF @FileExists = 1
            SET @UseBatchScript = 1
    END
    
    IF @UseBatchScript = 1
    BEGIN
        -- Crea un file temporaneo con gli ID delle email da processare
        DECLARE @TempFilePath VARCHAR(255) = 'C:\Temp\email_batch_' + CONVERT(VARCHAR(20), GETDATE(), 112) + '_' + 
                                           REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), ':', '') + '.csv'
        
        DECLARE @SqlCreateCsv VARCHAR(1000) = 'bcp "SELECT EmailID FROM #EmailBatch" queryout "' + @TempFilePath + 
                                          '" -c -T -S ' + @@SERVERNAME
        
        -- Esporta gli ID in un file CSV
        EXEC master.dbo.xp_cmdshell @SqlCreateCsv, NO_OUTPUT
        
        -- Esegui il batch script che elabora tutte le email nel file
        DECLARE @BatchCmd VARCHAR(1000) = 'powershell.exe -ExecutionPolicy Bypass -File "' + @ScriptPath + 
                                       '" -BatchFile "' + @TempFilePath + '"'
        
        -- Esegui PowerShell e cattura l'output
        INSERT INTO #CommandOutput (Output)
        EXEC xp_cmdshell @BatchCmd
    END
    ELSE
    BEGIN
        -- Usa l'approccio originale ma ottimizzato per più email
        DECLARE @CurrentEmailID VARCHAR(100)
        DECLARE @Cmd VARCHAR(1000)
        
        -- Crea un cursore ottimizzato per il batch
        DECLARE EmailCursor CURSOR FAST_FORWARD FOR 
        SELECT EmailID FROM #EmailBatch
        
        OPEN EmailCursor
        FETCH NEXT FROM EmailCursor INTO @CurrentEmailID
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @ScriptPathSingle + 
                     '" -EmailID "' + @CurrentEmailID + '"'
            
            -- Esegui PowerShell e cattura l'output
            DELETE FROM #CommandOutput
            INSERT INTO #CommandOutput (Output)
            EXEC xp_cmdshell @Cmd
            
            -- Associa l'EmailID all'output
            UPDATE #CommandOutput
            SET EmailID = @CurrentEmailID
            WHERE EmailID IS NULL
            
            FETCH NEXT FROM EmailCursor INTO @CurrentEmailID
        END
        
        CLOSE EmailCursor
        DEALLOCATE EmailCursor
    END
    
    -- Soluzione definitiva più robusta - conta sempre direttamente nel database
    
    -- Verifica quante email sono state effettivamente elaborate durante questa esecuzione
    -- Conta quelle inviate con successo
    SELECT @SuccessCount = COUNT(*) 
    FROM [dbo].[EmailDataDaProcessare] 
    WHERE DataInvio >= @StartTime 
      AND Inviata = 1
      AND EmailID IS NOT NULL
    
    -- Conta le email che hanno avuto errori durante questa esecuzione
    SELECT @FailCount = COUNT(*) 
    FROM [dbo].[EmailDataDaProcessare]
    WHERE [ID] IN (SELECT EmailID FROM #EmailBatch)
      AND [Note] IS NOT NULL 
      AND [Note] LIKE 'ERRORE%'
      AND DataInvio IS NULL
    
    -- Calcola il totale
    SET @ProcessedCount = @SuccessCount + @FailCount
    
    -- Elimina il file temporaneo
    IF @UseBatchScript = 1 AND EXISTS (SELECT 1 FROM sys.objects WHERE type = 'X' AND name = 'xp_fileexist')
    BEGIN
        DECLARE @DeleteFileCmd VARCHAR(255) = 'del "' + @TempFilePath + '"'
        EXEC master.dbo.xp_cmdshell @DeleteFileCmd, NO_OUTPUT
    END
    
    -- Registra le statistiche (una sola volta)
    INSERT INTO [dbo].[EmailStatistics] (RunDate, EmailsProcessed, SuccessCount, FailureCount, TotalDurationMs, Notes, BatchID)
    VALUES (
        @StartTime, 
        @ProcessedCount, 
        @SuccessCount, 
        @FailCount, 
        DATEDIFF(MILLISECOND, @StartTime, GETDATE()),
        'BatchSize: ' + CAST(@BatchSize AS VARCHAR(10)) + 
        ', EmailInBatch: ' + CAST((SELECT COUNT(*) FROM #EmailBatch) AS VARCHAR(10)) +
        ', UseBatchScript: ' + CAST(@UseBatchScript AS VARCHAR(10)),
        @BatchID
    )
    
    -- Raccogli gli ID delle email con errori
    DECLARE @EmailConErrori nvarchar(MAX) = ''
    
    SELECT @EmailConErrori = COALESCE(@EmailConErrori + ',', '') + CONVERT(nvarchar(50), e.ID)
    FROM [dbo].[EmailDataDaProcessare] e
    WHERE [ID] IN (SELECT EmailID FROM #EmailBatch)
      AND [Note] IS NOT NULL 
      AND [Note] LIKE 'ERRORE%'
    
    -- Aggiorna la statistica con gli ID delle email con errori
    IF LEN(@EmailConErrori) > 0
    BEGIN
        UPDATE [dbo].[EmailStatistics]
        SET EmailConErrori = @EmailConErrori
        WHERE RunDate = @StartTime
          AND BatchID = @BatchID
    END
    
    -- Pulisci
    DROP TABLE #EmailBatch
    DROP TABLE #CommandOutput

Uscita:
    -- Restituisci informazioni di riepilogo
    IF @ProcessedCount > 0
    BEGIN
        SELECT 
            @ProcessedCount AS EmailElaborate,
            @SuccessCount AS EmailInviate,
            @FailCount AS EmailFallite,
            DATEDIFF(MILLISECOND, @StartTime, GETDATE()) AS TempoEsecuzioneMs
    END
END
