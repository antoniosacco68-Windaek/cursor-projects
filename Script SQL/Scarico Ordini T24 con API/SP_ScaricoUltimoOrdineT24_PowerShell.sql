USE [Tyre24]
GO

/****** Object:  StoredProcedure [dbo].[SP_ScaricoUltimoOrdineT24_PowerShell]    Script Date: 05/06/2025 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		Antonio
-- Create date: 05/06/2025
-- Description:	Scarica ultimi ordini Tyre24 tramite PowerShell
-- =============================================
CREATE PROCEDURE [dbo].[SP_ScaricoUltimoOrdineT24_PowerShell]
	@ApyKey VARCHAR(400),
	@Country VARCHAR(2) = 'it',
	@Counter INT = 0,
	@NoTagging INT = 0,
	@TrackingNumber INT = 0,
	@OrderRole VARCHAR(20) = 'SELLER',
	@Demo INT = 0,
	@RitornoComferma VARCHAR(250) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @command NVARCHAR(MAX);
	DECLARE @command_varchar VARCHAR(8000);
	DECLARE @scriptPath VARCHAR(500) = 'C:\Antonio\Tyre24\Scripts\DownloadLatestOrdersT24.ps1';

	BEGIN TRY
		-- Costruzione del comando PowerShell con i parametri
		SET @command = 'powershell.exe -ExecutionPolicy Bypass -File "' + @scriptPath + '"' +
					   ' -apiKey "' + @ApyKey + '"' +
					   ' -country "' + @Country + '"' +
					   ' -counter ' + CAST(@Counter AS VARCHAR(10)) +
					   ' -no_tagging ' + CAST(@NoTagging AS VARCHAR(1)) +
					   ' -tracking_number ' + CAST(@TrackingNumber AS VARCHAR(10)) +
					   ' -order_role "' + @OrderRole + '"' +
					   ' -demo ' + CAST(@Demo AS VARCHAR(1));

		-- Conversione in varchar per xp_cmdshell
		SET @command_varchar = CAST(@command AS VARCHAR(8000));

		-- Esecuzione del comando PowerShell
		EXEC xp_cmdshell @command_varchar, no_output;

		SET @RitornoComferma = 'Download completato con successo tramite PowerShell';

	END TRY
	BEGIN CATCH
		SET @RitornoComferma = 'Errore durante il download: ' + ERROR_MESSAGE();
		
		-- Log dell'errore (opzionale)
		DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
		DECLARE @ErrorState INT = ERROR_STATE();
		
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
	END CATCH

	-- Restituisci il risultato
	SELECT @RitornoComferma AS Risultato;
END
GO 