USE PiattaformeWeb

-- ===== Magazzino ===== 

SELECT 'Riga Magazzino' AS [Riga Magazzino]

-- Fornitori esterni esistenti
SELECT
	ow.IDARTICO AS [Articolo__r:Product2:External_Id__c],
	ow.CodMagForn AS Codice_fornitore__c,
	fp.Descrizione AS Descrizione_fornitore__c,
	ISNULL(ow.PosT24, 1) AS Ranking_fornitore__c,
	ow.Qta AS Disponibile__c,
	ISNULL(psf.Impegnato, 0) AS Impegnato__c,
	ISNULL(psf.Inspedizione, '0') AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ow.Prezzo,',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM OfferteWeb ow INNER JOIN
Ant_FornPiattaforma fp ON fp.IdForPiatt = ow.IdFornitore
LEFT JOIN i24db.dbo.ProdottiSalesForce psf ON ow.IdArtico = psf.Art_Id
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON ow.IdArtico = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON ow.IdArtico = sped.QTTN

UNION ALL

-- Negozi BG1-BG8 come fornitori virtuali
SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG1' AS Codice_fornitore__c,
	'Bologna Gomme 1 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG1, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG1, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG2' AS Codice_fornitore__c,
	'Bologna Gomme 2 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG2, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG2, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG3' AS Codice_fornitore__c,
	'Bologna Gomme 3 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG3, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG3, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG4' AS Codice_fornitore__c,
	'Bologna Gomme 4 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG4, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG4, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BGD' AS Codice_fornitore__c,
	'Bologna Gomme BGD - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG5, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG5, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG6' AS Codice_fornitore__c,
	'Bologna Gomme 6 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG6, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG6, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG7' AS Codice_fornitore__c,
	'Bologna Gomme 7 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG7, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG7, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG8' AS Codice_fornitore__c,
	'Bologna Gomme 8 - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG8, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG8, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG5_CG' AS Codice_fornitore__c,
	'Bologna Gomme 5 CG - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG5_CG, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG5_CG, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG6_CSP' AS Codice_fornitore__c,
	'Bologna Gomme 6 CSP - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG6_CSP, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG6_CSP, 0) > 0

UNION ALL

SELECT
	psf.Art_Id AS [Articolo__r:Product2:External_Id__c],
	'BG7_FUNO' AS Codice_fornitore__c,
	'Bologna Gomme 7 Funo - Magazzino' AS Descrizione_fornitore__c,
	10 AS Ranking_fornitore__c,
	ISNULL(psf.BG7_Funo, 0) AS Disponibile__c,
	ISNULL(imp.QTTN, 0) AS Impegnato__c,
	ISNULL(sped.QTTN, 0) AS In_spedizione__c,
	ISNULL(psf.CDFDistr, 0) AS Conto_deposito_fornitore_Distribuzione__c,
	ISNULL(psf.CDFPDV, 0) AS Conto_deposito_fornitore_pdv__c,
	REPLACE(ISNULL(psf.UltimoCosto, '0'),',','.') AS Costo__c,
	REPLACE(ISNULL(psf.LISTINO, '0'),',','.') AS Prezzo_di_listino__c,
	REPLACE(ISNULL(psf.Prezzo, '0'),',','.') AS Prezzo_PDV__c,
	REPLACE(ISNULL(psf.PrAcq, '0'),',','.') AS PAC__c

FROM i24db.dbo.ProdottiSalesForce psf
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloImpegnato imp ON psf.Art_Id = imp.IDARTICO
LEFT JOIN i24bo.dbo.VDispNettaPneus24SoloSpedizione sped ON psf.Art_Id = sped.QTTN
WHERE ISNULL(psf.BG7_Funo, 0) > 0