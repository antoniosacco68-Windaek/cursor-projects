USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[Ant_ImportOrdiniTyre24_Ricambi_BR]    Script Date: 23/06/2025 12:23:55 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[Ant_ImportOrdiniTyre24_Ricambi_BR]

AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		--================= Importazione Ordini Tyre24 ===========================--

		DECLARE @URL NVARCHAR(255),@file NVARCHAR(255), @cmd NVARCHAR(255),@NomeFileXml varchar(200),@Bulk nvarchar(500),@Ordine varchar(80),@Id int,@NomeCsvDaArchiviare Varchar(400),@Data as varchar(25) = Replace((SELECT Ltrim(Rtrim(Cast(GETDATE() AS DATE))) + '_' + Left(LTRIM(Rtrim(CAST(GETDATE() AS TIME))),8)),':','')
		DECLARE @ApyKey VARCHAR(400), @RitornoComferma varchar(250), @Json VARCHAR(MAX)
		DECLARE @XML AS XML, @hDoc AS INT

		DECLARE @ListaFile TABLE (ID int IDENTITY, [TFileName] varchar(100))

		-- ======================================================================================================================================================================== --
		-- ================================================================= PROCEDURA DOWNLOAD TYRE24 RICAMBI_BR ================================================================= --
		-- ======================================================================================================================================================================== --

		DECLARE @ApyKey2 VARCHAR(400) = 'ODI3OTQ0YTBlZjc2ODY2NDEzZGE4ZjcwN2FiOGVkNzE0N2JlNDNjYmNkNmZmNTUyNmZmOTU3NzQ3ZDk5ODA0NjE1MjJlN2YyODg0ZTkzOTA5NzExMGJhNWIzZmJkZWVlMThmMTE0YWVlNzgyYmY=' -- Questo del secondo account 24H 1381

		EXEC Tyre24.dbo.SP_ScaricoUltimoOrdineT24_PowerShell @ApyKey2, 'it', 0, 0, 0, 'SELLER', 0, @RitornoComferma OUTPUT

		-- Possibili Json Scaricati con Errori da Cancellare --
		DELETE Tyre24.dbo.Tjson_BGD WHERE Json_Table = '{"data":[],"meta":{"count":0}}'
		DELETE Tyre24.dbo.Tjson_BGD WHERE Json_Table LIKE '%"error":"ERR_REQUEST_LIMIT_EXCEEDED"%' 
		DELETE Tyre24.dbo.Tjson_BGD WHERE Json_Table LIKE '%"error_code":"ERR_GENERAL"%'

		-- Elaboro TUTTI gli ordini non elaborati per l'account 24H
		WHILE EXISTS (SELECT 1 FROM tyre24.dbo.Tjson_BGD WHERE Elaborato = 0)
		BEGIN
			SET @Json = (SELECT TOP 1 tb.Json_Table FROM tyre24.dbo.Tjson_BGD tb WHERE tb.Elaborato = 0)

			-- Verifico se ci sono ordini nel JSON prima di procedere
			IF EXISTS (SELECT 1 FROM OPENJSON(@Json, '$.data') AS order_json WHERE JSON_VALUE(order_json.value, '$.order') IS NOT NULL)
			BEGIN 
				
				INSERT INTO PiattaformeWeb.dbo.[Ant_OrdiniTyre24_Tmp]
					([TOrdineNr],[TType],[Tpayment_method_cost],[Tbuyer_id],[Tdate],[Tsum_net],[Tsum_gross],[Tcomment],[Tuse_diff_delivery_address],[Tdelivery_name],[Tdelivery_street],[Tdelivery_zip],[Tdelivery_city],
					[Tdelivery_country],[Tdelivery_neutral],[Tdelivery_cost],[Tshipping_method],[Tshipping_method_name],[Tshipping_method_costs],[Tbuyer_name1],[Tbuyer_street],[Tbuyer_zip],[Tbuyer_city]
					,[Tbuyer_ustid],[Tbuyer_bank],[Tbuyer_account_owner],[Tbuyer_iban]
					,[Tbuyer_swift_bic],[Tbuyer_country],[Tpayment_method_id],[Tpayment_method_name],[Tpayment_method_text],[Tpayment_method_additional_sum],[Tcountry],[Tposition],[Tposition_id],[Tarticle_id],[Torder_id],[Tprefix],[Tstatus],[Tposition_name1],[Tposition_name2]
					,[Tprice_net],[Tquantity],[Twholesaler_item_number],[TipoOrdine], Tpayment_method_generic_cost)
				SELECT
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.order')), 25) AS order_number,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.article_type')), 10) AS article_type,
				JSON_VALUE(order_json.value, '$.payment.method.price.net') AS payment_price_net,
				JSON_VALUE(order_json.value, '$.buyer.id') AS buyer_id,
				CONVERT(DATETIME, JSON_VALUE(order_json.value, '$.date'), 120) AS order_date,
				JSON_VALUE(order_json.value, '$.sum.net') AS sum_net,
				JSON_VALUE(order_json.value, '$.sum.gross') AS sum_gross,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.comment')), 8000) AS order_comment,
				IIF(JSON_VALUE(order_json.value, '$.shipping.delivery_address.use_alternative_address') = 'true', 1, 0) AS use_alternative_address,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.delivery_address.address.name')), 50) AS shipping_address_name,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.delivery_address.address.street')), 50) AS shipping_address_street,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.delivery_address.address.zip')), 10) AS shipping_address_zip,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.delivery_address.address.city')), 50) AS shipping_address_city,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.delivery_address.address.country')), 50) AS shipping_address_country,
				IIF(JSON_VALUE(order_json.value, '$.shipping.neutral') = 'true', 1, 0) AS shipping_neutral,
				JSON_VALUE(order_json.value, '$.shipping.handling_fee.net') AS handling_fee_net,
				JSON_VALUE(order_json.value, '$.shipping.method.id') AS shipping_method_id,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.shipping.method.name')), 100) AS shipping_method_name,
				JSON_VALUE(order_json.value, '$.shipping.method.price.net') AS shipping_price_net,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.address.name')), 50) AS buyer_name,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.address.street')), 50) AS buyer_street,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.address.zip')), 10) AS buyer_zip,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.address.city')), 50) AS buyer_city,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.tax.sales_tax_identification_number')), 20) AS buyer_sales_tax_id,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.bank.bank')), 50) AS buyer_bank_name,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.bank.owner')), 50) AS buyer_bank_owner,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.bank.iban')), 50) AS buyer_bank_iban,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.bank.bic_swift')), 50) AS buyer_bank_bic_swift,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.buyer.address.country')), 50) AS buyer_country,
				JSON_VALUE(order_json.value, '$.payment.method.id') AS payment_method_id,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.payment.method.name')), 50) AS payment_method_name,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.payment.method.text')), 250) AS payment_method_text,
				JSON_VALUE(order_json.value, '$.payment.price_additional.net') AS payment_price_additional_net,
				LEFT(LTRIM(JSON_VALUE(order_json.value, '$.country')), 50) AS country,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.article_type')), 1) AS article_type_pos,
				JSON_VALUE(position.value, '$.status') AS position_status,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.alzura_id')), 50) AS alzura_id,
				JSON_VALUE(position.value, '$.id') AS position_id,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.article_type')), 1) AS article_type_pos2,
				JSON_VALUE(position.value, '$.status') AS position_status2,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.position_name')), 50) AS position_name,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.position_description')), 50) AS position_description,
				JSON_VALUE(position.value, '$.price.net') AS position_price_net,
				JSON_VALUE(position.value, '$.quantity') AS quantity,
				LEFT(LTRIM(JSON_VALUE(position.value, '$.supplier_item_number')), 40) AS supplier_item_number,
				'Ricambi_BR',
				0
				FROM
					OPENJSON(@Json, '$.data') AS order_json
					CROSS APPLY OPENJSON(order_json.value, '$.positions') AS position;

				-- Pulisco il Campo Partita Iva nel caso fosse vuoto per poi fermare la lavorazione dopo nel DOC T24 --
				UPDATE Ant_OrdiniTyre24_Tmp
					SET Tbuyer_ustid = NULL
				WHERE LTRIM(RTRIM(Tbuyer_ustid)) = ''

				INSERT INTO [Ant_OrdiniTyre24]
					([TOrdineNr],[TType],[Tpayment_method_cost],[Tbuyer_id],[Tdate],[Tsum_net],[Tsum_gross],[Tcomment] ,[Tuse_diff_delivery_address],[Tdelivery_name],[Tdelivery_street],[Tdelivery_zip],[Tdelivery_city],
					[Tdelivery_country],[Tdelivery_neutral],[Tdelivery_cost],[Tshipping_method],[Tshipping_method_name],[Tshipping_method_costs],[Tbuyer_name1],[Tbuyer_name2],[Tbuyer_street],[Tbuyer_zip],[Tbuyer_city]
					,[Tbuyer_ustid],[Tbuyer_phone],[Tbuyer_fax],[Tbuyer_contact],[Tbuyer_bank],[Tbuyer_account_owner],[Tbuyer_cr_index],[Tbuyer_cr_check_date],[Tbuyer_cr_limit],[Tbuyer_cr_text],[Tbuyer_iban]
					,[Tbuyer_swift_bic],[Tbuyer_country],[Tsepa_mandate_reference],[Tsepa_mandate_pdf],[Tpayment_method_id],[Tpayment_method_name],[Tpayment_method_costs_currency],[Tpayment_method_generic_cost],
					[Tpayment_method_text],[Tpayment_method_additional_sum],[Tcountry],[Tposition],[Tposition_id],[Tarticle_id],[Torder_id],[Tprefix],[Tstatus],[Tposition_name1],[Tposition_name2],[Tposition_name3]
					,[Tprice_net],[Tquantity],[Ttax],[Tean],TArticleId,TmanufacturerName,Tmanufacturer_number,TarticleReference,Tbrand_id,[Twholesaler_item_number],[Txml_id],[TipoOrdine],Tbuyer_recipient_code)
				SELECT DISTINCT
					[TOrdineNr],[TType],[Tpayment_method_cost],[Tbuyer_id],[Tdate],[Tsum_net],[Tsum_gross],[Tcomment] ,[Tuse_diff_delivery_address],[Tdelivery_name],[Tdelivery_street],[Tdelivery_zip],[Tdelivery_city],
					[Tdelivery_country],[Tdelivery_neutral],[Tdelivery_cost],[Tshipping_method],[Tshipping_method_name],[Tshipping_method_costs],[Tbuyer_name1],[Tbuyer_name2],[Tbuyer_street],[Tbuyer_zip],[Tbuyer_city]
					,[Tbuyer_ustid],[Tbuyer_phone],[Tbuyer_fax],[Tbuyer_contact],[Tbuyer_bank],[Tbuyer_account_owner],[Tbuyer_cr_index],[Tbuyer_cr_check_date],[Tbuyer_cr_limit],[Tbuyer_cr_text],[Tbuyer_iban]
					,[Tbuyer_swift_bic],[Tbuyer_country],[Tsepa_mandate_reference],[Tsepa_mandate_pdf],[Tpayment_method_id],[Tpayment_method_name],[Tpayment_method_costs_currency],[Tpayment_method_generic_cost],
					[Tpayment_method_text],[Tpayment_method_additional_sum],[Tcountry],[Tposition],[Tposition_id],[Tarticle_id],[Torder_id],[Tprefix],[Tstatus],[Tposition_name1],[Tposition_name2],[Tposition_name3]
					,[Tprice_net],[Tquantity],[Ttax],[Tean],TArticleId,TmanufacturerName,Tmanufacturer_number,TarticleReference,Tbrand_id,[Twholesaler_item_number],[Txml_id],[TipoOrdine],Tbuyer_recipient_code
				FROM [Ant_OrdiniTyre24_Tmp]
				WHERE NOT EXISTS (SELECT ID FROM Ant_OrdiniTyre24 WHERE ltrim(Rtrim(Ant_OrdiniTyre24.TOrdineNr)) = ltrim(rtrim(Ant_OrdiniTyre24_Tmp.TOrdineNr)) )

			END

			-- Segno come elaborato il JSON corrente
			UPDATE tyre24.dbo.Tjson_BGD
				SET Elaborato = 1
			WHERE Json_Table = @Json

		END

	-------------------- Agente , Cartella e CatForn --------------------------------

	UPDATE Ant_OrdiniTyre24
		SET AgenteId = 5, Cartella = 'C:\Antonio\Tyre24\Ricambi_BR\',CatForn = 'Forn_Ricambi_Italia' -- Scrive che è un Ordine Ricambi
	from Ant_OrdiniTyre24
	WHERE TipoOrdine = 'Ricambi_BR' AND Elaborato IS NULL -- Ricambi

	-------------------------------------------------- Pulisco ("Tbuyer_ustid" Partita Iva) ---------------------------------------

	UPDATE Ant_OrdiniTyre24
		SET Tbuyer_ustid = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(Tbuyer_ustid,'IT',''),'DE',''),'NL',''),'AT',''),'BE',''),'FR',''),'LU',''),'ES',''),'PL','')
	WHERE Elaborato IS NULL


	-------------------- Tipo di società (NULL def.; D= ditta individuale; S= società di persone; C= società di capitali) --------------------------------
	UPDATE Ant_OrdiniTyre24
		SET TipoPersona = 0,TipoSocieta = 'D'
	WHERE Elaborato IS NULL

	UPDATE Ant_OrdiniTyre24
		SET TipoSocieta = 'S'
	WHERE Tdelivery_name like '%s.a%' or Tdelivery_name like '%sa%' or Tdelivery_name like '%s.n%' or Tdelivery_name like '%sn%' AND Elaborato IS NULL

	UPDATE Ant_OrdiniTyre24
		SET TipoSocieta = 'C'
	WHERE Tdelivery_name like '%s.p%' or Tdelivery_name like '%sp%' or Tdelivery_name like '%s.r%' or Tdelivery_name like '%sr%' AND Elaborato IS NULL

	-------------------- Abbinamento x Ricambi ---------------------

	UPDATE Ant_OrdiniTyre24
		SET IdArtico = 561948 ,IdMarca = 10009 -- 561948 "@7RICWEB" -- 10009 "Meccanica Leggera"
	WHERE Ant_OrdiniTyre24.IdArtico IS NULL AND TipoOrdine = 'Ricambi_BR' AND Elaborato IS NULL

	-------------------- Scrivo IdCliente 'Tbuyer_ustid' =  'PARIVA' --------------------------------

	UPDATE Ant_OrdiniTyre24
		SET IdCliente = CLIENTI.ID
	FROM Ant_OrdiniTyre24 LEFT OUTER JOIN I24BO.dbo.PERSONE ON Ltrim(Rtrim(Replace(Tbuyer_ustid,'-',''))) = Ltrim(Rtrim(Replace(PARIVA,'-',''))) INNER JOIN I24BO.dbo.CLIENTI ON IDPERSONA = PERSONE.ID
	WHERE IdCliente IS NULL

	----------------------------- Lancio la Stored Procedure "Ant_Doc_OrdineTyre24" per creare gli ordini nuovi Ricambi se ci sono ITALIA --------------------------------

	SELECT id,Tbuyer_name1,Tquantity,Tposition_name1,Tposition_name2,Twholesaler_item_number,TipoOrdine,* FROM Ant_OrdiniTyre24 WHERE Elaborato is NULL AND TipoOrdine = 'Ricambi_BR' ORDER by Ant_OrdiniTyre24.ID

	IF @@ROWCOUNT > 0 BEGIN

		-----========== Tyre24 ==========-----
		INSERT INTO [dbo].[OrdiniClientiAll]
			([OrdineNum],OrdineNumOrig,[DataOrdine],[OrdineSettore],[IdCliente],[DropShipping],
			[CliDescr],[CliInd],[CliCitta],[CliCap],[CliTel],[CliContact],[CliPiva],[CliBanca],[CliIban],[CliSwift],[CliNazione],[CliSID],
			[DestDescr],[DestInd],[DestCitta],[DestCap],[DestNazione],AddContrTrasp,AddSpeseIncasso,TipoPagamento,
			[NoteOrdine],[CodiceArticolo],[Art_ID],[Ean],[DescrArticolo],[Qta],[ValUni],[ValTot],
			[TipoOrdine],Canale,AgenteId,CatFornit,cartella,GiorniConsegna)
		SELECT
			'T24_' + Ltrim(TOrdineNr),TOrdineNr,Tdate,'Ricambi_BR' ,NULL,Tuse_diff_delivery_address,
			Ltrim(Rtrim(Tbuyer_name1)) + ' ' + ISNULL(Ltrim(Rtrim(Tbuyer_name2)),''),Tbuyer_street,Tbuyer_city,Tbuyer_zip,Tbuyer_phone,Tbuyer_contact,Tbuyer_ustid,Tbuyer_bank,Tbuyer_iban,Tbuyer_swift_bic,Tcountry,Tbuyer_recipient_code,
			Tdelivery_name,Tdelivery_street,Tdelivery_city,Tdelivery_zip,Tdelivery_country,Tdelivery_cost,Tpayment_method_generic_cost,Tpayment_method_name,
			Tcomment,Twholesaler_item_number,IdArtico,Tean,Ltrim(Rtrim(Tposition_name1)) + ' ' + ISNULL(Ltrim(Rtrim(Tposition_name2)),''),Tquantity,Tprice_net,Tsum_net,
			[TipoOrdine],'Piattaforme',5,CatForn,Cartella,3
		FROM Ant_OrdiniTyre24 WHERE Elaborato IS NULL AND TipoOrdine = 'Ricambi_BR' AND NOT EXISTS (SELECT ID FROM OrdiniClientiAll WHERE 'T24_' + Ltrim(TOrdineNr) = OrdineNum)
	
		UPDATE OrdiniClientiAll -- Sistemo la Nazione dove Manca
			SET DestNazione = CliNazione
		WHERE DestNazione = ''

		--===== Aggiorno il Fornitore ed il Prezzo di Acquisto =====--
		UPDATE Ant_OrdiniTyre24
			SET CMF = 'Ricambi_BR', PACF = 0
		FROM Ant_OrdiniTyre24 INNER JOIN RicambiCSV ON TecDocID = Tmanufacturer_number WHERE TipoOrdine = 'Ricambi_BR' AND CMF IS NULL

		--------------------------------------------------------------
		
		EXEC [Ant_Doc_OrdineTyre24_Ricambi_NoStock] 'Ricambi_BR'
	END
	END TRY
    BEGIN CATCH
        -- Gestione degli errori
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;
		DECLARE @Errorline VARCHAR(50)
		DECLARE @ErrorProcedure VARCHAR(50)
		DECLARE @body nvarchar(4000),@TProfileName varchar(50),@to_mails nvarchar(500) = 'antonio.sacco@bolognagomme.com',@cc_mails nvarchar(500) = '',@ccn_mails nvarchar(500) = '',@subject nvarchar(500)

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE(),
			@Errorline = ERROR_LINE( ),
			@ErrorProcedure = ERROR_PROCEDURE( )

        -- Invia un'email di notifica
		SET @body = 'Si è verificato un errore durante la Creazione ORdini Tyre24 Ricambi BR: ' + @ErrorMessage + ' Linea: ' + @Errorline + ' Stored: ' + @ErrorProcedure
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'SQL',
            @recipients = @to_mails,
            @subject = 'Errore durante la Creazione Ordini Tyre24 Ricambi BR',
            @body = @body

        -- Rilancia l'errore
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState, @Errorline, @ErrorProcedure);
    END CATCH


END

