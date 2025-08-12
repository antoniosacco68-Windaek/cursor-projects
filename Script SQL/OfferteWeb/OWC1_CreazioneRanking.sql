USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[OWC1_CreazioneRanking]    Script Date: 02/07/2025 09:22:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[OWC1_CreazioneRanking]
AS
BEGIN
		-- SET NOCOUNT ON added to prevent extra result sets from
		-- interfering with SELECT statements.
		SET NOCOUNT ON;

	DECLARE @MaxOrder int
	---------------------------- Creo il Codice Articolo per le Piattaforme -----------------------------------
	 UPDATE OfferteWeb_1Pass
		SET CodArtPiatt = (CASE WHEN DOT_Forn IS NOT NULL THEN Ltrim(Rtrim(CodiceArticolo)) + '+D' + RIGHT(Rtrim(DOT_Forn), 2) ELSE Ltrim(Rtrim(CodiceArticolo)) END)
	 
	 --------------------------- Azzero il Numero di Ordine nel File Articoli e OrderB2b Nela Tbl OfferteWeb_1Pass ---------------------------------
	UPDATE B2b.dbo.Articoli
		SET Ordine = NULL

	UPDATE OfferteWeb_1Pass
		SET OrderB2b = NULL
		
	--============================================ Cancello Pubblicazione Fornitori ==========================================================================================--
	--UPDATE OfferteWeb_1Pass
	--	SET P_T24_GER = NULL
	--WHERE IdFornitore IN (3) -- Cancello da T24 Germania la pubblicazione di Univergomma

	--============================================ RANKING - POSIZIONI "PosGlobale" =======================================================================================================--

	DECLARE @files TABLE (ID int, Number int,TIdArtico int,TCodArtForn varchar(40),TIdFornitore int,TCodArtPiatt varchar(40)) -- creo la TBL Temporanea
	----------------------------- Scrivo il Ranking Globale ---------------------------
	INSERT INTO @files 
	SELECT 
		T1.IdOffWeb,T1.NumeroCodici,T1.IdArtico,T1.CodArtForn,T1.IdFornitore,CodArtPiatt
	FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt ORDER BY CodArtPiatt,(Prezzo + C_TraspBase),IdFornitore) AS [NumeroCodici],* FROM OfferteWeb_1Pass) as T1 
	ORDER BY T1.IdArtico,(T1.Prezzo + T1.C_TraspBase) ASC

	UPDATE OfferteWeb_1Pass
		SET PosGlobale = Number
	FROM @files INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb

	---------------------------- Scrivo Il Ranking del P_BASE negli Articoli Multipli per i Fornitori "TipoPubPiatt = 48H" - "Posizione" --------------------------

	DECLARE @Rank TABLE (ID int, Number int,TCodArtPiatt Varchar(40),TCodArtForn varchar(40),TIdFornitore int) -- creo la TBL Temporanea

	INSERT INTO @Rank 
		SELECT 
		T1.IdOffWeb, T1.NumeroCodici,T1.CodArtPiatt,T1.CodArtForn,T1.IdFornitore
		FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt ORDER BY CodArtPiatt,(Prezzo + C_TraspBase),IdFornitore) AS [NumeroCodici],* FROM OfferteWeb_1Pass WHERE TipoPubPiatt = '48H') as T1 
	ORDER BY T1.CodArtPiatt,(T1.Prezzo + T1.C_TraspBase) ASC

	UPDATE OfferteWeb_1Pass
		SET Posizione = Number
	FROM @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb -- AND TCodArtForn = CodArtForn AND TIdFornitore = IdFornitore
	WHERE TipoPubPiatt = '48H'

	---------------------------- Scrivo Il Ranking del P_BASE negli Articoli Multipli per i Fornitori "TipoPubPiatt = 72H" - "Posizione" --------------------------
	DELETE @Rank

	INSERT INTO @Rank 
		SELECT 
		T1.IdOffWeb,T1.NumeroCodici,T1.CodArtPiatt,T1.CodArtForn,T1.IdFornitore
		FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt ORDER BY CodArtPiatt,(Prezzo + C_TraspBase),IdFornitore) AS [NumeroCodici],* FROM OfferteWeb_1Pass WHERE TipoPubPiatt IN ('72H','72H_CST')) as T1 
	ORDER BY T1.CodArtPiatt,(T1.Prezzo + T1.C_TraspBase) ASC

	UPDATE OfferteWeb_1Pass
		SET Posizione = Number
	FROM @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb -- AND TCodArtForn = CodArtForn AND TIdFornitore = IdFornitore
	WHERE TipoPubPiatt IN ('72H','72H_CST');

	---------------------------- Scrivo Il Ranking del P_T24 negli Articoli Multipli per i Fornitori "TipoPubPiatt = Tutte" - "PosT24" (Di tutti le Pubblicazioni 24H,48H,72H Perchè Vogliono gli Articoli Univoci) --------------------------
