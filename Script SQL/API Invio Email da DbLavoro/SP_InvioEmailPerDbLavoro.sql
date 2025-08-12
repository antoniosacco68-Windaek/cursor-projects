USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_InvioEmailPerDbLavoro]    Script Date: 08/05/2025 08:50:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Antonio Sacco
-- Create date: 16/04/2025
-- Description:	Versione ottimizzata per l'invio di email tramite Gmail API
-- =============================================
ALTER PROCEDURE [dbo].[SP_InvioEmailPerDbLavoro]
	-- Parametri principali
	@Mittente VARCHAR(80),
	@StrTo VARCHAR(200),
	@Subject NVARCHAR(200),
	@Body NVARCHAR(MAX),
	@Attachment VARCHAR(400) = NULL,
	-- Parametri opzionali
	@CC VARCHAR(200) = NULL,
	@CCN VARCHAR(200) = NULL,
	@FormatoHTML BIT = 1,  -- Sempre 1, formato HTML sempre attivo
	@Debug BIT = 0         -- Per logging esteso quando necessario
AS
BEGIN
	-- Evita result set non necessari
	SET NOCOUNT ON;
    
    -- Variabili per gestione errori e risultati
    DECLARE @ErrorMessage NVARCHAR(4000);
    DECLARE @ErrorNumber INT;
    DECLARE @EmailUniqueID UNIQUEIDENTIFIER;
    DECLARE @ReturnValue INT = 0;
    DECLARE @OutputMsg NVARCHAR(MAX) = '';
    DECLARE @StartTime DATETIME = GETDATE();
    DECLARE @ExecutionTime INT;
    
    -- Crea una tabella temporanea per memorizzare l'output con migliore struttura
    CREATE TABLE #CommandOutput (
        ID INT IDENTITY(1,1),
        Output NVARCHAR(4000)
    );
    
    -- Logging iniziale
    IF @Debug = 1
    BEGIN
        INSERT INTO [dbo].[EmailLog] (LogLevel, Message, Details)
        VALUES ('INFO', 'Inizio elaborazione email', 'Mittente: ' + @Mittente + ', Destinatario: ' + @StrTo);
    END
    
    BEGIN TRY
        -- ===== Determina il NomeMittente in base al mittente ===== --
        DECLARE @NomeMittente varchar(80) =
            CASE @Mittente
                WHEN 'bg1team@bolognagomme.com' THEN 'Bologna Gomme 1 Team'
                WHEN 'bg2team@bolognagomme.com' THEN 'Bologna Gomme 2 Team'
                WHEN 'bg3team@bolognagomme.com' THEN 'Bologna Gomme 3 Team'
                WHEN 'bg4team@bolognagomme.com' THEN 'Bologna Gomme 4 Team'
                WHEN 'bg5team@bolognagomme.com' THEN 'Bologna Gomme 5 Team'
                WHEN 'bg6team@bolognagomme.com' THEN 'Bologna Gomme 6 Team'
                WHEN 'bg7team@bolognagomme.com' THEN 'Bologna Gomme 7 Team'
                WHEN 'donato.giove@bolognagomme.com' THEN 'Bologna Gomme Truck Team'
            ELSE 'Bologna Gomme Team'
            END;

        -- Definisci percorso script PowerShell
        DECLARE @ScriptPath VARCHAR(255) = 'C:\Antonio\ScriptPowershell\InviaEmailSqlDbLavoro.ps1';
        
        -- Gestione corpo vuoto
        IF @Body IS NULL OR @Body = ''
        BEGIN
            SET @Body = '<html><body>Nessun contenuto fornito.</body></html>';
        END
        ELSE IF @FormatoHTML = 1 AND (LEFT(@Body, 6) <> '<html>' AND LEFT(@Body, 14) <> '<!DOCTYPE html')
        BEGIN
            -- Assicurati che il corpo abbia la struttura HTML completa se FormatoHTML=1
            SET @Body = '<html><body>' + @Body + '</body></html>';
        END
        
        -- Genera un ID univoco per questa email con migliore casualità
        SET @EmailUniqueID = NEWID();
        
        -- Timestamp più preciso per tracking delle performance
        DECLARE @InsertTime DATETIME = GETDATE();
        
        -- Inserimento efficiente nella tabella EmailData con controllo integrità
        BEGIN TRANSACTION;
        
        INSERT INTO [dbo].[EmailData]
               ([ID], [DataCreazione], [Mittente], [NomeMittente], [Destinatario], [CC], [CCN], 
                [Oggetto], [Corpo], [FormatoHTML], [Allegato], [Inviata])
        VALUES
               (@EmailUniqueID, @InsertTime, @Mittente, @NomeMittente, @StrTo, @CC, @CCN, 
                @Subject, @Body, @FormatoHTML, @Attachment, 0);
                
        -- Logging post-inserimento
        IF @Debug = 1
        BEGIN
            SET @ExecutionTime = DATEDIFF(ms, @StartTime, GETDATE());
            INSERT INTO [dbo].[EmailLog] (LogLevel, Message, Details)
            VALUES ('INFO', 'Email inserita nel DB', 'ID: ' + CONVERT(VARCHAR(50), @EmailUniqueID) + ', Tempo: ' + CONVERT(VARCHAR(10), @ExecutionTime) + 'ms');
        END
        
        COMMIT TRANSACTION;
        
        -- Comando PowerShell ottimizzato
        DECLARE @Cmd VARCHAR(1000) = 'powershell.exe -ExecutionPolicy Bypass -NoProfile -File "' + @ScriptPath + 
                                      '" -EmailID "' + CONVERT(VARCHAR(50), @EmailUniqueID) + '"';
        
        -- Esegui PowerShell con timeout maggiore e gestione output migliorata
        DELETE FROM #CommandOutput;
        INSERT INTO #CommandOutput
        EXEC xp_cmdshell @Cmd;
        
        -- Raccogli tutto l'output in una variabile con gestione più efficiente
        SELECT @OutputMsg = STRING_AGG(ISNULL(Output, ''), CHAR(13) + CHAR(10))
        FROM #CommandOutput
        WHERE Output IS NOT NULL;
        
        -- Estrai informazioni dall'output formato TIPO|ID|MESSAGGIO con gestione più robusta
        DECLARE @StatusType VARCHAR(50) = '';
        DECLARE @EmailID VARCHAR(100) = '';
        DECLARE @StatusMessage NVARCHAR(MAX) = '';
        
        -- Ottieni la prima riga di output che contiene le informazioni con controllo più robusto
        SELECT TOP 1 @StatusType = CASE 
                                     WHEN CHARINDEX('|', Output) > 0 
                                     THEN LEFT(Output, CHARINDEX('|', Output) - 1) 
                                     ELSE '' 
                                   END,
                     @StatusMessage = CASE 
                                        WHEN CHARINDEX('|', Output) > 0 AND 
                                             CHARINDEX('|', Output, CHARINDEX('|', Output) + 1) > 0
                                        THEN SUBSTRING(Output, 
                                                      CHARINDEX('|', Output, CHARINDEX('|', Output) + 1) + 1, 
                                                      LEN(Output))
                                        ELSE ''
                                      END
        FROM #CommandOutput
        WHERE Output IS NOT NULL AND CHARINDEX('|', Output) > 0;
        
        -- Se abbiamo trovato l'ID dell'email, estrai la parte centrale
        IF @StatusType <> '' AND CHARINDEX('|', @OutputMsg) > 0
        BEGIN
            DECLARE @RestAfterFirst NVARCHAR(4000) = SUBSTRING(@OutputMsg, 
                                                              CHARINDEX('|', @OutputMsg) + 1, 
                                                              LEN(@OutputMsg));
                                                              
            IF CHARINDEX('|', @RestAfterFirst) > 0
            BEGIN
                SET @EmailID = LEFT(@RestAfterFirst, CHARINDEX('|', @RestAfterFirst) - 1);
            END
        END
        
        -- Calcola il tempo di esecuzione totale per analisi performance
        SET @ExecutionTime = DATEDIFF(ms, @StartTime, GETDATE());
        
        -- Verifica se l'email è stata inviata con successo con migliore validazione
        IF @StatusType = 'SUCCESSO' AND @EmailID <> ''
        BEGIN
            -- Logging del successo con metriche di performance
            IF @Debug = 1
            BEGIN
                INSERT INTO [dbo].[EmailLog] (LogLevel, Message, Details)
                VALUES ('INFO', 'Email inviata con successo', 
                       'ID: ' + @EmailID + ', Tempo totale: ' + CONVERT(VARCHAR(10), @ExecutionTime) + 'ms');
            END
            
            -- Restituisci il risultato con metriche
            SELECT 1 AS Successo, 
                  @StatusMessage AS Messaggio,
                  @EmailID AS EmailID,
                  @ExecutionTime AS TempoEsecuzioneMs;
            
            RETURN 0;
        END
        ELSE
        BEGIN
            -- Aggiorna il database con lo stato di errore
            UPDATE [dbo].[EmailData]
            SET [Note] = ISNULL(@StatusMessage, 'Errore sconosciuto'), 
                [UltimoAggiornamento] = GETDATE()
            WHERE [ID] = @EmailUniqueID;
            
            -- Logging dell'errore
            IF @Debug = 1
            BEGIN
                INSERT INTO [dbo].[EmailLog] (LogLevel, Message, Details)
                VALUES ('ERROR', 'Errore nell''invio email', 
                       'ID: ' + CONVERT(VARCHAR(50), @EmailUniqueID) + ', Errore: ' + ISNULL(@StatusMessage, 'Sconosciuto'));
            END
            
            SELECT 0 AS Successo, 
                  ISNULL(@StatusMessage, 'Errore sconosciuto') AS Messaggio,
                  @OutputMsg AS ErrorDetails,
                  @ExecutionTime AS TempoEsecuzioneMs;
            
            RETURN 1;
        END
    END TRY
    BEGIN CATCH
        -- Gestione completa degli errori
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Rollback se c'è una transazione attiva
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        -- Aggiorna il database con lo stato di errore
        IF @EmailUniqueID IS NOT NULL
        BEGIN
            UPDATE [dbo].[EmailData]
            SET [Note] = 'Errore SQL: ' + @ErrorMessage,
                [UltimoAggiornamento] = GETDATE()
            WHERE [ID] = @EmailUniqueID;
        END
        
        -- Logging dell'errore
        INSERT INTO [dbo].[EmailLog] (LogLevel, Message, Details)
        VALUES ('ERROR', 'Eccezione SQL durante invio email', 
               'Errore: ' + @ErrorMessage + ', Numero: ' + CONVERT(VARCHAR(10), @ErrorNumber));
        
        -- Restituisci informazioni dettagliate sull'errore
        SELECT 0 AS Successo,
               @ErrorMessage AS Messaggio,
               ERROR_NUMBER() AS ErrorNumber,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_STATE() AS ErrorState,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_LINE() AS ErrorLine,
               DATEDIFF(ms, @StartTime, GETDATE()) AS TempoEsecuzioneMs;
        
        -- Pulisci
        IF OBJECT_ID('tempdb..#CommandOutput') IS NOT NULL
            DROP TABLE #CommandOutput;
        
        RETURN -1;
    END CATCH
    
    -- Assicurati che la tabella temporanea venga eliminata
    IF OBJECT_ID('tempdb..#CommandOutput') IS NOT NULL
        DROP TABLE #CommandOutput;
END 
