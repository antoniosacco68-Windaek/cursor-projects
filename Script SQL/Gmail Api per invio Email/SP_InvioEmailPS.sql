USE [I24DB]
GO

/****** Object:  StoredProcedure [dbo].[SP_InvioEmailPerDbLavoroPowershell]    Script Date: 07/05/2025 14:50:17 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Antonio Sacco
-- Create date: 16/04/2025
-- Description:	Versione finale per l'invio di email tramite Gmail API (non bloccante)
-- =============================================
ALTER PROCEDURE [dbo].[SP_InvioEmailPS]
	-- Add the parameters for the stored procedure here
	@Mittente VARCHAR(80),
	@StrTo VARCHAR(200),
	@Subject NVARCHAR(200),
	@Body NVARCHAR(MAX),
	@Attachment VARCHAR(400) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	DECLARE
	@CC VARCHAR(200) = NULL,
	@CCN VARCHAR(200) = NULL,
	@FormatoHTML BIT = 1  -- Sempre 1, formato HTML sempre attivo
    
    -- Definisci percorsi file
    DECLARE @ScriptPath VARCHAR(255) = 'C:\Antonio\ScriptPowershell\InviaEmailSqlNew.ps1'
    
    -- Se il corpo è vuoto, usa un messaggio predefinito
    IF @Body IS NULL OR @Body = ''
    BEGIN
        SET @Body = ' '
    END
    
	-- ===== Decido il NomeMittente ===== --
	DECLARE @NomeMittente varchar (80) =
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
		END

    -- Genera un ID univoco per questa email
    DECLARE @EmailID UNIQUEIDENTIFIER = NEWID()
    
    -- Inserisci i dati nella tabella
    INSERT INTO [dbo].[EmailData]
           ([ID], [DataCreazione], [Mittente], NomeMittente, [Destinatario], [CC], [CCN], 
            [Oggetto], [Corpo], [FormatoHTML], [Allegato], [Inviata], StatoElaborazione)
    VALUES
           (@EmailID, GETDATE(), @Mittente, @NomeMittente, @StrTo, @CC, @CCN, 
            @Subject, '<html><body>' + @Body + '</body></html>', @FormatoHTML, @Attachment, 0, 'In Coda')
    
    -- Comando PowerShell ultra-semplificato: passiamo solo l'ID dell'email al PowerShell
    -- e utilizziamo START per lanciarlo in modalità non bloccante
    DECLARE @Cmd VARCHAR(1000) = 'START /B powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File "' + @ScriptPath + '" -EmailID "' + CONVERT(VARCHAR(50), @EmailID) + '"'
    
    -- Esegui PowerShell in modalità non bloccante (asincrona)
    EXEC xp_cmdshell @Cmd, NO_OUTPUT
    
    -- Restituisci subito l'ID dell'email e lo stato 'In Coda'
    SELECT 
        1 AS Successo, 
        'Email messa in coda per l''invio.' AS Messaggio,
        CONVERT(VARCHAR(50), @EmailID) AS EmailID
    
    RETURN 0
END 
GO


