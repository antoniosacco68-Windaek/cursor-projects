USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_InvioEmailPerDbLavoro]    Script Date: 16/04/2025 10:32:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SP_InvioEmailPerDbLavoro]
	-- Add the parameters for the stored procedure here
	@Mittente VARCHAR(80),
	@StrTo VARCHAR(200),
	@Subject VARCHAR(200),
	@Body VARCHAR(MAX),
	@Attachment VARCHAR(400)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @TProfileName varchar(50),@cc_mails nvarchar(500) = '',@ccn_mails nvarchar(500) = ''

	IF @Mittente = 'bg1team@bolognagomme.com' SET @TProfileName = 'Bg1 Appuntamenti'
	IF @Mittente = 'bg2team@bolognagomme.com' SET @TProfileName = 'Bg2 Appuntamenti'
	IF @Mittente = 'bg3team@bolognagomme.com' SET @TProfileName = 'Bg3 Appuntamenti'
	IF @Mittente = 'bg4team@bolognagomme.com' SET @TProfileName = 'Bg4 Appuntamenti'
	IF @Mittente = 'bg5team@bolognagomme.com' SET @TProfileName = 'Bg5 Appuntamenti'
	IF @Mittente = 'bg6team@bolognagomme.com' SET @TProfileName = 'Bg6 Appuntamenti'
	IF @Mittente = 'bg7team@bolognagomme.com' SET @TProfileName = 'Bg7 Appuntamenti'
	IF @Mittente = 'bg1truck@bolognagomme.com' SET @TProfileName = 'Bg Autocarro'
	IF @Mittente = 'noreply@bolognagomme.com' SET @TProfileName = 'InfoBg'
	IF @Mittente = 'info@bolognagomme.com' SET @TProfileName = 'InfoBg'

	--------------------------------------------- Creo il CSV con i Clienti Modificati ---------------------------------------------


	--SET @TProfileName = 'Bg1 Appuntamenti'
		SET @subject = @Subject
		if @body is null set @body = ''
		
		--SET @StrTo = 'windaed@gmail.com'

		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name			=	@TProfileName,
			@recipients				=	@StrTo,
			@copy_recipients		=	@cc_mails,
			@blind_copy_recipients	=	@ccn_mails,
			@subject				=	@subject,
			@body					=	@body,
			@body_format			= 'HTML',
			@file_attachments		=	@Attachment

END