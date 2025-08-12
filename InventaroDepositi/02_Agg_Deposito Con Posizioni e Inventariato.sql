------ Prima Preparare la Tabella che si User "Inventario_Depositi / Inventario_Depositi" -----------------


------ Aggiorno TBL Deposito con Inventario ----------

USE I24DB

DECLARE @Sql1 varchar(800),@Sql2 varchar(800),@PdvInv varchar(60),@NotaInventario varchar(30),@RicNotaInventario varchar(30),@Tabella varchar(100)

--========================= Attenzione Cambiare i Valori delle Variabili in Base alle Necessit� ===========================================--

SET @NotaInventario = 'INVENTARIATE (' + CAST(CAST(GETDATE( ) AS DATE) AS VARCHAR(20)) + ')'

SET @Tabella = 'Inventario_Depositi' -- Il NOME della TABELLA da Usare : Inventario_Depositi / Inventario_Estive



--======================================================================================================================================================
--
-- FASE 1: RESET DEPOSITI PRECEDENTEMENTE INVENTARIATI
-- Reset di tutti i depositi che erano stati inventariati in sessioni precedenti
--
--======================================================================================================================================================

	-- ===== Tolgo il Flag INVENTARIATO e Metto i Depositi in STATO "C" nei Depositi Inventariati ===== --

	UPDATE Deposito
		SET Note_Inventario = REPLACE(Note_Inventario,'INVENTARIATE',''),
			D_Stato = 'C',
			Inventariato = 0
	WHERE Inventariato = 1

	-- ===== Aggiorno Lo STATO in "C" dei Depositi In cui le "Note_Inventario" sono Compilate e lo STATO non è "C" ===== --

	UPDATE Deposito
		SET D_Stato = 'C'
	WHERE Note_Inventario IS NOT NULL AND D_Stato <> 'C'

--======================================================================================================================================================
--
-- FASE 2: CHIUSURA AUTOMATICA DEPOSITI NON PIÙ IN DEPOSITO
-- Identifica e chiude automaticamente depositi che non sono più fisicamente presenti
--
--======================================================================================================================================================

	-- Scrivo "Chiuso" nelle 'Note_Inventario' se Trovo il Campo 'Rimontate' VERO e le Note_Inventario sono NULL
	UPDATE Deposito
		SET Note_Inventario = 'Chiuso',D_Stato = 'C'
	WHERE Rimontate = 1 and Note_Inventario is NULL

	-- Scrivo "Chiuso" nelle 'Note_Inventario' se Trovo lo STATO = "C" e le note inventario vuote --
	UPDATE Deposito
		SET Note_Inventario = 'CHIUSO'
	WHERE D_Stato = 'C' AND Note_Inventario IS NULL

	-- Scrivo "Chiuso" nelle 'Note_Inventario' se Trovo il Campo 'No_Deposito' che Corrisponde al Campo 'Ritiro' VERO e le Note_Inventario sono NULL
	UPDATE Deposito
		SET Note_Inventario = 'Chiuso',D_Stato = 'C'
	WHERE No_Deposito = 1 and Note_Inventario is NULL

	-- Scrivo "Chiuso" nelle 'Note_Inventario' se le Note_Inventario sono NULL e Non trovo nelle righe del TipoDeposito la Scritta Deposito (qundi Ritirate o smaltite)
	UPDATE Deposito
		SET D_Stato = 'C', Note_Inventario = 'CHIUSO'
	WHERE Note_Inventario IS NULL AND (D_TipoDepositoR1 NOT LIKE '%Deposito%' AND D_TipoDepositoR2 NOT LIKE '%Deposito%')

	UPDATE Deposito
		SET D_Stato = 'C', Note_Inventario = 'CHIUSO'
	WHERE Note_Inventario IS NULL AND (D_TipoDepositoR1 NOT LIKE '%Deposito%' AND D_TipoDepositoR2 IS NULL)

	UPDATE Deposito
		SET D_Stato = 'C', Note_Inventario = 'CHIUSO'
	WHERE Note_Inventario IS NULL AND (D_TipoDepositoR2 NOT LIKE '%Deposito%' AND D_TipoDepositoR1 IS NULL)

--======================================================================================================================================================
--
-- FASE 3: AGGIORNAMENTO DEPOSITI TROVATI NELL'INVENTARIO ATTUALE
-- Aggiorna posizioni e stati per i depositi effettivamente trovati durante l'inventario
--
--======================================================================================================================================================

-- ===== Aggiorno Le posizioni e le note invemtario ===== --

UPDATE Deposito
	SET Posizione = COALESCE(i.PosizioneMultipla, i.Posizione),
		Note_Inventario = @NotaInventario,
		Inventariato = -1,
		D_Stato = 'A',
		D_DataInventario = GETDATE()