/*	DELETE @Rank

	INSERT INTO @Rank -- Escludo DELTICOM (IDForn = 22)
		SELECT -- ===== Escludo gli Articoli sotto i 6 Pezzi di Disponibilità ===== --
			T1.IdOffWeb
		   ,T1.NumeroCodici
		   ,T1.CodArtPiatt
		   ,T1.CodArtForn
		   ,T1.IdFornitore
		FROM (SELECT
				ROW_NUMBER() OVER (PARTITION BY CodArtPiatt ORDER BY CodArtPiatt, COALESCE(P_T24_24H, P_T24_48H, P_T24_72H), TipoPubPiatt) AS [NumeroCodici]
			   ,*
			FROM OfferteWeb_1Pass
			WHERE COALESCE(P_T24_24H, P_T24_48H, P_T24_72H) IS NOT NULL
			AND IdFornitore NOT IN (22)

			AND (CASE
				WHEN SettoreId IN (4, 6, 7) AND
					IdFornitore NOT IN (4, 8) THEN Qta
				WHEN SettoreId IN (4, 6, 7) AND
					IdFornitore IN (4, 8) THEN 9 -- BGD -- PDV
				WHEN SettoreId IN (16, 91) AND
					IdFornitore IN (4, 6, 8) THEN 9
				WHEN SettoreId IN (16, 91) AND
					IdFornitore NOT IN (4, 6, 8) AND
					Qta > 2 THEN 9
				WHEN SettoreId IN (16, 91) AND
					IdFornitore NOT IN (4, 6, 8) AND
					Qta <= 2 THEN Qta
				WHEN SettoreId = 8 AND
					IdFornitore IN (4, 6, 8) THEN 9
				ELSE Qta
			END) >= 1 -- Per riattivare le limitazioni mettere il NR pezzi che si vuole prima erano 6
			) AS T1

		ORDER BY T1.CodArtPiatt, COALESCE(P_T24_24H, P_T24_48H, P_T24_72H) ASC, T1.TipoPubPiatt
*/
	-- 6. Ranking "PosT24" escludendo IdFornitore 22 e basato sui valori di T24 (24H, 48H, 72H)
	WITH RankedT24 AS (
		SELECT ROW_NUMBER() OVER (PARTITION BY CodArtPiatt 
								  ORDER BY COALESCE(P_T24_24H, P_T24_48H, P_T24_72H), TipoPubPiatt) AS NumeroCodici,
			   IdOffWeb, CodArtPiatt
		FROM OfferteWeb_1Pass
		WHERE COALESCE(P_T24_24H, P_T24_48H, P_T24_72H) IS NOT NULL
		  --AND IdFornitore NOT IN (22)
		  AND (
			  -- SettoreId 4, 6, 7 con IdFornitore 4, 6, 8 devono avere Qta > 0
			  (SettoreId IN (4, 6, 7) AND IdFornitore IN (4, 6, 8) AND Qta > 0)
			  OR
			  -- SettoreId 4, 6, 7 con IdFornitore diversi da 4, 6, 8 devono avere Qta > 0
			  (SettoreId IN (4, 6, 7) AND IdFornitore NOT IN (4, 6, 8) AND Qta > 0)
			  OR
			  -- SettoreId 16, 91 con IdFornitore 4, 6, 8 devono avere Qta > 0
			  (SettoreId IN (16, 91) AND IdFornitore IN (4, 6, 8) AND Qta > 0)
			  OR
			  -- SettoreId 16, 91 con fornitori diversi da 4, 6, 8 devono avere Qta > 0
			  (SettoreId IN (16, 91) AND IdFornitore NOT IN (4, 6, 8) AND Qta > 0)
		  )
	)
	UPDATE OfferteWeb_1Pass
	SET PosT24 = rt24.NumeroCodici
	FROM RankedT24 rt24
	WHERE OfferteWeb_1Pass.IdOffWeb = rt24.IdOffWeb;

	-- ===== Cancello gli Articoli disponibili in Casa di Dunlop Invernale ===== --
	--DELETE @Rank
	--FROM  @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb
	--WHERE Stagione = 'INVERNALE' AND MarcaId = 6 AND IdFornitore IN (4,6,8) AND DOT_Forn IS NULL
	 
	--UPDATE OfferteWeb_1Pass
	--	SET PosT24 = Number
	--FROM @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb

	-- ========== Faccio Passare Davanti al 72H il 24H e i PDV nelle Posisioni per T24 ========== --

	DELETE @Rank

	INSERT INTO @Rank -- Prendo i 72H con Posizione T24 = 1
		(ID, TCodArtPiatt, TCodArtForn, TIdFornitore)
	SELECT
		owp.IdOffWeb, owp.CodArtPiatt, owp.CodArtForn, owp.IdFornitore
	FROM OfferteWeb_1Pass owp
	WHERE owp.PosT24 = 1 AND owp.TipoPubPiatt = '72H'

	-- ===== Magazzini BGD ===== --
	UPDATE OfferteWeb_1Pass -- Incrocio i 72H con PosT24 = 1 con quelli dove ci sono i Nostri Magazzini e Passo i Nostri Magazzini come PosT24 = 1
		SET PosT24 = 1, PosGlobale = 1
	FROM  @Rank INNER JOIN OfferteWeb_1Pass owp ON TCodArtPiatt = owp.CodArtPiatt
	WHERE owp.IdFornitore IN (4,6) AND owp.Qta > 3

	UPDATE @Rank -- Mi segno nella TBL Temporanea i 72H che hanno PosT24 = 1 ed esistono gomme nei nostri Magazzini e Segno nella TBL Temporanea "Number = 2"
		SET Number = 2
	FROM  @Rank INNER JOIN OfferteWeb_1Pass owp ON TCodArtPiatt = owp.CodArtPiatt
	WHERE owp.IdFornitore IN (4,6) AND owp.Qta > 3

	-- ===== Magazzini PDV ===== --
	UPDATE OfferteWeb_1Pass -- Incrocio i 72H con PosT24 = 1 con quelli dove ci sono i Nostri Magazzini e Passo i Nostri Magazzini come PosT24 = 1
		SET PosT24 = 1, PosGlobale = 1
	FROM  @Rank INNER JOIN OfferteWeb_1Pass owp ON TCodArtPiatt = owp.CodArtPiatt
	WHERE owp.IdFornitore IN (8) AND owp.Qta > 3

	UPDATE @Rank -- Mi segno nella TBL Temporanea i 72H che hanno PosT24 = 1 ed esistono gomme nei nostri Magazzini e Segno nella TBL Temporanea "Number = 2"
		SET Number = 2
	FROM  @Rank INNER JOIN OfferteWeb_1Pass owp ON TCodArtPiatt = owp.CodArtPiatt
	WHERE owp.IdFornitore IN (8) AND owp.Qta > 3
	
	UPDATE OfferteWeb_1Pass -- Metto la PosT24 = 2 Dove i 72H avevano 1 e avevamo gomme nei nostri Magazzini
		SET PosT24 = Number, PosGlobale = Number
	FROM  @Rank INNER JOIN OfferteWeb_1Pass owp ON ID = owp.IdOffWeb
	WHERE number = 2
	
	---------------------------- Scrivo Il Ranking del P_T24_GER (che non sto usando) che uso per T24 Germania per i Fornitori "TipoPubPiatt = 24/48" - "Pos07ZR" (Di tutti le Pubblicazioni 24H,48H) Fatto perchè elimino 2 fornitori(sopra Univergoma e Francogomme e perdevamo articoli) --------------------------
	--DELETE @Rank

	--INSERT INTO @Rank 
	--	SELECT 
	--	T1.IdOffWeb,T1.NumeroCodici,T1.CodArtPiatt,T1.CodArtForn,T1.IdFornitore
	--	FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt ORDER BY CodArtPiatt,P_T24_GER,TipoPubPiatt) AS [NumeroCodici],* FROM OfferteWeb_1Pass WHERE P_T24_GER IS NOT NULL) as T1 
	--ORDER BY T1.CodArtPiatt,T1.P_T24_GER ASC,T1.TipoPubPiatt

	--UPDATE OfferteWeb_1Pass
	--	SET Pos07ZR = Number
	--FROM @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb
	
		---------------------------- Scrivo Il Ranking del P_Esteri_Ger negli Articoli Multipli per i Fornitori "TipoPubPiatt = 48/72H" - "PosEsteri" --------------------------
	DELETE @Rank

	INSERT INTO @Rank -- Uso il Prezzo P_T24_FRA per creare il Ranking
		SELECT 
		T1.IdOffWeb,T1.NumeroCodici,T1.CodArtPiatt,T1.CodArtForn,T1.IdFornitore
		FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt ORDER BY CodArtPiatt,P_T24_FRA,TipoPubPiatt) AS [NumeroCodici],* FROM OfferteWeb_1Pass WHERE P_T24_GER IS NOT NULL /*AND IdFornitore NOT IN (3)*/ ) as T1 
	ORDER BY T1.CodArtPiatt,T1.P_T24_FRA ASC,T1.TipoPubPiatt

	UPDATE OfferteWeb_1Pass
		SET PosEsteri = Number
	FROM @Rank INNER JOIN OfferteWeb_1Pass ON ID = IdOffWeb -- AND TCodArtForn = CodArtForn AND TIdFornitore = IdFornitore
	WHERE TipoPubPiatt IN ('24H','48H')
	
	---------------------------- Ordine B2b per il 24H "TipoPubPiatt = 24H" (Solo ordinamento Prezzo) --------------------------
	DELETE @files

	INSERT INTO @files 
	SELECT 
		IdOffWeb,ROW_NUMBER() OVER (ORDER BY (Prezzo + C_TraspBase)) AS Riga,IdArtico,CodArtForn,IdFornitore,CodArtPiatt
	FROM OfferteWeb_1Pass WHERE TipoPubPiatt = '24H' ORDER BY (Prezzo + C_TraspBase) ASC

	DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY TCodArtPiatt ORDER BY Number) AS [NumeroCodici],* FROM @files) as T1 
	where T1.NumeroCodici>1 -- Cancella i duplicati in ordine di data di modifica (Tiene solo il Primo Duplicato gli Altri Vengono Cancellati, quindi Ordinare in Modo che il Primo sia quello da TENERE)

	UPDATE OfferteWeb_1Pass
		SET OrderB2b = Number
	FROM @files INNER JOIN OfferteWeb_1Pass ON IdOffWeb = ID
	WHERE OrderB2b IS NULL

	UPDATE B2b.dbo.Articoli -- Passo Nella Tabella Articoli che usa il B2b l'ordinamento
		SET Ordine = Number
	FROM B2b.dbo.Articoli INNER JOIN @files ON TCodArtPiatt = CodiceArticolo
	WHERE Ordine IS NULL

	---------------------------- Ordine B2b per il 48/72H (Ordinamento Marche (Nostri Brand), + Ordinamento Prezzo) --------------------------

	----------- Tutti quelli che non hanno il Campo OrderB2b Compilato (ho fatto solo il 24H prima quindi 48/72H) non MOTO/SCOOTER

	SET @MaxOrder = (SELECT MAX(OrderB2b) FROM OfferteWeb_1Pass) -- Numero Max dell campo "OrdineB2b" Creato fino ad ora

	DELETE @files

	INSERT INTO @files 
	SELECT 
		IdOffWeb,@MaxOrder + ROW_NUMBER() OVER (ORDER BY (Prezzo + C_TraspBase)) AS Riga,IdArtico,CodArtForn,IdFornitore,CodArtPiatt
	FROM OfferteWeb_1Pass WHERE MarcaId IN (104,57,7,15,10160,105) AND SettoreId IN (4,6,7,8,76,37) AND OrderB2b IS NULL -- Toyo(104) - Barum(57) - Continental(7) - Yokohama(15) - Atlas(10160) - GtRadial(105)
	ORDER BY (Prezzo + C_TraspBase) ASC

	DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY TCodArtPiatt ORDER BY Number) AS [NumeroCodici],* FROM @files) as T1 
	where T1.NumeroCodici>1 -- Cancella i duplicati in ordine di data di modifica (Tiene solo il Primo Duplicato gli Altri Vengono Cancellati, quindi Ordinare in Modo che il Primo sia quello da TENERE)

	UPDATE OfferteWeb_1Pass
		SET OrderB2b = Number
	FROM @files INNER JOIN OfferteWeb_1Pass ON IdOffWeb = ID
	WHERE OrderB2b IS NULL

	UPDATE B2b.dbo.Articoli -- Passo Nella Tabella Articoli che usa il B2b l'ordinamento
		SET Ordine = Number
	FROM B2b.dbo.Articoli INNER JOIN @files ON TCodArtPiatt = CodiceArticolo
	WHERE Ordine IS NULL

	---------------------------- Ordine B2b per il 48/72H "TipoPubPiatt = 24H/48H" (Ordinamento Marche (Esclusi nostri Brand), + Ordinamento Prezzo) --------------------------

	----------- 48H/72H MOTO/SCOOTER + Articoli non ancora Segnati (Campo OrderB2b Vuoto)

	SET @MaxOrder = (SELECT MAX(OrderB2b) FROM OfferteWeb_1Pass) -- Numero Max dell campo "OrdineB2b" Creato fino ad ora

	DELETE @files

	INSERT INTO @files 
	SELECT 
		IdOffWeb,@MaxOrder + ROW_NUMBER() OVER (ORDER BY (Prezzo + C_TraspBase)) AS Riga,IdArtico,CodArtForn,IdFornitore,CodArtPiatt
	FROM OfferteWeb_1Pass WHERE OrderB2b IS NULL --
	ORDER BY (Prezzo + C_TraspBase)
	
	DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY TCodArtPiatt ORDER BY Number) AS [NumeroCodici],* FROM @files) as T1 
	where T1.NumeroCodici>1 -- Cancella i duplicati in ordine di data di modifica (Tiene solo il Primo Duplicato gli Altri Vengono Cancellati, quindi Ordinare in Modo che il Primo sia quello da TENERE)
	
	UPDATE OfferteWeb_1Pass
		SET OrderB2b = Number
	FROM @files INNER JOIN OfferteWeb_1Pass ON IdOffWeb = ID
	WHERE OrderB2b IS NULL

	UPDATE B2b.dbo.Articoli -- Passo Nella Tabella Articoli che usa il B2b l'ordinamento
		SET Ordine = Number
	FROM B2b.dbo.Articoli INNER JOIN @files ON TCodArtPiatt = CodiceArticolo
	WHERE Ordine IS NULL	
	
	------- Aggiorno quelli rimasti fuori dalla Tabella Offerte per per il Delete dei duplicati che ho messo prima ------
	
	UPDATE OfferteWeb_1Pass
		SET OrderB2b = Ordine
	FROM B2b.dbo.Articoli INNER JOIN OfferteWeb_1Pass ON Articoli.CodiceArticolo = CodArtPiatt
	WHERE OrderB2b IS NULL
	
