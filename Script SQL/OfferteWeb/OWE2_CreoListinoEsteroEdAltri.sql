USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[OWE2_CreoListinoEsteroEdAltri]    Script Date: 02/07/2025 09:51:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================================================================================
-- Author:		<Sacco,,Antonio>
-- Create date: <04-10-2015>
-- Description:	<Listini Automatici Piattaforme e PDV>
-- Qui decide quali Magazzini delle Nostre Gomme Pubblicare !!!!
-- =======================================================================================================================================
ALTER PROCEDURE [dbo].[OWE2_CreoListinoEsteroEdAltri]

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @AggiuntaPerc decimal(6,2) = 1.10, @AggiuntaEuro decimal(6,2) = 0, @ScontoVettura DECIMAL(6,2) = 1, @ScontoMoto DECIMAL(6,2) = 1.5, @ScontoPrezMan DECIMAL(6,2) = 0.5
	DECLARE @PfuMotoFrancia Float = 0,@PfuVettFrancia Float = 0, @Addx07ZR DECIMAL(6,2) = 0 -- Commissioni 07ZR più alte di T24
	DECLARE @ProvvPiattPerc decimal (4,3) = 1.013

	-- ===== Prezzo Esteri 48H VETTURA ===== --
	UPDATE OfferteWeb_1Pass
		SET P_Esteri_Ger = P_T24_GER / @ProvvPiattPerc,
		P_Esteri_Spa = P_T24_SPA / @ProvvPiattPerc,
		P_Esteri_Aus = P_T24_AUS / @ProvvPiattPerc
	WHERE TipoPubPiatt IN ('24H','48H')
	AND P_T24_AUS IS NOT NULL
	AND SettoreId IN (4,6,7,8,76,37)

	-- ===== Prezzo Esteri 48H MOTO ===== --
	UPDATE OfferteWeb_1Pass
		SET P_Esteri_Ger = P_T24_GER / @ProvvPiattPerc,
		P_Esteri_Spa = P_T24_SPA / @ProvvPiattPerc,
		P_Esteri_Aus = P_T24_AUS / @ProvvPiattPerc
	WHERE TipoPubPiatt IN ('24H','48H')
	AND P_T24_AUS IS NOT NULL
	AND SettoreId IN (16,91)

	-- ===== Prezzo Piattaforma Cont Trasporto + Clienti Senza Trasporto VETTURA ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_24H / @ProvvPiattPerc,
		P_GommeAuto = (P_T24_24H / @ProvvPiattPerc) - C_TraspT24,
		P_PiattSenzaTrasp = (P_T24_24H  / @ProvvPiattPerc) - C_TraspT24
	WHERE TipoPubPiatt = '24H'
	AND SettoreId IN (4,6,7,8,76,37)

	-- ===== Prezzo Piattaforma Cont Trasporto + Clienti Senza Trasporto MOTO ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_24H / @ProvvPiattPerc,
		P_GommeAuto = (P_T24_24H / @ProvvPiattPerc) - C_TraspT24,
		P_PiattSenzaTrasp =(P_T24_24H / @ProvvPiattPerc) - C_TraspT24
	WHERE TipoPubPiatt = '24H'
	AND SettoreId IN (16,91)

	-- ===== Prezzo Piattaforma Cont Trasporto + Clienti Senza Trasporto VETTURA ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_48H / @ProvvPiattPerc,
		P_GommeAuto = (P_T24_48H / @ProvvPiattPerc) - C_TraspT24,
		P_PiattSenzaTrasp = (P_T24_48H / @ProvvPiattPerc) - C_TraspT24
	WHERE TipoPubPiatt = '48H'
	AND SettoreId IN (4,6,7,8,76,37)

	-- ===== Prezzo Piattaforma Cont Trasporto + Clienti Senza Trasporto MOTO ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_48H / @ProvvPiattPerc,
		P_GommeAuto = (P_T24_48H / @ProvvPiattPerc) - C_TraspT24,
		P_PiattSenzaTrasp = (P_T24_48H / @ProvvPiattPerc) - C_TraspT24
	WHERE TipoPubPiatt = '48H'
	AND SettoreId IN (16,91)

	-- ===== Non Tolgo il Trasporto Perchè questi Fornitori hanno il prezzo comprensivo di trasporto VETTURA ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_72H / @ProvvPiattPerc,
		P_GommeAuto = P_T24_72H / @ProvvPiattPerc, -- Gommeauto Con Trasporto sul 72H
		P_PiattSenzaTrasp = P_T24_72H / @ProvvPiattPerc -- niente tohgliere trasporto perché nel 72H non c'è
	WHERE TipoPubPiatt = '72H'
	AND SettoreId IN (4,6,7,8,76,37)

	UPDATE OfferteWeb_1Pass -- Non Tolgo il Trasporto Perchè questi Fornitori hanno il prezzo comprensivo di trasporto
		SET P_PiattConTrasp = P_T24_72H / @ProvvPiattPerc,
		P_GommeAuto = P_T24_72H / @ProvvPiattPerc, -- Gommeauto Con Trasporto sul 72H
		P_PiattSenzaTrasp = (P_T24_72H / @ProvvPiattPerc) - C_TraspBase -- tohgliere trasporto perché nel 72H_CST c'è il Trasporto
	WHERE TipoPubPiatt = '72H_CST'
	AND SettoreId IN (4,6,7,8,76,37)

	-- ===== Non Tolgo il Trasporto Perchè questi Fornitori hanno il prezzo comprensivo di trasporto MOTO ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_PiattConTrasp = P_T24_72H / @ProvvPiattPerc,
		P_GommeAuto = P_T24_72H / @ProvvPiattPerc, -- Gommeauto Con Trasporto sul 72H
		P_PiattSenzaTrasp = P_T24_72H / @ProvvPiattPerc -- niente tohgliere trasporto perché nel 72H non c'è
	WHERE TipoPubPiatt = '72H'
	AND SettoreId IN (16,91)

	UPDATE OfferteWeb_1Pass -- Non Tolgo il Trasporto Perchè questi Fornitori hanno il prezzo comprensivo di trasporto
		SET P_PiattConTrasp = P_T24_72H / @ProvvPiattPerc,
		P_GommeAuto = P_T24_72H / @ProvvPiattPerc, -- Gommeauto Con Trasporto sul 72H
		P_PiattSenzaTrasp = (P_T24_72H / @ProvvPiattPerc) - C_TraspBase -- tohgliere trasporto perché nel 72H_CST c'è il Trasporto
	WHERE TipoPubPiatt = '72H_CST'
	AND SettoreId IN (16,91)

	-----------------------------------------------------------------------------------------------------------------------
	
	-- ===== Prezzo 07ZR + Note_T24 VETTURA ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_07ZR_24H = Ow.P_T24_24H + @Addx07ZR,
		P_07ZR_48H = P_T24_48H + @Addx07ZR,
		P_07ZR_72H = P_T24_72H + @Addx07ZR,
		P_07ZR_FRA = Ow.P_T24_FRA + @Addx07ZR + (CASE WHEN SettoreId IN (16,91) THEN @PfuMotoFrancia ELSE @PfuVettFrancia END), -- Aggiungo il PFU per la Francia perché dopo viene Tolto da 07ZR e Fatturato a noi a Fine Mese
		P_07ZR_GER = Ow.P_T24_GER + @Addx07ZR,
		P_07ZR_SPA = Ow.P_T24_SPA + @Addx07ZR,
		P_07ZR_AUS = Ow.P_T24_AUS + @Addx07ZR,
		P_07ZR_POR = (Prezzo + M_T24 + (CASE SettoreId WHEN 8 THEN NULL ELSE Bcs.Z34 END)) * @ProvvPiattPerc,
		P_07ZR_Uk_Danim = Ow.P_T24_Uk_Danim + @Addx07ZR
	FROM OfferteWeb_1Pass Ow INNER JOIN
	BestCosti_Sped Bcs ON Bcs.Misura = Ow.Misura AND Bcs.Settore_Id = Ow.SettoreId
	WHERE Ow.SettoreId IN (4,6,7,8,76,37)

	-- ===== Prezzo 07ZR + Note_T24 MOTO ===== --
	UPDATE OfferteWeb_1Pass 
		SET P_07ZR_24H = Ow.P_T24_24H + @Addx07ZR,
		P_07ZR_48H = P_T24_48H + @Addx07ZR,
		P_07ZR_72H = P_T24_72H + @Addx07ZR,
		P_07ZR_FRA = Ow.P_T24_FRA + @Addx07ZR + (CASE WHEN SettoreId IN (16,91) THEN @PfuMotoFrancia ELSE @PfuVettFrancia END), -- Aggiungo il PFU per la Francia perché dopo viene Tolto da 07ZR e Fatturato a noi a Fine Mese
		P_07ZR_GER = Ow.P_T24_GER + @Addx07ZR,
		P_07ZR_SPA = Ow.P_T24_SPA + @Addx07ZR,
		P_07ZR_AUS = Ow.P_T24_AUS + @Addx07ZR,
		P_07ZR_POR = (Prezzo + M_T24 + (CASE SettoreId WHEN 8 THEN NULL ELSE Bcs.Z34 END)) * @ProvvPiattPerc,
		P_07ZR_Uk_Danim = Ow.P_T24_Uk_Danim + @Addx07ZR
	FROM OfferteWeb_1Pass Ow INNER JOIN
	BestCosti_Sped Bcs ON Bcs.Misura = Ow.Misura AND Bcs.Settore_Id = Ow.SettoreId
	WHERE Ow.SettoreId IN (16,91)

	-- ===== Prezzo B2b ===== --

	UPDATE OfferteWeb_1Pass
		SET P_Base = P_PiattSenzaTrasp,
		P_BaseBo = P_PiattSenzaTrasp,
		P_Top = P_PiattSenzaTrasp,
		P_TopBo = P_PiattSenzaTrasp,
		P_StdBo = P_PiattSenzaTrasp,
		P_Std = P_PiattSenzaTrasp

	UPDATE OfferteWeb_1Pass
		SET Differenza = P_Base - Prezzo

	-- ====================================================================================== --
	-- ===== Script per Aggingere EURO o PERCENTUALE in base alla Marca e alla Stagione ===== --
	-- ====================================================================================== --

	--UPDATE OfferteWeb_1Pass
	--	SET P_T24_24H = P_T24_24H * @AggiuntaPerc, P_T24_GER = P_T24_GER * @AggiuntaPerc, P_T24_SPA = P_T24_SPA * @AggiuntaPerc, P_T24_AUS = P_T24_AUS * @AggiuntaPerc, P_T24_BEL = P_T24_BEL * @AggiuntaPerc, P_T24_LUS = P_T24_LUS * @AggiuntaPerc, P_T24_FRA = P_T24_FRA * @AggiuntaPerc, P_T24_OLA = P_T24_OLA * @AggiuntaPerc, P_T24_POL = P_T24_POL * @AggiuntaPerc,
	--	P_07ZR_24H = P_07ZR_24H * @AggiuntaPerc, P_07ZR_FRA = P_07ZR_FRA * @AggiuntaPerc, P_07ZR_GER = P_07ZR_GER * @AggiuntaPerc, P_07ZR_SPA = P_07ZR_SPA * @AggiuntaPerc, P_07ZR_AUS = P_07ZR_AUS * @AggiuntaPerc, P_07ZR_POR = P_07ZR_POR * @AggiuntaPerc, P_PiattConTrasp = P_PiattConTrasp * @AggiuntaPerc, P_PiattSenzaTrasp = P_PiattSenzaTrasp * @AggiuntaPerc,P_GommeAuto = P_GommeAuto * @AggiuntaPerc
	--WHERE IdFornitore IN (4,6,8) AND Produttore in ('Goodyear','Dunlop') AND Stagione IN ('invernale','4 STAGIONI')

	--UPDATE OfferteWeb_1Pass
	--	SET P_T24_24H = P_T24_24H + @AggiuntaEuro, P_T24_GER = P_T24_GER + @AggiuntaEuro, P_T24_SPA = P_T24_SPA + @AggiuntaEuro, P_T24_AUS = P_T24_AUS + @AggiuntaEuro, P_T24_BEL = P_T24_BEL + @AggiuntaEuro, P_T24_LUS = P_T24_LUS + @AggiuntaEuro, P_T24_FRA = P_T24_FRA + @AggiuntaEuro, P_T24_OLA = P_T24_OLA + @AggiuntaEuro, P_T24_POL = P_T24_POL + @AggiuntaEuro,
	--	P_07ZR_24H = P_07ZR_24H + @AggiuntaEuro, P_07ZR_FRA = P_07ZR_FRA + @AggiuntaEuro, P_07ZR_GER = P_07ZR_GER + @AggiuntaEuro, P_07ZR_SPA = P_07ZR_SPA + @AggiuntaEuro, P_07ZR_AUS = P_07ZR_AUS + @AggiuntaEuro, P_07ZR_POR = P_07ZR_POR + @AggiuntaEuro, P_PiattConTrasp = P_PiattConTrasp + @AggiuntaEuro, P_PiattSenzaTrasp = P_PiattSenzaTrasp + @AggiuntaEuro,P_GommeAuto = P_GommeAuto + @AggiuntaEuro
	--WHERE IdFornitore IN (4,6,8) AND Produttore in ('Imperial') AND Stagione IN ('invernale','4 STAGIONI') and PrezzoManT24 is NULL

	--================================================================================================================
	--=================== Aggiorno il Numero di Articoli in Stock nella TBL "Ant_FornPiattaforma"  ===================
	--================================================================================================================

	DECLARE @IdForn int,@ArtInStock int,@ArtTotali INT

	UPDATE Ant_FornPiattaforma
		SET ArtInStockCsv = 0,Art1Pos = 0,ArtTotali = 0,Perc1Pos = 0

	Declare CursStock cursor for select IdForPiatt from Ant_FornPiattaforma WHERE AttivaFerie = 0
	open CursStock
		fetch next from CursStock into @IdForn
		WHILE @@FETCH_STATUS = 0
		begin
			
			SET @ArtInStock = (SELECT COUNT(*) FROM OfferteWeb_1Pass WHERE IdFornitore = @IdForn)
			
			-- Articoli in Stock
			UPDATE Ant_FornPiattaforma
				SET ArtInStockCsv = @ArtInStock
			WHERE IdForPiatt = @IdForn

			-- Articoli in 1 posizione
			UPDATE Ant_FornPiattaforma
				SET Art1Pos = (SELECT COUNT(IdOffWeb) FROM OfferteWeb_1Pass WHERE IdFornitore = @IdForn AND PosGlobale = 1)
			WHERE IdForPiatt = @IdForn

			-- Percentuale Articoli in 1 pos
			UPDATE Ant_FornPiattaforma
				SET Perc1Pos = (Art1Pos * 100) / ArtInStockCsv
			WHERE ArtInStockCsv > 0

			fetch next from CursStock into @IdForn
		end

	close CursStock
	deallocate CursStock

	--============================================ Controllo gli Articoli nello Stock dei Fornitori ==========================================================================================

	EXEC ControlloStockImportatiFornitori -- Se il numero degli articoli nello stock del fornitore e inferiore al Minimo che ho inserito manda email

	-- ================================================================================================================================================================== --
	-- ======================= Se ci sono meno di 4 Pezzi in BGD (Id Fornitore 4) e > 0 PDV (IdFornitore 8) li Sommo e li metto tutti in PDV 48H  ======================= --
	-- ================================================================================================================================================================== --

	DECLARE @FusioneBgdPdv TABLE (ID INT IDENTITY(1,1), IdOffWebBgd INT, IdOffWePdv INT, QtaBgd INT )

	-- ===== Salvo gli Articoli che hanno le caratteristiche del filtro per poterli cambiare ===== --

	INSERT INTO @FusioneBgdPdv -- IdFornitore 4 = BGD, IdFornitore 8 = PDV
		(IdOffWebBgd, IdOffWePdv, QtaBgd)
	SELECT owp.IdOffWeb,Pdv.IdOffWebPdv, owp.Qta
	FROM OfferteWeb_1Pass owp OUTER APPLY
	(SELECT owp1.Qta AS QtaPdv, owp1.IdOffWeb AS IdOffWebPdv, owp1.PosEsteri
		FROM OfferteWeb_1Pass owp1 WHERE owp1.IdArtico = owp.IdArtico AND owp1.IdFornitore = 8 AND owp1.Qta > 0) AS Pdv
	WHERE (owp.PosT24 = 1 OR owp.PosT24 = 1) AND owp.IdFornitore = 4 AND owp.Qta < 4 AND Pdv.QtaPdv > 0 AND owp.SettoreId NOT IN (16,91)

	UPDATE OfferteWeb_1Pass -- Aggiorno i Dati della Riga BGD
		SET PosEsteri = 99, PosT24 = 99, Qta = 0
	FROM OfferteWeb_1Pass owp INNER JOIN
	@FusioneBgdPdv ON owp.IdOffWeb = IdOffWebBgd

	UPDATE OfferteWeb_1Pass -- Aggiorno i Dati della Riga PDV
		SET PosEsteri = 1, PosT24 = 1, Qta = owp.Qta + QtaBgd, PosGlobale = 1
	FROM OfferteWeb_1Pass owp INNER JOIN
	@FusioneBgdPdv ON owp.IdOffWeb = IdOffWePdv

	--================================================================================================================
	--=================== Abbasso la Qta degli articoli metto il tetto di 20 pezzi se sono di più  ===================
	--================================================================================================================

	UPDATE OfferteWeb_1Pass
		SET Qta = 30
	WHERE Qta > 30

END