FROM Deposito d INNER JOIN Inventario_Depositi i ON i.IdAbbinato = d.IdDeposito
WHERE Elaborato IS NULL

UPDATE Inventario_Depositi
	SET Elaborato = 1
FROM Deposito d INNER JOIN Inventario_Depositi i ON i.IdAbbinato = d.IdDeposito

--======================================================================================================================================================
--
-- GESTIONE SPECIALE: CHIUSURA DEPOSITI HERA E T-PER
--
--======================================================================================================================================================

-- ===== Aggiunto per Chiudere DEPOSITI HERA e T-PER ===== --

UPDATE Deposito
	SET Posizione = 'Nessuna',Inventariato = 0,Note_Inventario = 'CHIUSO'
FROM Deposito
INNER JOIN Anagrafica ON IDAnagrafica = Deposito.D_IdAnagrafica
INNER JOIN Veicolo ON IdVeicolo = D_IdVeicolo 
WHERE Note_Inventario is NULL AND (Societa LIKE '%Hera%' AND Societa LIKE '%T-Per%')

----------------------------------------------------------------------------------------------------------------------------------------------

-- SELECT * from Inventario_Depositi  WHERE Note = 'Verificare'
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT * from Inventario_Depositi  WHERE Elaborato IS NULL

--SELECT * from Inventario_Depositi  WHERE Elaborato is NULL order by SoloTarga
--SELECT * from Inventario_Depositi  WHERE note is not NULL order by SoloTarga

----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------

-------- Trovo i DEPOSITI che non sono Stati TROVATI e quindi MANCANTI !!!

--SELECT d.IdDeposito, Nome,Cognome,Societa,Marca,v.Modello,D_Targa,Quantita,d.Modello,d.Misura,D_Quantita_Post,D_Modello_Post,D_MisuraPost,d.Note,Nostre,Estive,d.AllSeason, Invernali,i.Posizione AS InventarioPosizione, i.Note AS NotefileInventario,d.Pdv,Data AS DataDeposito
--from Deposito d INNER JOIN Anagrafica a ON IDAnagrafica = d.D_IdAnagrafica INNER JOIN Veicolo v ON IdVeicolo = D_IdVeicolo LEFT JOIN Inventario_Depositi i ON SoloTarga COLLATE Database_Default = v.Targa COLLATE Database_Default
--WHERE Note_Inventario is NULL --AND ((Societa NOT LIKE '%Hera%' AND Societa NOT LIKE '%T-Per%') OR Societa IS NULL)
--ORDER BY d.Data


------ Utilissima Per dare ad ALBA per Verificare i Probabili Depositi Inventariati ma Nostri !! -------------------

--SELECT     Pdv,Anagrafica.Nome, Anagrafica.Cognome, Anagrafica.Societa, Anagrafica.Mobile1, Anagrafica.NoteAnagrafica, Veicolo.Targa, Veicolo.Marca, Veicolo.Modello AS ModelloVettura, 
--                      Deposito.*
--FROM         Veicolo INNER JOIN
--                      Anagrafica ON Veicolo.V_IdAnagrafica = Anagrafica.IDAnagrafica INNER JOIN
--                      Deposito ON Veicolo.IdVeicolo = Deposito.D_IdVeicolo
--WHERE   (Deposito.Inventariato = 1) AND (Deposito.Appuntamento = 0 OR
--                      Deposito.Appuntamento IS NULL) AND (Deposito.Note LIKE '%Smalt%' OR
--                      Deposito.Note LIKE '%Nostr%' OR
--                      Deposito.Note LIKE '%Finit%' OR
--                      Deposito.Note LIKE '%vend%'OR 
--                      Deposito.Note LIKE '%Resa%'OR 
--                      Deposito.Note LIKE '%Rotta%' 
--					  )

------ Utile Per dare ad ALBA per Verificare Depositi Inventariati ma Non MOVIMENTATI da 2 ANNI !! -------------------

-- SELECT     Pdv,Anagrafica.Nome, Anagrafica.Cognome, Anagrafica.Societa, Anagrafica.Mobile1, Anagrafica.NoteAnagrafica, Veicolo.Targa, Veicolo.Marca, Veicolo.Modello AS ModelloVettura, 
--                      Deposito.*
--FROM         Veicolo INNER JOIN
--                      Anagrafica ON Veicolo.V_IdAnagrafica = Anagrafica.IDAnagrafica INNER JOIN
--                      Deposito ON Veicolo.IdVeicolo = Deposito.D_IdVeicolo
--WHERE   (Deposito.Inventariato = 1) AND (Deposito.Appuntamento = 0 OR
--                      Deposito.Appuntamento IS NULL) AND Year(Data) < YEAR(GETDATE()) - 1