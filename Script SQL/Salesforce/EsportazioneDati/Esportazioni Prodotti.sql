-- =========================================================================
    -- STEP 10: Inserimento Prodotti
    -- =========================================================================

	SELECT 'Prodotti' AS Prodotti

	SELECT DISTINCT
		psf.Art_Id AS External_Id__c,
		ISNULL(psf.SETTORE,'N/D') AS Settore__c,
		ISNULL(psf.MARCA,'') AS Marca__c,
		ISNULL(psf.ART_CODICE,'') AS ProductCode,
		ISNULL(psf.DESCR_DIRECT,'N/D') AS Description,
		ISNULL(psf.DESCR_ESTESA,'N/D') AS Name,
		ISNULL(psf.ART_STAGIONE,'N/D') AS Tipologia_gomma__c,
		(CASE psf.Stato_Articolo WHEN 'G' THEN 1 ELSE 0 END) AS IsActive,
		ISNULL(psf.Fascia,'X') AS Fascia__c,
		ISNULL(psf.Ext_EAN,'') AS StockKeepingUnit,
		ISNULL(psf.ART_CAI,'') AS CAI__c,
		ISNULL(psf.IC,'') AS Indice_di_carico__c,
		ISNULL(psf.IV,'') AS Indice_di_velocita__c,
		ISNULL(psf.classificatore1,'') AS Larghezza__c,
		ISNULL(psf.classificatore2,'') AS Spalla__c,
		ISNULL(psf.classificatore3,'') AS Diametro__c,
		(CASE psf.ART_RUNFLAT WHEN 'SI' THEN 1 ELSE 0 END) AS Runflat__c,
		ISNULL(psf.ext_dot,'') AS Dot__c,
		ISNULL(psf.Rotolamento,'') AS Consumo_Rotolamento__c,
		ISNULL(psf.Aderenza,'') AS Aderenza_sul_bagnato__c,
		ISNULL(psf.Decibel,'') AS Rumorosita_decibel__c,
		ISNULL(psf.Rumorosita,'') AS Rumorosita_onde__c

		FROM I24DB.dbo.ProdottiSalesForce psf
	