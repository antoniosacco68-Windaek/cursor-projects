-- =================================================================================
-- 1. Tutte le anagrafiche esistenti dalla tabella [Anagrafica].
-- 2. Gli utilizzatori dei veicoli presenti nella tabella [Veicolo] che non
--    hanno una corrispondenza nella tabella [Anagrafica] basata su Email e Telefono.
-- =================================================================================

-- 2025-06-11T12:24:36.000+0000 per data formattata Salesforce

USE I24DB

    -- =========================================================================
    -- STEP 1: Creo Tabella Temp con Id da cercare per portare dentro le Anagrafiche e i vari dati correlati fra loro
    -- =========================================================================

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

    -- =========================================================================
    -- STEP 2: Tabella Temp per unire le Anagrafiche Private insieme all'Utilizzatore
    -- =========================================================================

DECLARE @AnagraficaPriv TABLE
(
	Id int IDENTITY(1,1),
	IdAnagrafica int,
	IdVeicolo int,
	Nome varchar(80),
	Cognome varchar(80),
	Email1 varchar(150),
	Mobile1 varchar(60),
	Indirizzo varchar(80),
	Citta varchar(80),
	Prov varchar(80),
	Cap varchar(80),
	TipoCliente varchar(80),
	Provenienza varchar(60),
	RecordTypeId varchar(20) -- 012bl0000006WA5AAM (Privato) RecordTypeId (Valore dell'Id di SalesForce)
)

-- Popolo la Tbl Temporanea delle Anagrafiche Private --

INSERT INTO @AnagraficaPriv
	(IdAnagrafica, Nome, Cognome, Email1, Mobile1, Indirizzo, Citta, Prov, Cap, TipoCliente, RecordTypeId)
	   SELECT
	   a.IDAnagrafica,
	   a.Nome,
	   (CASE WHEN a.Cognome IS NULL AND a.Nome IS NULL THEN 'Generico' WHEN a.Cognome IS NULL AND a.Nome IS NOT NULL THEN a.Nome ELSE a.Cognome END),
	   (CASE
			WHEN Email1 IS NOT NULL AND
				 (LEN(Email1) - LEN(REPLACE(Email1, '@', '')) <> 1 OR
				 CHARINDEX('.', Email1, CHARINDEX('@', Email1)) = 0 OR
				 CHARINDEX('@', Email1) = 1 OR
				 CHARINDEX('.', REVERSE(Email1)) = 1) THEN ''
			ELSE a.Email1
	   END),
	   a.Mobile1,
	   a.Indirizzo,
	   a.Citta,
	   a.Prov,
	   a.Cap,
	   a.TipoCliente,
	   '012bl0000006WA5AAM'
	   FROM Anagrafica a
			INNER JOIN
			@Id
			ON IdAna = a.IDAnagrafica
	   WHERE a.TipoCliente = 'Privato'

-- ===== Pulisco i Campi che usiamo noi nell'Utilizzatore ===== --
UPDATE @AnagraficaPriv
  SET Nome = (CASE
	   WHEN Nome LIKE '%Referente%' THEN NULL
	   WHEN Nome LIKE '%Altro%' THEN NULL
	   WHEN Nome LIKE '%non presente%' THEN NULL
	   WHEN Nome LIKE '%nonpresente%' THEN NULL
	   ELSE Nome
  END),
  Cognome = (CASE
	   WHEN Cognome LIKE '%Referente%' THEN NULL
	   WHEN Cognome LIKE '%Altro%' THEN NULL
	   WHEN Cognome LIKE '%non presente%' THEN NULL
	   WHEN Cognome LIKE '%nonpresente%' THEN NULL
	   ELSE Cognome
  END),
  Email1 = (CASE
	   WHEN Email1 LIKE '%Referente%' THEN NULL
	   WHEN Email1 LIKE '%Altro%' THEN NULL
	   WHEN Email1 LIKE '%non presente%' THEN NULL
	   WHEN Email1 LIKE '%nonpresente%' THEN NULL
	   WHEN Email1 LIKE '%NonLasciaEmail%' THEN NULL
	   WHEN Email1 LIKE '%Non Lascia Email%' THEN NULL
	   ELSE Email1
  END),
  Mobile1 = (CASE
	   WHEN Mobile1 LIKE '%Referente%' THEN NULL
	   WHEN Mobile1 LIKE '%Altro%' THEN NULL
	   WHEN Mobile1 LIKE '%non presente%' THEN NULL
	   WHEN Mobile1 LIKE '%nonpresente%' THEN NULL
	   ELSE Mobile1
  END)


    -- =========================================================================
    -- STEP 3: Tabella Temp per le Anagrafiche Business insieme
    -- =========================================================================

DECLARE @AnagraficaBus TABLE
(
		Id int IDENTITY(1,1),
		IdAnagrafica int,
		Societa varchar(80),
		IndirizzoAz varchar(80),
		CapAz varchar(80),
		CittaAz varchar(80),
		RifAziendale varchar(80),
		A_MobileRifAz varchar(80),
		EmailRifAziend varchar(80),
		TelRifAzienda varchar(80),
		TipoCliente varchar(80),
		RecordTypeId varchar(20) -- 012bl0000006W8TAAU (Businness) RecordTypeId (Valore dell'Id di SalesForce)
)

-- Popolo la Tbl Temporanea delle Anagrafiche Business --

INSERT INTO @AnagraficaBus
	(IdAnagrafica, Societa, IndirizzoAz, CapAz, CittaAz, RifAziendale, A_MobileRifAz, EmailRifAziend, TelRifAzienda, TipoCliente, recordtypeid)
SELECT
		a.IDAnagrafica, a.Societa, a.IndirizzoAz, a.CapAz, a.CittaAz, a.RifAziendale, a.A_MobileRifAz,  (CASE WHEN a.EmailRifAziend IS NOT NULL AND (LEN(a.EmailRifAziend) - LEN(REPLACE(a.EmailRifAziend, '@', '')) <> 1 OR CHARINDEX('.', a.EmailRifAziend, CHARINDEX('@', a.EmailRifAziend)) = 0 OR CHARINDEX('@',a.EmailRifAziend) = 1 OR CHARINDEX('.', REVERSE(a.EmailRifAziend)) = 1) THEN '' ELSE a.EmailRifAziend END), a.TelRifAzienda, 'Cliente azienda','012bl0000006W8TAAU'
FROM Anagrafica a
	 INNER JOIN
	 @Id
	 ON IdAna = a.IDAnagrafica
WHERE a.TipoCliente = 'Azienda'


	-- Sistemo le Anagrafiche Aziendali se sono vuote perché erano Private e Passate Azienda quindi i dati sono da prendere dai dati Privato --

	UPDATE @AnagraficaBus
		SET RifAziendale = ISNULL(a.Nome,'') + ' ' + ISNULL(a.Cognome,''),
		Societa = ISNULL(a.Nome,'') + ' ' + ISNULL(a.Cognome,''),
		A_MobileRifAz = a.Mobile1,
		EmailRifAziend = a.Email1
	FROM @AnagraficaBus ab INNER JOIN
		Anagrafica a ON ab.IdAnagrafica = a.IDAnagrafica
	WHERE ab.Societa IS NULL
		AND ab.EmailRifAziend IS NULL
		AND ab.TelRifAzienda IS NULL

	-- Cancella i duplicati in ordine di data di modifica (Tiene solo il Primo Duplicato gli Altri Vengono Cancellati, quindi Ordinare in Modo che il Primo sia quello da TENERE)

	DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY ab.IdAnagrafica ORDER BY ab.IdAnagrafica DESC) AS [NumeroCodici],* FROM @AnagraficaBus ab) AS T1 
	WHERE T1.NumeroCodici > 1 

    -- =========================================================================
    -- STEP 4: Inserimento degli utilizzatori unici da [Veicolo]
    -- =========================================================================

    -- Dobbiamo generare nuovi ID per le anagrafiche che stiamo creando.
    DECLARE @MaxId INT;
    SELECT @MaxId = ISNULL(MAX(IdAnagrafica), 0) FROM @AnagraficaPriv;

    -- Inseriamo gli utilizzatori dalla tabella Veicolo solo se non esistono già
    -- nella tabella Anagrafica originale.
    INSERT INTO @AnagraficaPriv (
        IdAnagrafica,
		IdVeicolo,
        Nome,
        Cognome,
        Email1,
        Mobile1,
		Provenienza,
        TipoCliente, -- Gli altri campi saranno Privato
		RecordTypeId
    )
    SELECT
        -- Genera un nuovo ID univoco partendo dal massimo ID trovato + un numero progressivo
        @MaxId + ROW_NUMBER() OVER (ORDER BY v.V_EmailUtiliz, v.V_TelefonoUtiliz),
		MAX(v.IdVeicolo),
        MAX(v.V_NomeUtiliz),      -- Usiamo MAX() per prendere un valore nel caso ci siano duplicati
        MAX(v.V_CognomeUtiliz),   -- di email/telefono con nomi/cognomi leggermente diversi
       (CASE
			WHEN v.V_EmailUtiliz IS NOT NULL AND
				 (LEN(v.V_EmailUtiliz) - LEN(REPLACE(v.V_EmailUtiliz, '@', '')) <> 1 OR
				 CHARINDEX('.', v.V_EmailUtiliz, CHARINDEX('@', v.V_EmailUtiliz)) = 0 OR
				 CHARINDEX('@', v.V_EmailUtiliz) = 1 OR
				 CHARINDEX('.', REVERSE(v.V_EmailUtiliz)) = 1) THEN ''
			ELSE v.V_EmailUtiliz
	   END),
        v.V_TelefonoUtiliz,
        'Utilizzatore Veicolo', -- Assegniamo un tipo per riconoscerli facilmente
		'Privato',
		'012bl0000006WA5AAM'
   FROM Veicolo v
	 INNER JOIN
	 @Id
	 ON IdVeic = v.IdVeicolo
    WHERE
        -- Condizione 1: Assicuriamoci che i campi per il confronto non siano vuoti
        (v.V_CognomeUtiliz IS NOT NULL AND v.V_TelefonoUtiliz IS NOT NULL)
        AND
		LEN(LTRIM(RTRIM(v.V_CognomeUtiliz))) > 3
		AND
        -- Condizione 2: L'utilizzatore (coppia Email/Telefono) NON deve esistere nella tabella Anagrafica
        NOT EXISTS (
            SELECT 1
            FROM @AnagraficaPriv a
            WHERE a.Cognome = v.V_CognomeUtiliz AND a.Mobile1 = v.V_TelefonoUtiliz
        )
    GROUP BY
        -- Raggruppiamo per Email e Telefono per inserire una sola volta gli utilizzatori
        -- che potrebbero essere presenti su più veicoli.
        v.V_EmailUtiliz,
        v.V_TelefonoUtiliz;

	-- ===== Pulisco i Campi che usiamo noi nell'Utilizzatore ===== --

	UPDATE @AnagraficaPriv
	  SET Nome = (CASE
		   WHEN Nome LIKE '%Referente%' THEN ''
		   WHEN Nome LIKE '%Altro%' THEN ''
		   WHEN Nome LIKE '%non presente%' THEN ''
		   WHEN Nome LIKE '%nonpresente%' THEN ''
		   WHEN Nome IS NULL THEN ''
		   ELSE Nome
	  END),
	  Cognome = (CASE
		   WHEN Cognome LIKE '%Referente%' THEN ''
		   WHEN Cognome LIKE '%Altro%' THEN ''
		   WHEN Cognome LIKE '%non presente%' THEN ''
		   WHEN Cognome LIKE '%nonpresente%' THEN ''
		   WHEN Cognome IS NULL THEN ''
		   ELSE Cognome
	  END),
	  Email1 = (CASE
		   WHEN Email1 LIKE '%Referente%' THEN ''
		   WHEN Email1 LIKE '%Altro%' THEN ''
		   WHEN Email1 LIKE '%non presente%' THEN ''
		   WHEN Email1 LIKE '%nonpresente%' THEN ''
		   WHEN Email1 LIKE '%NonLasciaEmail%' THEN ''
		   WHEN Email1 LIKE '%Non Lascia Email%' THEN ''
		   WHEN Email1 IS NULL THEN ''
		   ELSE Email1
	  END),
	  Mobile1 = (CASE
		   WHEN Mobile1 LIKE '%Referente%' THEN ''
		   WHEN Mobile1 LIKE '%Altro%' THEN ''
		   WHEN Mobile1 LIKE '%non presente%' THEN ''
		   WHEN Mobile1 LIKE '%nonpresente%' THEN ''
		   WHEN Mobile1 IS NULL THEN ''
		   ELSE Mobile1
	  END)

	DELETE @AnagraficaPriv WHERE Email1 IS NULL AND Mobile1 IS NULL AND Provenienza = 'Utilizzatore Veicolo';

	DELETE @AnagraficaPriv WHERE LTRIM(RTRIM(Email1)) = '' AND LTRIM(RTRIM(Mobile1)) = '' AND Provenienza = 'Utilizzatore Veicolo';

	DELETE @AnagraficaPriv WHERE LTRIM(RTRIM(Nome)) = '' AND LTRIM(RTRIM(Cognome)) = '' AND Provenienza = 'Utilizzatore Veicolo';



	-- Cancello i Duplicati che si Possono Creare quando inserisco gli Utilizzatori --

	WITH DuplicatiDaCancellare AS (
		SELECT
			ROW_NUMBER() OVER(
				-- PARTITION BY: Definisce cosa costituisce un "gruppo di duplicati".
				-- In questo caso, raggruppiamo per Nome, Cognome, Email e Cellulare.
				PARTITION BY Nome, Cognome, Email1, Mobile1
				ORDER BY Nome, Cognome DESC
			) AS RowNum
		FROM

			@AnagraficaPriv
	)
	DELETE FROM DuplicatiDaCancellare
	WHERE RowNum > 1;

	-- Visualizzo Anagrafica Privato --
	
	SELECT 'Anagrafica Privato' AS [Anagrafica Privato]

	SELECT IdAnagrafica AS External_Id__c, ISNULL(Nome,'') AS FirstName, ISNULL(Cognome,'') AS LastName, ISNULL(Email1,'') AS PersonEmail, ISNULL(Mobile1,'') AS PersonMobilePhone, ISNULL(Indirizzo,'') AS BillingStreet, ISNULL(Citta,'') AS BillingCity, ISNULL(Prov,'') AS BillingState, ISNULL(Cap,'') AS BillingPostalCode, TipoCliente AS [Type], RecordTypeId, Provenienza, IdVeicolo
	FROM @AnagraficaPriv
	ORDER BY Cognome

	-- Visualizzo Anagrafica Business --
	
	SELECT 'Anagrafica Business' AS [Anagrafica Business]

	SELECT IdAnagrafica AS External_Id__c, ISNULL(Societa,'') AS [Name], ISNULL(IndirizzoAz,'') AS BillingStreet, ISNULL(CapAz,'') AS BillingPostalCode, ISNULL(CittaAz,'') AS BillingCity, ISNULL(RifAziendale,''), ISNULL(A_MobileRifAz,'') AS Mobile_aziendale__c, ISNULL(EmailRifAziend,'') AS Email_aziendale__c, ISNULL(TelRifAzienda,'') AS Phone, TipoCliente AS [Type], RecordTypeId
	FROM @AnagraficaBus
	ORDER BY Societa

    -- =========================================================================
    -- STEP 5: Inserimento dei Veicoli
    -- =========================================================================

	-- ===== Veicolo ===== --
	
	SELECT 'Veicolo' AS Veicolo

	SELECT DISTINCT v.IdVeicolo AS External_ID__c,
		v.V_IdAnagrafica AS [Anagrafica__r:Account:External_Id__c],
		v.TipologiaVeicolo AS Tipologia_Veicolo__c,
		v.Targa AS Targa__c,
		ISNULL(v.Marca,'') AS Marca__c,
		ISNULL(v.Modello,'') AS Modello__c,
		ISNULL(v.V_LeasingCompany,'') AS Leasing_Company__c,
		ISNULL(v.N_Telaio,'') AS Telaio__c,
		ISNULL(v.V_Archiviato,'') AS Archiviato__c,
		ISNULL(v.V_TipoPneumLc,'') AS Tipo_Contratto__c,
		ISNULL(v.V_Note,'') AS Note__c,
		ISNULL(v.V_Tpms,0) AS Tpms__c,
		ISNULL(v.V_PortaleLeasing,'') AS Portale_Leasing__c,
		ISNULL(v.V_NCabina,'') AS Numero_Cabina__c,
		ISNULL(v.V_ScadRevisione,'') AS Scadenza_Revisione__c,
		ISNULL(v.Cilindrata,'') AS Cilindrata__c,
		ISNULL(v.Kilowatt,'') AS Kilowatt__c,
		ISNULL(v.CodiceMotore,'') AS Codice_Motore__c,
		ISNULL(v.DataImmatricolazione,'') AS Data_Immatricolazione__c,
		ISNULL(v.DataUltimaRev,'') AS Data_ultima_Revisione__c,
		ISNULL(v.RagioneSocialeRev,'') AS Ragione_Sociale_Revisione__c,
		ISNULL(v.NomeRev,'') AS Nome_Revisione__c,
		ISNULL(v.CognomeRev,'') AS Cognome_Revisione__c,
		ISNULL(v.CellulareRev,'') AS Cellulare_Revisione__c,
		ISNULL((CASE
			WHEN v.EmailRev IS NOT NULL AND
				 (LEN(v.EmailRev) - LEN(REPLACE(v.EmailRev, '@', '')) <> 1 OR
				 CHARINDEX('.', v.EmailRev, CHARINDEX('@', v.EmailRev)) = 0 OR
				 CHARINDEX('@', v.EmailRev) = 1 OR
				 CHARINDEX('.', REVERSE(v.EmailRev)) = 1) THEN ''
			ELSE v.EmailRev
	   END),'') AS Email_Revisione__c,
		ISNULL(v.IndirizzoRev,'') AS Indirizzo_Revisione__c,
		ISNULL(v.CapRev,'') AS Cap_Revisione__c,
		ISNULL(v.ProvinciaRev,'') AS Provincia_Revisione__c,
		ISNULL(v.CittaRev,'') AS Citta_Revisione__c,
		ISNULL(v.PromemoriaScadTipoInvio,'') AS Promemoria_Scadenza_Tipo_Invio__c,
		ISNULL(v.V_NoMozzi,0) AS No_Mozzi__c,
		ISNULL(v.V_ScadBombole,'') AS Scadenza_Revisione_Bombole__c,
		ISNULL(v.Marca,'') + ' ' + ISNULL(v.Modello,'') + ' - ' + v.Targa AS Name 
	FROM Veicolo v
		 INNER JOIN
		 @Id
		 ON IdVeic = v.IdVeicolo

	-- =========================================================================
    -- STEP 5B: Inserimento Propietà
    -- =========================================================================

	SELECT 'Propieta' AS Propieta

	SELECT
	IdVeicolo AS External_ID__c,
	v.IdVeicolo AS [Veicolo__r:Veicolo__c:External_ID__c],
	(CASE WHEN v.V_LeasingCompany IS NULL THEN CAST(v.V_IdAnagrafica AS varchar(20)) ELSE lc.ID END) AS [Proprietario__r:Account:External_Id__c],
	(CASE WHEN v.V_LeasingCompany IS NOT NULL THEN CAST(v.V_IdAnagrafica AS varchar(20)) ELSE '' END) AS [Locatario__r:Account:External_Id__c],
	(CASE WHEN v.V_LeasingCompany IS NOT NULL THEN 'Noleggio' WHEN v.V_LeasingCompany IS NULL AND a.TipoCliente = 'Privato' THEN 'Privata' ELSE 'Business' END) as Tipologia__c
	FROM Veicolo v
		 INNER JOIN
		 @Id
		 ON IdVeic = v.IdVeicolo
		 INNER JOIN
		 Anagrafica a
		 ON a.IDAnagrafica = IdAna
		 LEFT JOIN
		 LeasingCompany lc
		 ON REPLACE(REPLACE(REPLACE(REPLACE(v.V_LeasingCompany,'ALD (AYVENS 1/25)','AYVENS') ,'LEASE PLANE (AYVENS 1/25)','AYVENS') ,'SIFA (UNIPOL RENTAL 1/25)','UNIPOL RENTAL'), 'ALD','AYVENS') = lc.NomeLc
	
	UNION ALL 

	-- Inserisco gli Utilizzatori --
	SELECT
		IdVeicolo AS External_ID__c,
		IdVeicolo AS [Veicolo__r:Veicolo__c:External_ID__c],	
		IdAnagrafica AS [Proprietario__r:Account:External_Id__c],
		'' AS [Locatario__r:Account:External_Id__c],
		'Privata' AS Tipologia__c
	FROM @AnagraficaPriv
	WHERE Provenienza = 'Utilizzatore Veicolo';


    -- ========================================================================= 
    -- STEP 6: Inserimento Commesse
    -- ========================================================================= 

	/*
	SELECT 'Commesse' AS Commesse

	SELECT s.IdSchedaLavoro AS External_ID__c,
		s.S_IdAnagrafica AS [Anagrafica__r:Account:External_Id__c],
		s.S_IdVeicolo AS [Veicolo__r:Veicolo__c:External_ID__c],
		s.Pdv AS Pdv__c,
		s.Km AS Km__c,
		s.Data_Lavori AS Data_Lavori__c,
		ISNULL(s.S_ConfImpPneumatici,0) AS ConfImpPneumatici__c,
		ISNULL(s.OreMeccanicaReali,0) AS OreMeccanicaReali__c,
		ISNULL(s.S_NImpPneumatici,'') AS NImpPneumatici__c,
		ISNULL(s.CodCli_LC_FatturaBolla,'') AS CodCli_LC_FatturaBolla__c,
		ISNULL(s.S_TipoPagamento,'') AS TipoPagamento__c,
		ISNULL(s.Note_Stampa,'') AS Note_Stampa__c,
		ISNULL(s.Operatore,'') AS Operatore__c,
		ISNULL(s.Note,'') AS Note__c,
		s.S_Targa AS Targa__c,
		ISNULL(s.Stato_Commessa,'') AS Stato_Commessa__c,
		ISNULL(s.Importo,0) AS Importo__c,
		ISNULL(s.Problemi,0) AS Problemi__c,
		ISNULL(s.Urgente,0) AS Urgente__c,
		ISNULL(s.S_IdPreventivo,'') AS IdPreventivo__c,
		ISNULL(s.S_Promozione,'') AS Promozione__c,
		ISNULL(s.S_UsuraFreniAnt,'') AS UsuraFreniAnt__c,
		ISNULL(s.S_UsuraFreniPost,'') AS UsuraFreniPost__c,
		ISNULL(s.S_NScontrino,'') AS NScontrino__c,
		ISNULL(s.S_NFattura,'') AS NFattura__c,
		ISNULL(s.S_NRichiestaLc,'') AS NRichiestaLc__c,
		ISNULL(s.S_BGR,'') AS BGR__c,
		ISNULL(s.S_NBGR,'') AS NBGR__c,
		ISNULL(s.S_NBolla,'') AS NBolla__c,
		ISNULL(s.S_TPMS,'') AS TPMS__c,
		ISNULL(s.S_ODL,'') AS ODL__c,
		ISNULL(s.S_NReport,'') AS NReport__c,
		ISNULL(s.S_DataCreazDocVen,'') AS DataCreazDocVen__c,
		ISNULL(s.S_UsuraDischiAnt,'') AS UsuraDischiAnt__c,
		ISNULL(s.S_UsuraDischiPost,'') AS UsuraDischiPost__c,
		ISNULL(s.S_NoMozzi,'') AS NoMozzi__c,
		ISNULL(s.S_Reparto,'') AS NReport__c,
		ISNULL(s.S_OffMeccEsterna,'') AS OffMeccEsterna__c,
		ISNULL(s.Autista,'') AS Autista__c,
		ISNULL(s.S_RespCommessa,'') AS RespCommessa__c
	FROM SchedaLavoro s
		 INNER JOIN
		 @Id
		 ON IdScLav = s.IdSchedaLavoro

*/
	-- =========================================================================
    -- STEP 6B: Inserimento Righe Commesse
    -- =========================================================================

	---- ===== Articoli Commessa ===== --
	--SELECT ar.Art_IdSchedaLavoro, ar.Art_IdVeicolo, ar.Art_IdArtico, ar.Art_Codice, ar.Art_Qta, ar.Art_DOT, ar.Art_PrezzoUnit AS PrezzoUnitImp, ar.Art_PrezzoRigaImp AS PrezzoRigaImp, ar.Art_Prezzo AS PrezzoTotIc, ar.Art_Fascia AS Fascia, ar.Art_LottoForzato AS LottoForzato
	--FROM ArtSchedaLavoro ar
	--	 INNER JOIN
	--	 @Id
	--	 ON IdScLav = ar.Art_IdSchedaLavoro


    -- =========================================================================
    -- STEP 7: Inserimento Movimentazione Pneumatico
    -- =========================================================================

	SELECT 'Movimentazione Pneumatico' AS [Movimentazione Pneumatico]

	SELECT d.IdDeposito AS External_ID__c,
		d.D_IdVeicolo AS [Veicolo__r:Veicolo__c:External_ID__c],
		d.D_IdSchedaLavoro AS idsclav,
		d.D_IdAnagrafica AS IdAnagrafica__c,
		(CASE WHEN d.D_IdSchedaLavoro = 0 THEN (SELECT d1.D_IdSchedaLavoro FROM Deposito d1 WHERE d1.IdDeposito = d.IdRinnovo) ELSE d.D_IdSchedaLavoro END) AS IdCommessa__c,
		ISNULL(d.Note,'') AS Note__c,
		d.Pdv AS Pdv__c
	FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep


    -- =========================================================================
    -- STEP 8: Inserimento Deposito
    -- =========================================================================

	SELECT 'Deposito' AS Deposito

	SELECT 
		d.IdDeposito AS External_ID__c,
		d.IdDeposito AS [Movimentazione_pneumatico__r:Movimentazione_pneumatico__c:External_ID__c],
    
		-- Campi Data corretti
		dbo.FormatDateToSalesForce(d.D_DataInventario) AS Data_Inventario__c,
		dbo.FormatDateToSalesForce(d.D_DataRitiro) AS Data_Ritiro__c,
		dbo.FormatDateToSalesForce(d.DataCaricatePerMagazzino) AS Data_Caricate_Per_Magazzino__c,
		dbo.FormatDateToSalesForce(d.DataRimandato) AS Data_Rimandato__c,
		dbo.FormatDateToSalesForce(d.Data_Rimontate) AS Data_Rimontate__c,

		-- Altri campi
		ISNULL(d.Note_Inventario, '') AS Note_Inventario__c,
		d.D_Stato AS Stato__c,
		(CASE WHEN d.DaPagare IS NULL THEN 0 ELSE d.DaPagare END) AS Da_Pagare__c,
		(CASE WHEN d.CaricatePerMagazzino IS NULL THEN 0 ELSE d.CaricatePerMagazzino END) AS Caricate_Per_Magazzino__c,
		d.D_FirmatoRitiro_FM AS Firmato_Ritiro_FM__c,
		ISNULL(d.Posizione, '') AS Posizione__c,
		(CASE WHEN d.Rimontate IS NULL THEN 0 ELSE d.Rimontate END) AS Rimontate__c,
		ISNULL(d.D_NotizieClienteDett, '') AS Notizie_Cliente_Dettaglio__c
	FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep


    -- =========================================================================
    -- STEP 9: Inserimento  Riga Movimentazione Pneumatico
    -- =========================================================================

	SELECT 'Riga Movimentazione Pneumatico' AS [Riga Movimentazione Pneumatico]

	SELECT d.IdDeposito AS [Movimentazione_Pneumatico__r:Movimentazione_pneumatico__c:External_ID__c],
		d.IdDeposito AS [Deposito__r:Deposito__c:External_Id__c],
		d.Quantita AS Quantita__c,
		d.D_ArtCodice AS Codice_Articolo__c,
		ISNULL(a.ID,'') AS [Articolo__r:Product2:External_Id__c],
		(CASE WHEN d.D_DotAnt IS NULL THEN '' ELSE d.D_DotAnt END) AS Dot__c,
		REPLACE(d.Ant_mm,',','.') AS mm__c,
		d.D_TipoDepositoR1 AS Stato__c,
		(CASE WHEN d.Complete IS NULL THEN 0 ELSE d.Complete END) AS Complete__c,
		(CASE
			WHEN d.Estive = 1 THEN 'Estivo'
			WHEN d.Invernali = 1 THEN 'Invernale'
			WHEN d.AllSeason = 1 THEN 'All Season'
		ELSE 'N/D'
		END) AS Tipologia_Gomma__c,
		d.Nostre AS Ritirato_BG__c
	FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep
		 LEFT JOIN
		 i24bo.dbo.ARTICO a
		 ON a.CODICE = d.D_ArtCodice

	UNION ALL

	SELECT d.IdDeposito AS [Movimentazione_Pneumatico__r:Movimentazione_pneumatico__c:External_ID__c],
		d.IdDeposito AS [Deposito__r:Deposito__c:External_Id__c],
		d.D_Quantita_Post AS Quantita__c,
		d.D_ArtCodicePost AS Codice_Articolo__c,
		ISNULL(a.ID,'') AS [Articolo__r:Product2:External_Id__c],
		(CASE WHEN d.D_DotPost IS NULL THEN '' ELSE d.D_DotPost END) AS Dot__c,
		REPLACE(d.Post_mm,',','.') AS mm__c,
		d.D_TipoDepositoR2 AS Stato__c,
		(CASE WHEN d.Complete IS NULL THEN 0 ELSE d.Complete END) AS Complete__c,
		(CASE
			WHEN d.Estive = 1 THEN 'Estivo'
			WHEN d.Invernali = 1 THEN 'Invernale'
			WHEN d.AllSeason = 1 THEN 'All Season'
		ELSE 'N/D'
		END) AS Tipologia_Gomma__c,
		d.Nostre AS Ritirato_BG__c
	FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep
		 LEFT JOIN
		 i24bo.dbo.ARTICO a
		 ON a.CODICE = d.D_ArtCodicePost


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
		ISNULL(psf.Ext_EAN,'') AS Ean__c,
		ISNULL(psf.ART_CODICE,'') AS StockKeepingUnit,
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
		FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep
		 INNER JOIN 
		 I24DB.dbo.ProdottiSalesForce psf
		 ON (psf.ART_CODICE = d.D_ArtCodice OR psf.ART_CODICE = d.D_ArtCodicePost)


	-- =========================================================================
    -- STEP 11: Riga Magazzino
    -- =========================================================================

	SELECT 'Riga magazzino' AS [Riga magazzino]

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
	FROM Deposito d
		 INNER JOIN
		 @Id
		 ON d.IdDeposito = IdDep
		 INNER JOIN
		 I24DB.dbo.ProdottiSalesForce psf
		 ON (psf.ART_CODICE = d.D_ArtCodice OR
			 psf.ART_CODICE = d.D_ArtCodicePost)
		 INNER JOIN
		 PiattaformeWeb.dbo.OfferteWeb ow
		 ON psf.Art_Id = ow.IDARTICO
		 INNER JOIN
		 PiattaformeWeb.dbo.Ant_FornPiattaforma fp
		 ON fp.IdForPiatt = ow.IdFornitore
	


