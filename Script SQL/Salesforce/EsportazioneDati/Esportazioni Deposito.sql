USE I24DB

-- ===== Tabella Temp con Id da cercare per portare dentro le Anagrafiche e i vari dati correlati fra loro ===== --

DECLARE @Id TABLE
(
			IdDep	int,
			IdAna	int,
			IdVeic	int,
			IdScLav	int
)

-- Popolo la Tbl Temporanea degli ID --

INSERT INTO @Id (IdDep, IdAna, IdVeic, IdScLav)
	   SELECT TOP 100 d.IdDeposito, d.D_IdAnagrafica, d.D_IdVeicolo, d.D_IdSchedaLavoro
	   FROM Deposito d
	   WHERE d.D_TipoDepositoR2 IS NOT NULL
		AND LEN(LTRIM(RTRIM(d.D_ArtCodice)))> 4
		AND LEN(LTRIM(RTRIM(d.D_ArtCodicePost)))> 4
		AND CAST(d.Data AS date) <= '10-06-25'
	   ORDER BY d.IdDeposito DESC


-- ===== Veicolo ===== --
SELECT v.IdVeicolo, v.V_IdAnagrafica, v.TipologiaVeicolo, v.Targa, v.Marca, v.Modello, v.V_LeasingCompany, v.N_Telaio, v.V_Archiviato, v.V_TipoPneumLc, v.V_Note, v.V_Tpms, v.V_PortaleLeasing, v.V_NCabina, v.V_ScadRevisione, v.Cilindrata, v.Kilowatt, v.CodiceMotore, v.DataImmatricolazione, v.DataUltimaRev, v.RagioneSocialeRev, v.NomeRev, v.CognomeRev, v.CellulareRev, v.EmailRev, v.IndirizzoRev, v.CapRev, v.ProvinciaRev, v.CittaRev, v.PromemoriaScadTipoInvio, v.V_NoMozzi, v.V_ScadBombole
FROM Veicolo v
	 INNER JOIN
	 @Id
	 ON IdVeic = v.IdVeicolo

-- ===== Prodotti ===== --

---- ===== Commessa ===== --
--SELECT s.IdSchedaLavoro, s.S_IdAnagrafica, s.S_IdVeicolo, s.Pdv, s.Km, s.Data_Lavori, s.S_ConfImpPneumatici, s.OreMeccanicaReali, s.S_NImpPneumatici, s.CodCli_LC_FatturaBolla, s.S_TipoPagamento, s.Note_Stampa, s.Operatore, s.Note, s.S_Targa, s.Stato_Commessa, s.Importo, s.Problemi, s.Urgente, s.S_IdPreventivo, s.S_Promozione, s.S_UsuraFreniAnt, s.S_UsuraFreniPost, s.S_NScontrino, s.S_NFattura, s.S_NRichiestaLc, s.S_BGR, s.S_NBGR, s.S_NBolla, s.S_TPMS, s.S_ODL, s.S_NReport, s.S_DataCreazDocVen, s.S_UsuraDischiAnt, s.S_UsuraDischiPost, s.S_NoMozzi, s.S_Reparto, s.S_OffMeccEsterna, s.Autista, s.S_RespCommessa
--FROM SchedaLavoro s
--	 INNER JOIN
--	 @Id
--	 ON IdScLav = s.IdSchedaLavoro

---- ===== Articoli Commessa ===== --
--SELECT ar.Art_IdSchedaLavoro, ar.Art_IdVeicolo, ar.Art_IdArtico, ar.Art_Codice, ar.Art_Qta, ar.Art_DOT, ar.Art_PrezzoUnit AS PrezzoUnitImp, ar.Art_PrezzoRigaImp AS PrezzoRigaImp, ar.Art_Prezzo AS PrezzoTotIc, ar.Art_Fascia AS Fascia, ar.Art_LottoForzato AS LottoForzato
--FROM ArtSchedaLavoro ar
--	 INNER JOIN
--	 @Id
--	 ON IdScLav = ar.Art_IdSchedaLavoro

-- ===== Movimentazione Pneumatico ===== --
SELECT d.IdDeposito AS External_Id, d.D_IdVeicolo, d.D_IdAnagrafica, (CASE WHEN d.D_IdSchedaLavoro = 0 THEN (SELECT d1.D_IdSchedaLavoro FROM Deposito d1 WHERE d1.IdDeposito = d.IdRinnovo) ELSE d.D_IdSchedaLavoro END) AS IdSchedaLavoro, d.Note, d.Data, d.Pdv
FROM Deposito d
	 INNER JOIN
	 @Id
	 ON d.IdDeposito = IdDep

-- ===== Deposito ===== --
SELECT TOP 100 d.IdDeposito AS IdMovimentazionePneumatico, ISNULL(d.D_DataInventario,' ') AS D_DataInventario, d.Note_Inventario, d.D_Stato, ISNULL(d.D_DataRitiro,' ') AS D_DataRitiro, (CASE WHEN d.DaPagare IS NULL THEN 0 ELSE d.DaPagare END) AS DaPagare, (CASE WHEN d.CaricatePerMagazzino IS NULL THEN 0 ELSE d.CaricatePerMagazzino END) AS CaricatePerMagazzino, ISNULL(d.DataCaricatePerMagazzino,' ') AS DataCaricatePerMagazzino, ISNULL(d.DataRimandato,' ') AS DataRimandato, d.D_FirmatoRitiro_FM, d.Posizione, (CASE WHEN d.Rimontate IS NULL THEN 0 ELSE d.Rimontate END) AS Rimontate, ISNULL(d.Data_Rimontate,' ') AS Data_Rimontate, d.D_NotizieClienteDett
FROM Deposito d
	 INNER JOIN
	 @Id
	 ON d.IdDeposito = IdDep

-- ===== Righe Movimentazione Pneumatico ===== --
SELECT TOP 100 d.IdDeposito AS IdMovimentazionePneumatico, d.IdDeposito AS IdDeposito, d.Quantita, d.D_ArtCodice AS [Codice Articolo], (CASE WHEN d.D_DotAnt IS NULL THEN '' ELSE d.D_DotAnt END) AS DOT, d.Ant_mm AS Mm, d.D_TipoDepositoR1 AS [Tipo Deposito], (CASE WHEN d.Complete IS NULL THEN 0 ELSE d.Complete END) AS Complete, (CASE
	 WHEN d.Estive = 1 THEN 'Estivo'
	 WHEN d.Invernali = 1 THEN 'Invernale'
	 WHEN d.AllSeason = 1 THEN 'All Season'
	 ELSE 'N/D'
END) AS Stagione, d.Nostre
FROM Deposito d
	 INNER JOIN
	 @Id
	 ON d.IdDeposito = IdDep

UNION ALL

SELECT TOP 100 d.IdDeposito AS IdMovimentazionePneumatico, d.IdDeposito AS IdDeposito, d.D_Quantita_Post, d.D_ArtCodicePost AS [Codice Articolo], (CASE WHEN d.D_DotPost IS NULL THEN '' ELSE d.D_DotPost END) AS DOT, d.Post_mm AS Mm, d.D_TipoDepositoR2 AS [Tipo Deposito], (CASE WHEN d.Complete IS NULL THEN 0 ELSE d.Complete END) AS Complete, (CASE
	 WHEN d.Estive = 1 THEN 'Estivo'
	 WHEN d.Invernali = 1 THEN 'Invernale'
	 WHEN d.AllSeason = 1 THEN 'All Season'
	 ELSE 'N/D'
END) AS Stagione, d.Nostre
FROM Deposito d
	 INNER JOIN
	 @Id
	 ON d.IdDeposito = IdDep



