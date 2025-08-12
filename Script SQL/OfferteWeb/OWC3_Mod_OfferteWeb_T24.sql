USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[OWC3_Mod_OfferteWeb_T24]    Script Date: 02/07/2025 09:40:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[OWC3_Mod_OfferteWeb_T24]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-------------------------- Cancello gli Articoli Autocarro perché esclusi dal Ranking ------------------------------------------------------
DELETE Ant_RankingTyre24 
FROM OfferteWeb_1Pass 
INNER JOIN Ant_RankingTyre24 ON Ltrim(Rtrim(Codice)) = Ltrim(Rtrim(CodArtPiatt))
WHERE SettoreId = '8'
---------------------------------------------- Inizio Elaborazione -------------------------------------------------------------------------
DECLARE @SettVettura varchar(20) = '(4,6,7,76,37)',@SettAutocarro varchar(20) = '(8)',@SettMotoScoot varchar(20) = '(16,91)',@Sql varchar(1000),@NstriMag48H varchar(20) = '(6,8)'

----------------------------- Faccio Prezzo Minimo/Massimo 24H -----------------------------
SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_24H - [M-T24],P_Max_T24 = P_T24_24H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''24H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''Vettura''
WHERE Ranking = ''24H'' AND SettoreId IN ' + @SettVettura + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND TipoPubPiatt = ''24H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_24H - [M-T24],P_Max_T24 = P_T24_24H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''24H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''MotoScooter''
WHERE Ranking = ''24H'' AND SettoreId IN ' + @SettMotoScoot + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND TipoPubPiatt = ''24H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

----------------------------- Faccio Prezzo Minimo/Massimo 48H Per i Nostri Articoli Messi in 48H (Pdv,Logistica) ----------------------------------------------------------------------------------------------

/*  Spedifico per i nostri 2 Magazzini che vanno nel 48H ma hanno il listino 24H IdFornitore (6,8) */

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_48H - [M-T24],P_Max_T24 = P_T24_48H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''24H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''Vettura''
WHERE Ranking = ''48H'' AND SettoreId IN ' + @SettVettura + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND IdFornitore IN ' + @NstriMag48H + ' AND TipoPubPiatt = ''48H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_48H - [M-T24],P_Max_T24 = P_T24_48H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''24H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''MotoScooter''
WHERE Ranking = ''48H'' AND SettoreId IN ' + @SettMotoScoot + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND IdFornitore IN ' + @NstriMag48H + ' AND TipoPubPiatt = ''48H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

-------------------------------------------------------- Prezzo Magazzini 48H ESCLUSI i Nostri ------------------------------------------------------------------------------------

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli in cui siamo Primi 
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_48H - [M-T24],P_Max_T24 = P_T24_48H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''48H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''Vettura''
WHERE Ranking = ''48H'' AND SettoreId IN ' + @SettVettura + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND IdFornitore NOT IN ' + @NstriMag48H + ' AND TipoPubPiatt = ''48H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli in cui siamo Primi 
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_48H - [M-T24],P_Max_T24 = P_T24_48H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''48H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''MotoScooter''
WHERE Ranking = ''48H'' AND SettoreId IN ' + @SettMotoScoot + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND IdFornitore NOT IN ' + @NstriMag48H + ' AND TipoPubPiatt = ''48H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

----------------------------- Faccio Prezzo Minimo/Massimo 72H -----------------------------

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli in cui siamo Primi 
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_72H - [M-T24],P_Max_T24 = P_T24_72H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''72H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''Vettura''
WHERE Ranking = ''72H'' AND SettoreId IN ' + @SettVettura + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND TipoPubPiatt = ''72H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

SET @Sql = 'UPDATE OfferteWeb_1Pass -- Metto i Campi come preferisco negli articoli in cui siamo Primi 
	SET P_1Pos_T24 = Round(MigliorPrezzo,2),P_Min_T24 = P_T24_72H - [M-T24],P_Max_T24 = P_T24_72H + [M+T24],P_Prec_T24 = NostroPrezzo,Diff_T24 = Ant_RankingTyre24.Differenza,
PosPrec_T24 = Ant_RankingTyre24.Posizione
FROM PiattaformeWeb.dbo.Ant_RankingTyre24
INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice
INNER JOIN RegoleListiniPiatt ON TipoListForn = ''72H'' AND NomeListino = ''TYRE24'' AND RegoleListiniPiatt.Settore = ''MotoScooter''
WHERE Ranking = ''72H'' AND SettoreId IN ' + @SettMotoScoot + ' AND Prezzo BETWEEN CifraIn AND CifraOut AND TipoPubPiatt = ''72H'' ' -- INNER JOIN OfferteWeb_1Pass ON CodArtPiatt = Codice AND OfferteWeb_1Pass.Posizione = 1

EXECUTE (@Sql)

--==================================== PER TUTTI i RECORD ====================================--
DECLARE @RicaricoMinimo int = 5,@DiffPer1Pos FLOAT = 0.01
---==================================== AGGIORNO LE NOTE =====================================---
-------------------- Metto il PrezzoMinimo nel PrezzoRicalcolato per Tutti gli Articoli -------------------

