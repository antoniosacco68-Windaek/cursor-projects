USE [PiattaformeWeb]
GO

/****** Object:  StoredProcedure [dbo].[AA0_ImpCSV_AzzeraTBL]    Script Date: 20/06/2025 10:25:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- =======================================================================================================================================
-- Author:		<Sacco,,Antonio>
-- Create date: <04-10-2015>
-- Description:	<Listini Automatici Piattaforme e PDV>

-- Procedura Di Partenza Gira solo 1 Volta alla Mattina, cancella le TBL anche Ext_OffSpec e inserisce anche i PDV 
-- e Cancello i PRezzi Manuali di Stefano (Offerte "12") Quando gli Articoli non sono più Disponibili
-- =======================================================================================================================================
ALTER PROCEDURE  [dbo].[AA0_ImpCSV_AzzeraTBL]


AS
BEGIN

	SET NOCOUNT ON;

------------------- Pulisco i Campi di I24BO.dbo.PERSONE che usiamo per i Listini del B2b ---------------------------------------------
UPDATE I24BO.dbo.PERSONE
	SET INTERNET = NULL
WHERE INTERNET = '' -- Campo con il Codice del Listino assegnato a loro

UPDATE I24BO.dbo.PERSONE
	SET MEMOWEB = NULL
WHERE MEMOWEB = '' -- Campo con "OK" se i clienti possono entrare sul B2b

-- ============================================== Cancello Tutte Le TBL che USO =================================================================================
TRUNCATE TABLE Ant_ListiniManualiDistribuzione -- Cancello TBL
TRUNCATE TABLE Ant_ListiniManualiDistribuzioneCsv
--TRUNCATE TABLE Ant_ListiniManualiPdv
TRUNCATE TABLE OfferteWeb
TRUNCATE TABLE OfferteWeb_1Pass

--DBCC CHECKIDENT('PiattaformeWeb.dbo.Ant_ListiniManualiPdv', reseed, 0)
--DBCC CHECKIDENT('PiattaformeWeb.dbo.OfferteWeb', reseed, 0)
--DBCC CHECKIDENT('PiattaformeWeb.dbo.OfferteWeb_1Pass', reseed, 0)

-- ============================================== Importa CondBasePdv.csv in Tbl Ant_CondBasePdv e Cancella i duplicati in base alla data di modifica =====================================
 
--TRUNCATE TABLE I24BO.dbo.Ant_CondBasePdv -- Cancello TBL

--BULK insert I24BO.dbo.Ant_CondBasePdv from 'C:\Antonio\Pdv\FileDiImportazioneCSV\CondBasePdv.csv'

--WITH ( FIELDTERMINATOR = ';', ROWTERMINATOR = '\n', FirstRow=1) -- Inserisco i Dati Del Foglio Di Excel Di Alba nella TBL Ant_PrezziManualiExcelPdv
    
-- ============================================== Importa GestionePrezziPdv.csv in Tbl Ant_GestionePrezziPdv e Cancella i duplicati in base alla data di modifica =====================================
 
--TRUNCATE TABLE Ant_GestionePrezziPdv -- Cancello TBL

--BULK insert Ant_GestionePrezziPdv from 'C:\Antonio\PrezziPdv\FileDiImportazioneCSV\GestionePrezziPdv.csv'

--WITH ( FIELDTERMINATOR = ';', ROWTERMINATOR = '\n', FirstRow=1) -- Inserisco i Dati Del Foglio Di Excel Di Alba nella TBL Ant_PrezziManualiExcelPdv

---- Aggiorno il Campo della Marca Scritta perché ha spazi e èuò creare problemi --

--UPDATE Ant_GestionePrezziPdv
--	SET Marca = M.DESCR
--FROM Ant_GestionePrezziPdv agpp INNER JOIN
--I24BO.dbo.MARCHE M ON agpp.Marca_Id = M.id

-- ===== Rimpiazzo i MArgini con quelli del CSV ===== -- (Non serve faccio il Controllo nella Sotred dei OWB3_CreazionePrezziManuali)

--EXEC SP_AggiornaRegoleListiniPiattaformeDaCsv

----- Cancello i file dei Prezzi Ranking alla Mattina ----------------
--DELETE Ranking_07ZR
--DELETE Ranking_07ZR_Csv
--DELETE Ant_RankingTyre24
--DELETE Ant_RankingTyre24Csv

--- Per sicurezza alla mattina pulisco le 2 tabelle temporanee degl'ordini automatici
TRUNCATE TABLE TempTestaOrdiniAuto
TRUNCATE TABLE TempRigheOrdiniAuto

-- Elimino gli articoli della lista da Cancellare per 1 giorno
TRUNCATE TABLE RegoleArtEsclusioneWebOneDay

--------- Cancello Le Dimensioni e la Data dei File di Stock Per azzerare tutto alla Mattina -------
UPDATE Ant_FornPiattaforma
	SET DimensioneFile = NULL,DataFile = NULL -- File Fornitori

UPDATE FileCsvInfo
	SET DimensioneFile = NULL,DataFile = NULL -- File Listini PDV e Distribuzione

UPDATE Ant_FornRanking
	SET Art1Pos = 0,ArtTotali = 0,Perc1Pos = 0,ArtInStockCsv = 0 -- File dei Ranking

UPDATE Ant_FornPiattaformaRicambi
	SET DimensioneFile = NULL,DataFile = NULL -- File Fornitori Ricambi

----------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------

PRINT ' OK - AA0_ImpCSV_AzzeraTBL_05,30'

END

GO


