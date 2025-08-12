USE [I24DB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antonio Sacco
-- Create date: 16/04/2025
-- Description:	Versione semplificata per l'invio di email tramite Gmail API
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_InvioEmailPerDbLavoroPowershell]
	-- Add the parameters for the stored procedure here
	@Mittente VARCHAR(80),
	@StrTo VARCHAR(200),
	@Subject VARCHAR(200),
	@Body VARCHAR(MAX),
	@Attachment VARCHAR(400) = NULL,
	@CC VARCHAR(200) = NULL,
	@CCN VARCHAR(200) = NULL,
	@FormatoHTML BIT = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    -- Crea una tabella temporanea per memorizzare l'output
    CREATE TABLE #CommandOutput (
        Output VARCHAR(8000)
    )
    
    -- Crea file temporaneo per il corpo dell'email
    DECLARE @BodyFilePath VARCHAR(255) = 'C:\Temp\emailbody.txt'
    DECLARE @CreateBodyFileCmd VARCHAR(8000)
    
    -- Salva il corpo dell'email in un file
    SET @CreateBodyFileCmd = 'echo ' + REPLACE(@Body, '"', '\"') + ' > ' + @BodyFilePath
    EXEC xp_cmdshell @CreateBodyFileCmd, no_output
    
    -- Utilizziamo la creazione di un file batch temporaneo per evitare problemi di escape
    DECLARE @BatchFile VARCHAR(255) = 'C:\Temp\emailsender.bat'
    DECLARE @PSFile VARCHAR(255) = 'C:\Temp\emailsender.ps1'
    
    -- Creiamo un file PowerShell
    DECLARE @CreatePSCmd VARCHAR(8000)
    SET @CreatePSCmd = 'echo try { > ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Aggiungiamo i comandi PowerShell uno per uno
    SET @CreatePSCmd = 'echo Add-Type -Path "C:\Antonio\GoogleApi\lib\Newtonsoft.Json.dll" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Core.dll" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.dll" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Auth.dll" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo Add-Type -Path "C:\Antonio\GoogleApi\lib\Google.Apis.Gmail.v1.dll" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath) >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send") >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $delegated = $scoped.CreateWithUser("' + @Mittente + '") >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $initializer.HttpClientInitializer = $delegated >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $initializer.ApplicationName = "BG MailSender" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Intestazione email
    SET @CreatePSCmd = 'echo $headers = @() >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $headers += "From: ' + @Mittente + '" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $headers += "To: ' + @StrTo + '" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- CC e CCN
    IF @CC IS NOT NULL AND @CC <> ''
    BEGIN
        SET @CreatePSCmd = 'echo $headers += "Cc: ' + @CC + '" >> ' + @PSFile
        EXEC xp_cmdshell @CreatePSCmd, no_output
    END
    
    IF @CCN IS NOT NULL AND @CCN <> ''
    BEGIN
        SET @CreatePSCmd = 'echo $headers += "Bcc: ' + @CCN + '" >> ' + @PSFile
        EXEC xp_cmdshell @CreatePSCmd, no_output
    END
    
    -- Oggetto
    SET @CreatePSCmd = 'echo $headers += "Subject: ' + REPLACE(@Subject, '"', '\"') + '" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Tipo MIME
    IF @FormatoHTML = 1
    BEGIN
        SET @CreatePSCmd = 'echo $headers += "Content-Type: text/html; charset=UTF-8" >> ' + @PSFile
        EXEC xp_cmdshell @CreatePSCmd, no_output
    END
    ELSE
    BEGIN
        SET @CreatePSCmd = 'echo $headers += "Content-Type: text/plain; charset=UTF-8" >> ' + @PSFile
        EXEC xp_cmdshell @CreatePSCmd, no_output
    END
    
    -- Componi email
    SET @CreatePSCmd = 'echo $emailBody = $headers -join "`r`n" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $emailBody += "`r`n`r`n" >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Leggi il corpo da file
    SET @CreatePSCmd = 'echo $bodyContent = Get-Content -Path "' + @BodyFilePath + '" -Raw >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $emailBody += $bodyContent >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Resto del codice
    SET @CreatePSCmd = 'echo $rawMessage = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($emailBody)) >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $rawMessage = $rawMessage.Replace("+", "-").Replace("/", "_").Replace("=", "") >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $msg = New-Object Google.Apis.Gmail.v1.Data.Message >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $msg.Raw = $rawMessage >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo $response = $service.Users.Messages.Send($msg, "me").Execute() >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo Write-Output ("SUCCESS:" + $response.Id) >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Fine try e catch
    SET @CreatePSCmd = 'echo } catch { >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo    Write-Error ("ERROR:" + $_.Exception.Message) >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo    exit 1 >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    SET @CreatePSCmd = 'echo } >> ' + @PSFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    -- Creiamo il file batch che eseguirà lo script PowerShell
    SET @CreatePSCmd = 'echo powershell.exe -ExecutionPolicy Bypass -File "' + @PSFile + '" > ' + @BatchFile
    EXEC xp_cmdshell @CreatePSCmd, no_output
    
    BEGIN TRY
        -- Esegui il comando batch e cattura l'output
        INSERT INTO #CommandOutput
        EXEC xp_cmdshell @BatchFile
        
        -- Cerca l'ID dell'email nell'output
        DECLARE @EmailID VARCHAR(100) = NULL
        DECLARE @Success BIT = 0
        
        SELECT @EmailID = SUBSTRING(Output, 9, LEN(Output) - 8),
               @Success = 1
        FROM #CommandOutput
        WHERE Output LIKE 'SUCCESS:%'
        
        -- Verifica l'esito
        IF @Success = 1
        BEGIN
            SELECT 1 AS Successo, 
                  'Email inviata con successo' AS Messaggio,
                  @EmailID AS EmailID
            
            -- Pulisci
            DROP TABLE #CommandOutput
            RETURN 0
        END
        ELSE
        BEGIN
            -- Recupera eventuali errori
            DECLARE @ErrorMsg VARCHAR(MAX) = ''
            
            SELECT @ErrorMsg = @ErrorMsg + ISNULL(Output, '') + CHAR(13) + CHAR(10)
            FROM #CommandOutput
            WHERE Output IS NOT NULL
            
            SELECT 0 AS Successo, 
                  'Errore durante l''invio dell''email' AS Messaggio,
                  @ErrorMsg AS ErrorDetails
            
            -- Pulisci
            DROP TABLE #CommandOutput
            RETURN 1
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(MAX) = ERROR_MESSAGE()
        
        SELECT 0 AS Successo,
               @ErrorMessage AS Messaggio,
               ERROR_NUMBER() AS ErrorNumber,
               ERROR_SEVERITY() AS ErrorSeverity,
               ERROR_STATE() AS ErrorState,
               ERROR_PROCEDURE() AS ErrorProcedure,
               ERROR_LINE() AS ErrorLine
        
        -- Pulisci
        IF OBJECT_ID('tempdb..#CommandOutput') IS NOT NULL
            DROP TABLE #CommandOutput
        
        RETURN -1
    END CATCH
END 