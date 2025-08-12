USE [I24DB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Antonio Sacco
-- Create date: 16/04/2025
-- Description:	Versione alternativa per inviare email (metodo più diretto)
-- =============================================
CREATE OR ALTER PROCEDURE [dbo].[SP_InvioEmailPerDbLavoro_V2]
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

	-- Crea una tabella temporanea per memorizzare l'output del comando PowerShell
	CREATE TABLE #OutputTable (
		ID INT IDENTITY(1,1),
		OutputText NVARCHAR(MAX)
	)

	DECLARE @PowerShellScriptPath NVARCHAR(255) = 'C:\Antonio\ScriptPowershell\InvioEmailCommando.ps1'
	DECLARE @PowerShellCmd NVARCHAR(MAX)
	
	-- Creare un nuovo script PowerShell temporaneo che verrà eseguito
	SET @PowerShellCmd = N'echo # Script PowerShell temporaneo per inviare email > ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output

	-- Aggiungi le importazioni DLL
	SET @PowerShellCmd = N'echo # Carica le DLL necessarie >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo $dllPath = "C:\Antonio\GoogleApi\lib" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo Add-Type -Path "$dllPath\Newtonsoft.Json.dll" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo Add-Type -Path "$dllPath\Google.Apis.Core.dll" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo Add-Type -Path "$dllPath\Google.Apis.dll" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo Add-Type -Path "$dllPath\Google.Apis.Auth.dll" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo Add-Type -Path "$dllPath\Google.Apis.Gmail.v1.dll" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Configura le credenziali
	SET @PowerShellCmd = N'echo # Configurazione credenziali >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo $serviceAccountKeyPath = "C:\Antonio\GoogleApi\private-key.json" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Mittente
	SET @PowerShellCmd = N'echo $mittente = "' + @Mittente + '" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Destinatari
	SET @PowerShellCmd = N'echo $destinatari = "' + @StrTo + '" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Oggetto (escape degli apici)
	DECLARE @EscapedSubject NVARCHAR(MAX) = REPLACE(@Subject, '"', '`"')
	SET @PowerShellCmd = N'echo $oggetto = "' + @EscapedSubject + '" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Corpo (escape degli apici e impostazione come here-string in PowerShell)
	DECLARE @PowerShellBody NVARCHAR(MAX)
	SET @PowerShellBody = N'echo $corpo = @"' + CHAR(13) + CHAR(10) + 
						  @Body + CHAR(13) + CHAR(10) + 
						  N'"@ >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellBody, no_output
	
	-- CC e CCN
	IF @CC IS NOT NULL AND @CC <> ''
	BEGIN
		SET @PowerShellCmd = N'echo $cc = "' + @CC + '" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	ELSE
	BEGIN
		SET @PowerShellCmd = N'echo $cc = "" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	
	IF @CCN IS NOT NULL AND @CCN <> ''
	BEGIN
		SET @PowerShellCmd = N'echo $ccn = "' + @CCN + '" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	ELSE
	BEGIN
		SET @PowerShellCmd = N'echo $ccn = "" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	
	-- Allegati
	IF @Attachment IS NOT NULL AND @Attachment <> ''
	BEGIN
		SET @PowerShellCmd = N'echo $allegato = "' + REPLACE(@Attachment, '\', '\\') + '" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	ELSE
	BEGIN
		SET @PowerShellCmd = N'echo $allegato = "" >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	
	-- Formato HTML
	IF @FormatoHTML = 1
	BEGIN
		SET @PowerShellCmd = N'echo $formatoHTML = $true >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	ELSE
	BEGIN
		SET @PowerShellCmd = N'echo $formatoHTML = $false >> ' + @PowerShellScriptPath
		EXEC xp_cmdshell @PowerShellCmd, no_output
	END
	
	-- Aggiungi il resto del codice PowerShell
	SET @PowerShellCmd = N'echo try { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     # Carica le credenziali >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $credential = [Google.Apis.Auth.OAuth2.GoogleCredential]::FromFile($serviceAccountKeyPath) >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $scoped = $credential.CreateScoped("https://www.googleapis.com/auth/gmail.send") >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $delegated = $scoped.CreateWithUser($mittente) >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     # Crea il servizio Gmail >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $initializer = New-Object Google.Apis.Services.BaseClientService+Initializer >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $initializer.HttpClientInitializer = $delegated >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $initializer.ApplicationName = "BG MailSender" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $service = New-Object Google.Apis.Gmail.v1.GmailService -ArgumentList $initializer >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Preparazione dell'email
	SET @PowerShellCmd = N'echo     # Prepara l''email >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $headers = @( >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         "From: $mittente", >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         "To: $destinatari" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     ) >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     if (-not [string]::IsNullOrEmpty($cc)) { $headers += "Cc: $cc" } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     if (-not [string]::IsNullOrEmpty($ccn)) { $headers += "Bcc: $ccn" } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $headers += "Subject: $oggetto" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     if ($formatoHTML) { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         $headers += "Content-Type: text/html; charset=UTF-8" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     } else { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         $headers += "Content-Type: text/plain; charset=UTF-8" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Corpo email e allegati
	SET @PowerShellCmd = N'echo     $emailBody = $headers -join "`r`n" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $emailBody += "`r`n`r`n" + $corpo >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Gestione allegati
	SET @PowerShellCmd = N'echo     if (-not [string]::IsNullOrEmpty($allegato)) { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         # Gestione allegati (codice minimo) >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         Write-Host "Allegati presenti, ma codice semplificato per debug" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Codifica e invio
	SET @PowerShellCmd = N'echo     # Codifica il messaggio in base64 per l''API Gmail >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $rawMessage = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($emailBody)) >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $rawMessage = $rawMessage.Replace(''+", "-").Replace(''/", "_").Replace(''='', """") >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $msg = New-Object Google.Apis.Gmail.v1.Data.Message >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $msg.Raw = $rawMessage >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     # Invia l''email >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     $response = $service.Users.Messages.Send($msg, "me").Execute() >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     Write-Output "SUCCESS: $($response.Id)" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Gestione errori
	SET @PowerShellCmd = N'echo } catch { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     Write-Error "Errore: $_" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     if ($_.Exception.InnerException) { >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo         Write-Error "Inner Exception: $($_.Exception.InnerException.Message)" >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo     exit 1 >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	SET @PowerShellCmd = N'echo } >> ' + @PowerShellScriptPath
	EXEC xp_cmdshell @PowerShellCmd, no_output
	
	-- Esecuzione del comando PowerShell
	DECLARE @PsExecCmd NVARCHAR(500) = N'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScriptPath + '"'
	
	BEGIN TRY
		-- Esegui PowerShell e cattura l'output
		INSERT INTO #OutputTable (OutputText)
		EXEC xp_cmdshell @PsExecCmd
		
		-- Verifica il risultato
		DECLARE @Success BIT = 0
		DECLARE @EmailID NVARCHAR(255) = NULL
		
		SELECT @Success = 1, @EmailID = SUBSTRING(OutputText, 10, LEN(OutputText) - 9)
		FROM #OutputTable 
		WHERE OutputText LIKE 'SUCCESS:%'
		
		IF @Success = 1
		BEGIN
			SELECT 
				1 AS Successo, 
				'Email inviata con successo' AS Messaggio,
				@EmailID AS EmailID
			RETURN 0
		END
		ELSE
		BEGIN
			-- Recupera i messaggi di errore
			DECLARE @ErrorMsg NVARCHAR(MAX) = ''
			
			SELECT @ErrorMsg = @ErrorMsg + OutputText + CHAR(13) + CHAR(10)
			FROM #OutputTable
			WHERE OutputText IS NOT NULL
			
			SELECT 
				0 AS Successo, 
				'Errore durante l''invio dell''email' AS Messaggio,
				@ErrorMsg AS ErrorDetails
			RETURN 1
		END
	END TRY
	BEGIN CATCH
		DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE()
		
		SELECT 
			0 AS Successo,
			@ErrMsg AS Messaggio,
			ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() AS ErrorState,
			ERROR_PROCEDURE() AS ErrorProcedure,
			ERROR_LINE() AS ErrorLine
		
		RETURN -1
	END CATCH
	
	DROP TABLE #OutputTable
END 