---------- Cancello Alcuni Articoli Doppi del Fornitore (CodArtPiatt,IdFornitore sono le chiavi) --------------------------

	DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CodArtPiatt,IdFornitore ORDER BY CodArtPiatt,IdFornitore,Posizione) AS [NumeroCodici],* FROM OfferteWeb_1Pass) as T1 
	WHERE T1.NumeroCodici>1

	-- ======================================================================================================= --
	-- ===== Cancello gli Articoli disponibili in Casa che non vogliamo Passare modificando la POSIZIONE ===== --
	-- ======================================================================================================= --

	/*	SOSPESO 20-02-25

	DELETE @Rank

	-- Inserisco tutti gli Articoli in 1 Posizione di T24 di Marca Goodyear --
	INSERT INTO @Rank 
		(ID, Number,TIdFornitore)
	SELECT
		ow.IdOffWeb, ow.PosT24, ow.IdFornitore
	FROM OfferteWeb_1Pass ow
	WHERE ow.MarcaId = 3 AND ow.PosT24 IN (1,2) -- Marca Goodyear

	-- Prendo tutte le GOODYEAR IN magazzino da noi e le passo come POSIZIONE 2 se erano in 1 Posizione su T24 --
	UPDATE OfferteWeb_1Pass
		SET PosT24 = 2
	FROM @Rank r INNER JOIN OfferteWeb_1Pass ow ON r.ID = ow.IdOffWeb AND ow.IdFornitore IN (4,6,8) AND r.Number = 1

	-- Prendo tutte le GOODYEAR NON in magazzino da noi e le passo come POSIZIONE 1 se erano in 2 Posizione su T24 --
	UPDATE OfferteWeb_1Pass
		SET PosT24 = 1
	FROM @Rank r INNER JOIN OfferteWeb_1Pass ow ON r.ID = ow.IdOffWeb AND ow.IdFornitore NOT IN (4,6,8) AND r.Number = 2

	*/

	-- ========================================================================================================= --

END