UPDATE OfferteWeb_1Pass
	SET P_Ricalc_T24 = P_Min_T24
WHERE P_Min_T24 > Prezzo + @RicaricoMinimo -- Controllo che almeno ci siano 5€ di Ricarico giusto per non creare errori ecclatanti ...

-- Aggiorno il PrezzoRicalcolato con quelli che Rientrano con il nostro "PrezzoPer1Pos" fra PrezzoMinimo/PrezzoMassimo
--(Ci rientrano anche quelli dove eravamo primi se non ci è cambiato il Prezzo di acquisto,altrimenti hanno preso il Prezzo Minimo)

UPDATE OfferteWeb_1Pass -- Non in 1 Posizione (P_Prec_T24 > P_1Pos_T24) e Prezzo 1 Poszione (P_1Pos_T24) Beetwen Minimo e Massimo 
	SET P_Ricalc_T24 = (CASE WHEN P_Prec_T24 > P_1Pos_T24 THEN P_1Pos_T24 - @DiffPer1Pos ELSE P_Prec_T24 END) -- Metto come PrezzoRicalcolato il Prezzo della 1 Posizione - @DiffPer1Pos
WHERE P_1Pos_T24 BETWEEN P_Min_T24 AND P_Max_T24 AND P_1Pos_T24 > Prezzo + @RicaricoMinimo

UPDATE OfferteWeb_1Pass  -- 1 Poszizione (P_Prec_T24 = P_1Pos_T24) e Prezzo 1 Poszione (P_1Pos_T24) Beetwen Minmo e Massimo 
	SET P_Ricalc_T24 = IsNull((CASE WHEN P_Prec_T24 = P_1Pos_T24 THEN P_1Pos_T24 END),P_Ricalc_T24) -- Metto come PrezzoRicalcolato il Prezzo della P_1Pos_T24 che è uguale al nostro
WHERE P_1Pos_T24 BETWEEN P_Min_T24 AND P_Max_T24 AND P_1Pos_T24 > Prezzo + @RicaricoMinimo

UPDATE OfferteWeb_1Pass  -- Prezzo 1 Poszione (P_1Pos_T24) Maggiore del Prezzo Massimo (Capita solo quando siamo 1° e rifacendo il Prezzo cala quindi va oltre il prezzo che avevamo prima)
	SET P_Ricalc_T24 = P_Max_T24 -- Metto come PrezzoRicalcolato il P_Max_T24 che è più Basso del nostro Precedente Prezzo.
WHERE P_1Pos_T24 > P_Max_T24

UPDATE OfferteWeb_1Pass
	SET Note_T24_Rank = 'AggPrezAuto(' + CAST(P_Ricalc_T24 AS VARCHAR(10)) + ') - PosPrec(' + Ltrim(Rtrim(PosPrec_T24)) + ') - PrezPreced.(' + CAST(P_Prec_T24 AS VARCHAR(10)) + ') - PrezBasePiatt.(' + CAST(Coalesce(P_T24_24H,P_T24_48H,P_T24_72H) AS VARCHAR(10)) + ') - Prezzo Min/Max(' + CAST(P_Min_T24 AS VARCHAR(10)) + '/' + CAST(P_Max_T24 AS VARCHAR(10)) + ')' + ' - 1°PrezPiatt(' + CAST(P_1Pos_T24 AS varchar(10)) + ')' -- Aggiornamento Prezzo Automatico

---=================================== AGGIORNO il PREZZO su OfferteWeb_1Pass ====================================

UPDATE OfferteWeb_1Pass -- Solo per gli Articoli in cui non siamo PRIMI
	SET P_T24_24H = Coalesce(PrezzoManT24, P_Ricalc_T24)
WHERE TipoPubPiatt = '24H' AND Coalesce(PrezzoManT24, P_Ricalc_T24) IS NOT NULL

UPDATE OfferteWeb_1Pass -- Solo per gli Articoli in cui non siamo PRIMI
	SET P_T24_48H = P_Ricalc_T24
WHERE TipoPubPiatt = '48H' AND P_Ricalc_T24 IS NOT NULL

UPDATE OfferteWeb_1Pass -- Solo per gli Articoli in cui non siamo PRIMI
	SET P_T24_48H = Coalesce(PrezzoManT24, P_Ricalc_T24)
WHERE TipoPubPiatt = '48H' AND Coalesce(PrezzoManT24, P_Ricalc_T24) IS NOT NULL AND IdFornitore IN (6,8) -- Prezzo MAnuale sui nostri Magazzini PDV e LDC

UPDATE OfferteWeb_1Pass -- Solo per gli Articoli in cui non siamo PRIMI
	SET P_T24_72H = P_Ricalc_T24
WHERE TipoPubPiatt = '72H' AND P_Ricalc_T24 IS NOT NULL

---=================================== AGGIORNO il PREZZO Manuale su OfferteWeb_1Pass ====================================


PRINT 'OK - [AD3_Mod_OfferteWeb_PrezziT24]'

END


