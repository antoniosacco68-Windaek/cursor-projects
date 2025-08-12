USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[SP_PreventiviWebImportazione]    Script Date: 13/05/2025 10:50:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SP_PreventiviWebImportazione]
AS
BEGIN

	SET NOCOUNT ON;

	-- ===== Sposto dalla Cartella del NAS al Disco del Server in "C:\Antonio\Web\PreventiviWeb\" i Preventivi che arrivano dai Moduli del Sito ===== --

	EXEC XP_CMDSHELL 'net use Y: \\NasSynBg1\Dropbox\PreventiviWeb /user:Antonio Superboos42s7'
	EXEC XP_CMDSHELL 'Dir y:'
	EXEC XP_CMDSHELL 'move Y:\*.json C:\Antonio\Web\PreventiviWeb\'
	EXEC XP_CMDSHELL 'net use Y: /delete'

	-- ===== Variabili di configurazione ===== --

	DECLARE @sourceFolder VARCHAR(255) = 'C:\Antonio\Web\PreventiviWeb';  -- Cartella sorgente dei CSV
	DECLARE @archiveFolder VARCHAR(255) = 'C:\Antonio\Web\PreventiviWeb\Archivio';  -- Cartella di archivio
	DECLARE @fileName VARCHAR(255);
	DECLARE @bulkInsertCommand NVARCHAR(MAX);
	DECLARE @moveCommand VARCHAR(4000);
	DECLARE @Rif VARCHAR(80)
		   ,@Riga INT
		   ,@Descr VARCHAR(250)
		   ,@NomeJson VARCHAR(400)

	-- Variabili Email --
	DECLARE @body nvarchar(4000),@TProfileName varchar(50),@to_mails nvarchar(500) = 'antonio.sacco@bolognagomme.com',@cc_mails nvarchar(500) = '',@ccn_mails nvarchar(500) = '',@subject nvarchar(500);

	-- Pulisco la TBL dove mettero il Json da Importare nella TBL di Produzione --
	TRUNCATE TABLE PreventivoWebJson

	-- ===== GESTIONE ERRORI ==== --
	BEGIN TRY

		-- Crea una tabella temporanea per memorizzare i nomi dei file
		DECLARE @FileList TABLE (
			FileName NVARCHAR(255)
		);

		-- Usa xp_cmdshell per ottenere la lista dei file CSV nella cartella
		INSERT INTO @FileList (FileName)
		EXEC xp_cmdshell 'dir "C:\Antonio\Web\PreventiviWeb\*.json" /b';

		-- Rimuovi eventuali valori NULL che possono essere inseriti da xp_cmdshell
		DELETE FROM @FileList
		WHERE FileName IS NULL
			OR FileName LIKE '%trovato%';

		-- Crea un cursore per ciclare sui file CSV
		DECLARE file_cursor CURSOR FAST_FORWARD READ_ONLY LOCAL FOR SELECT
			FileName
		FROM @FileList

		OPEN file_cursor;
		FETCH NEXT FROM file_cursor INTO @fileName;

		-- Ciclo per processare ogni file

		WHILE @@fetch_status = 0
		BEGIN

		-- Creo il nome corretto del percorso file JSON da importare
		SET @NomeJson = @sourceFolder + '\' + @fileName

		-- Eseguo la Stored per importare i Json dentro alla TBL --
		EXEC ImportaPreventivoWebJson @JsonFilePath = @NomeJson;

		PRINT 'Json Elaborato Correttamente: ' + @NomeJson

		-- Dopo l'importazione, sposta il file nella cartella Archivio
		SET @moveCommand = 'move "' + @sourceFolder + '\' + @fileName + '" "' + @archiveFolder + '\' + @fileName + '"';
		EXEC xp_cmdshell @moveCommand;

		-- Passa al file successivo
		FETCH NEXT FROM file_cursor INTO @fileName;
		END;

		-- Chiudi e dealloca il cursore

		CLOSE file_cursor;
		DEALLOCATE file_cursor;

		-- Inserisco i Dati nella TBL di Produzione --
		INSERT INTO PreventiviWeb (DataRichiesta
		, Nome
		, Cognome
		, Email
		, Telefono
		, CAP
		, Negozio
		, TargaVeicolo
		, Marca
		, Modello
		, TipoPreventivo
		, Larghezza
		, Spalla
		, Diametro
		, CodCar
		, CodVel
		, Stagionalita
		, NrPneumatici
		, FasciaDiPrezzo
		, Km
		, TipoManutenzione
		, LarghezzaMotoAnt
		, SpallaMotoAnt
		, DiametroMotoAnt
		, CodCarMotoAnt
		, CodVelMotoAnt
		, LarghezzaMotoPost
		, SpallaMotoPost
		, DiametroMotoPost
		, CodCarMotoPost
		, CodVelMotoPost
		, CorpoMessaggio)
			SELECT
				p.DataRichiesta, LEFT(LTRIM(RTRIM(p.Nome)),50), LEFT(LTRIM(RTRIM(p.Cognome)),50), LEFT(LTRIM(RTRIM(dbo.Rimuove_Spazi_CR_LF(p.Email))),150), LEFT(LTRIM(RTRIM(dbo.Rimuove_Spazi_CR_LF(p.Telefono))),50), LEFT(LTRIM(RTRIM(p.CAP)),10), LEFT(LTRIM(RTRIM(p.Negozio)),150), LEFT(dbo.Rimuove_Spazi_CR_LF(p.TargaVeicolo),20), LEFT(LTRIM(RTRIM(p.Marca)),50), LEFT(LTRIM(RTRIM(p.Modello)),50), LEFT(LTRIM(RTRIM(p.TipoPreventivo)),50), LEFT(LTRIM(RTRIM(p.Larghezza)),10), LEFT(LTRIM(RTRIM(p.Spalla)),10), LEFT(LTRIM(RTRIM(p.Diametro)),10), LEFT(LTRIM(RTRIM(p.CodCar)),10), LEFT(LTRIM(RTRIM(p.CodVel)),10), LEFT(LTRIM(RTRIM(p.Stagionalita)),50), LEFT(LTRIM(RTRIM(p.NrPneumatici)),10), LEFT(LTRIM(RTRIM(p.FasciaDiPrezzo)),80), LEFT(LTRIM(RTRIM(p.Km)),10), LEFT(LTRIM(RTRIM(p.TipoManutenzione)),100), LEFT(LTRIM(RTRIM(p.LarghezzaMotoAnt)),10), LEFT(LTRIM(RTRIM(p.SpallaMotoAnt)),10), LEFT(LTRIM(RTRIM(p.DiametroMotoAnt)),10), LEFT(LTRIM(RTRIM(p.CodCarMotoAnt)),10), LEFT(LTRIM(RTRIM(p.CodVelMotoAnt)),10), LEFT(LTRIM(RTRIM(p.LarghezzaMotoPost)),10), LEFT(LTRIM(RTRIM(p.SpallaMotoPost)),10), LEFT(LTRIM(RTRIM(p.DiametroMotoPost)),10), LEFT(LTRIM(RTRIM(p.CodCarMotoPost)),10), LEFT(LTRIM(RTRIM(p.CodVelMotoPost)),10), p.CorpoMessaggio
			FROM (SELECT
					*
				   ,ROW_NUMBER() OVER (PARTITION BY DataRichiesta, Nome, Cognome, Email, TipoPreventivo, TargaVeicolo, Stagionalita, FasciaDiPrezzo ORDER BY (SELECT
							NULL)
					) AS RowNum  -- Definisce i campi per identificare i duplicati in PreventivoWebJson
				FROM PreventivoWebJson) AS p
			WHERE p.RowNum = 1  -- Seleziona solo la prima riga per ogni gruppo di duplicati in PreventivoWebJson
			AND NOT EXISTS (
    SELECT 1
    FROM PreventiviWeb pw
    WHERE
        -- Gestione di DataRichiesta
        (
            (p.DataRichiesta IS NULL AND pw.DataRichiesta IS NULL) OR
            (p.DataRichiesta IS NOT NULL AND pw.DataRichiesta IS NOT NULL AND pw.DataRichiesta = p.DataRichiesta)
        )
        -- Gestione di Nome
        AND (
            (p.Nome IS NULL AND pw.Nome IS NULL) OR
            (p.Nome IS NOT NULL AND pw.Nome IS NOT NULL AND pw.Nome = p.Nome)
        )
        -- Gestione di Cognome
        AND (
            (p.Cognome IS NULL AND pw.Cognome IS NULL) OR
            (p.Cognome IS NOT NULL AND pw.Cognome IS NOT NULL AND pw.Cognome = p.Cognome)
        )
        -- Gestione di Email
        AND (
            (p.Email IS NULL AND pw.Email IS NULL) OR
            (p.Email IS NOT NULL AND pw.Email IS NOT NULL AND pw.Email = p.Email)
        )
        -- Gestione di Telefono
        AND (
            (p.Telefono IS NULL AND pw.Telefono IS NULL) OR
            (p.Telefono IS NOT NULL AND pw.Telefono IS NOT NULL AND pw.Telefono = p.Telefono)
        )
        -- Gestione di CAP
        AND (
            (p.CAP IS NULL AND pw.CAP IS NULL) OR
            (p.CAP IS NOT NULL AND pw.CAP IS NOT NULL AND pw.CAP = p.CAP)
        )
        -- Gestione di Negozio
        AND (
            (p.Negozio IS NULL AND pw.Negozio IS NULL) OR
            (p.Negozio IS NOT NULL AND pw.Negozio IS NOT NULL AND pw.Negozio = p.Negozio)
        )
        -- Gestione di TargaVeicolo (con gestione aggiuntiva di stringhe vuote)
        AND (
            (p.TargaVeicolo IS NULL AND pw.TargaVeicolo IS NULL) OR
            (p.TargaVeicolo IS NOT NULL AND pw.TargaVeicolo IS NOT NULL AND pw.TargaVeicolo = p.TargaVeicolo) OR
            (p.TargaVeicolo = '' AND pw.TargaVeicolo IS NULL) OR
            (p.TargaVeicolo IS NULL AND pw.TargaVeicolo = '')      OR
            (p.TargaVeicolo = '' AND pw.TargaVeicolo = '')
        )
        -- Gestione di Marca
        AND (
            (p.Marca IS NULL AND pw.Marca IS NULL) OR
            (p.Marca IS NOT NULL AND pw.Marca IS NOT NULL AND pw.Marca = p.Marca)
        )
        -- Gestione di Modello
        AND (
            (p.Modello IS NULL AND pw.Modello IS NULL) OR
            (p.Modello IS NOT NULL AND pw.Modello IS NOT NULL AND pw.Modello = p.Modello)
        )
        -- Gestione di TipoPreventivo
        AND (
            (p.TipoPreventivo IS NULL AND pw.TipoPreventivo IS NULL) OR
            (p.TipoPreventivo IS NOT NULL AND pw.TipoPreventivo IS NOT NULL AND pw.TipoPreventivo = p.TipoPreventivo)
        )
        -- Gestione di Larghezza
        AND (
            (p.Larghezza IS NULL AND pw.Larghezza IS NULL) OR
            (p.Larghezza IS NOT NULL AND pw.Larghezza IS NOT NULL AND pw.Larghezza = p.Larghezza)
        )
        -- Gestione di Spalla
        AND (
            (p.Spalla IS NULL AND pw.Spalla IS NULL) OR
            (p.Spalla IS NOT NULL AND pw.Spalla IS NOT NULL AND pw.Spalla = p.Spalla)
        )
        -- Gestione di Diametro
        AND (
            (p.Diametro IS NULL AND pw.Diametro IS NULL) OR
            (p.Diametro IS NOT NULL AND pw.Diametro IS NOT NULL AND pw.Diametro = p.Diametro)
        )
        -- Gestione di CodCar
        AND (
            (p.CodCar IS NULL AND pw.CodCar IS NULL) OR
            (p.CodCar IS NOT NULL AND pw.CodCar IS NOT NULL AND pw.CodCar = p.CodCar)
        )
        -- Gestione di CodVel
        AND (
            (p.CodVel IS NULL AND pw.CodVel IS NULL) OR
            (p.CodVel IS NOT NULL AND pw.CodVel IS NOT NULL AND pw.CodVel = p.CodVel)
        )
        -- Gestione di Stagionalita
        AND (
            (p.Stagionalita IS NULL AND pw.Stagionalita IS NULL) OR
            (p.Stagionalita IS NOT NULL AND pw.Stagionalita IS NOT NULL AND pw.Stagionalita = p.Stagionalita)
        )
		-- Gestione NrPneumatici
        AND (
            (p.NrPneumatici IS NULL AND pw.NrPneumatici IS NULL) OR
            (p.NrPneumatici IS NOT NULL AND pw.NrPneumatici IS NOT NULL AND pw.NrPneumatici = p.NrPneumatici)
        )
        -- Gestione di FasciaDiPrezzo
        AND (
            (p.FasciaDiPrezzo IS NULL AND pw.FasciaDiPrezzo IS NULL) OR
            (p.FasciaDiPrezzo IS NOT NULL AND pw.FasciaDiPrezzo IS NOT NULL AND pw.FasciaDiPrezzo = p.FasciaDiPrezzo)
        )
        -- Gestione di Km
        AND (
            (p.Km IS NULL AND pw.Km IS NULL) OR
            (p.Km IS NOT NULL AND pw.Km IS NOT NULL AND pw.Km = p.Km)
        )
        -- Gestione di TipoManutenzione
        AND (
            (p.TipoManutenzione IS NULL AND pw.TipoManutenzione IS NULL) OR
            (p.TipoManutenzione IS NOT NULL AND pw.TipoManutenzione IS NOT NULL AND pw.TipoManutenzione = p.TipoManutenzione)
        )
        -- Gestione di LarghezzaMotoAnt
        AND (
            (p.LarghezzaMotoAnt IS NULL AND pw.LarghezzaMotoAnt IS NULL) OR
            (p.LarghezzaMotoAnt IS NOT NULL AND pw.LarghezzaMotoAnt IS NOT NULL AND pw.LarghezzaMotoAnt = p.LarghezzaMotoAnt)
        )
        -- Gestione di SpallaMotoAnt
        AND (
            (p.SpallaMotoAnt IS NULL AND pw.SpallaMotoAnt IS NULL) OR
            (p.SpallaMotoAnt IS NOT NULL AND pw.SpallaMotoAnt IS NOT NULL AND pw.SpallaMotoAnt = p.SpallaMotoAnt)
        )
        -- Gestione di DiametroMotoAnt
        AND (
            (p.DiametroMotoAnt IS NULL AND pw.DiametroMotoAnt IS NULL) OR
            (p.DiametroMotoAnt IS NOT NULL AND pw.DiametroMotoAnt IS NOT NULL AND pw.DiametroMotoAnt = p.DiametroMotoAnt)
        )
        -- Gestione di CodCarMotoAnt
        AND (
            (p.CodCarMotoAnt IS NULL AND pw.CodCarMotoAnt IS NULL) OR
            (p.CodCarMotoAnt IS NOT NULL AND pw.CodCarMotoAnt IS NOT NULL AND pw.CodCarMotoAnt = p.CodCarMotoAnt)
        )
        -- Gestione di CodVelMotoAnt
        AND (
            (p.CodVelMotoAnt IS NULL AND pw.CodVelMotoAnt IS NULL) OR
            (p.CodVelMotoAnt IS NOT NULL AND pw.CodVelMotoAnt IS NOT NULL AND pw.CodVelMotoAnt = p.CodVelMotoAnt)
        )
        -- Gestione di LarghezzaMotoPost
        AND (
            (p.LarghezzaMotoPost IS NULL AND pw.LarghezzaMotoPost IS NULL) OR
            (p.LarghezzaMotoPost IS NOT NULL AND pw.LarghezzaMotoPost IS NOT NULL AND pw.LarghezzaMotoPost = p.LarghezzaMotoPost)
        )
        -- Gestione di SpallaMotoPost
        AND (
            (p.SpallaMotoPost IS NULL AND pw.SpallaMotoPost IS NULL) OR
            (p.SpallaMotoPost IS NOT NULL AND pw.SpallaMotoPost IS NOT NULL AND pw.SpallaMotoPost = p.SpallaMotoPost)
        )
        -- Gestione di DiametroMotoPost
        AND (
            (p.DiametroMotoPost IS NULL AND pw.DiametroMotoPost IS NULL) OR
            (p.DiametroMotoPost IS NOT NULL AND pw.DiametroMotoPost IS NOT NULL AND pw.DiametroMotoPost = p.DiametroMotoPost)
        )
        -- Gestione di CodCarMotoPost
        AND (
            (p.CodCarMotoPost IS NULL AND pw.CodCarMotoPost IS NULL) OR
            (p.CodCarMotoPost IS NOT NULL AND pw.CodCarMotoPost IS NOT NULL AND pw.CodCarMotoPost = p.CodCarMotoPost)
        )
        -- Gestione di CodVelMotoPost
        AND (
            (p.CodVelMotoPost IS NULL AND pw.CodVelMotoPost IS NULL) OR
            (p.CodVelMotoPost IS NOT NULL AND pw.CodVelMotoPost IS NOT NULL AND pw.CodVelMotoPost = p.CodVelMotoPost)
        )
        -- Gestione di CorpoMessaggio
        AND (
            (p.CorpoMessaggio IS NULL AND pw.CorpoMessaggio IS NULL) OR
            (p.CorpoMessaggio IS NOT NULL AND pw.CorpoMessaggio IS NOT NULL AND pw.CorpoMessaggio = p.CorpoMessaggio)
        )
);


	-- ===== Gestione ERRORI ===== --
	END TRY
	BEGIN CATCH
		-- Gestione degli errori
		DECLARE @ErrorMessage NVARCHAR(4000);
		DECLARE @ErrorSeverity INT;
		DECLARE @ErrorState INT;
		DECLARE @Errorline VARCHAR(50)
		DECLARE @ErrorProcedure VARCHAR(50)

		SELECT
			@ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @Errorline = ERROR_LINE(), @ErrorProcedure = ERROR_PROCEDURE()

		-- Invia un'email di notifica
		SET @body = 'Si è verificato un errore durante l''importazione del file JSON: ' + @ErrorMessage + ' Linea: ' + @Errorline + ' Stored: ' + @ErrorProcedure
		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SQL'
									,@recipients = @to_mails
									,@subject = 'Errore durante l''importazione JSON PreventiviWeb'
									,@body = @body

		-- Rilancia l'errore
		RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState, @Errorline, @ErrorProcedure);
	END CATCH

	-- ===================================================================
	-- SCRIPT PRINCIPALE IMPORTAZIONE E CREAZIONE PREVENTIVI WEB
	-- ===================================================================

	DECLARE
		-- Variabili dal Cursore (Aggiungi quelle mancanti per SP Righe)
		@Nome VARCHAR(80),
		@Cognome VARCHAR(80),
		@Email VARCHAR(250),
		@Cellulare VARCHAR(20),
		@Negozio VARCHAR(150),
		@Targa VARCHAR(20),
		@Marca VARCHAR(50),
		@Modello VARCHAR(50),
		@TipoPreventivo VARCHAR(50),
		@FasciaDiPrezzo VARCHAR(50),
		@MisuraVettura VARCHAR(20),
		@MisuraMotoAnt VARCHAR(20),
		@MisuraMotoPost VARCHAR(20),
		@CodCar VARCHAR(6),
		@CodVel VARCHAR(6),
		@CodCarMotoAnt VARCHAR(6),
		@CodCarMotoPost VARCHAR(6),
		@CodVelMotoAnt VARCHAR(6),
		@CodVelMotoPost VARCHAR(6),
		@Stagione VARCHAR(1),
		@Qta INT,
		@Km VARCHAR(10),
		@TipoManutenzione VARCHAR(50),
		@NoteInput VARCHAR(MAX), 

		-- Variabili Logiche Interne
		@IdAnagrafica INT,
		@IdVeicolo INT,
		@IdVeicoloEsistenteConTarga INT, -- Per tracciare se il veicolo è stato trovato TRAMITE targa
		@IdAnagraficaEsistente INT,    -- Per tracciare se l'anagrafica è stata trovata
		@Pdv VARCHAR(10),             -- Da Mappare da @Negozio
		@EmailUtilizzatoreEsistente VARCHAR(250),
		@CellulareUtilizzatoreEsistente VARCHAR(20),
		@IdPreventivoProduzione INT,
		@TargaPlaceholder VARCHAR(10) = 'GEN', -- O altro valore standard per targa generica/mancante
		@Errore NVARCHAR(MAX),
		@DataCorrente DATETIME = GETDATE(),
		@ID INT;

	-- Assicurati che il cursore selezioni TUTTI i campi necessari da PreventiviWeb

	DECLARE cur CURSOR FAST_FORWARD READ_ONLY LOCAL FOR
	SELECT
		pw.ID,
		pw.Nome,
		pw.Cognome,
		pw.Email,
		pw.Telefono,
		pw.Negozio,
		pw.TargaVeicolo,
		pw.Marca,
		pw.Modello,
		pw.TipoPreventivo,
		pw.FasciaDiPrezzo,
		ISNULL(LTRIM(RTRIM(pw.Larghezza)),'') + ISNULL(LTRIM(RTRIM(pw.Spalla)),'') + ISNULL(LTRIM(RTRIM(pw.Diametro)),''),
		pw.CodCar,
		pw.CodVel,
		pw.Stagionalita,
		pw.NrPneumatici,
		ISNULL(LTRIM(RTRIM(pw.LarghezzaMotoAnt)),'') + ISNULL(LTRIM(RTRIM(pw.SpallaMotoAnt)),'') + ISNULL(LTRIM(RTRIM(pw.DiametroMotoAnt)),''),
		pw.CodCarMotoAnt,
		pw.CodVelMotoAnt,
		ISNULL(LTRIM(RTRIM(pw.LarghezzaMotoPost)),'') + ISNULL(LTRIM(RTRIM(pw.SpallaMotoPost)),'') + ISNULL(LTRIM(RTRIM(pw.DiametroMotoPost)),''),
		pw.CodCarMotoPost,
		pw.CodVelMotoPost,
		pw.Km,
		pw.TipoManutenzione,
		pw.CorpoMessaggio
	FROM
		PreventiviWeb pw
	WHERE
		(pw.Elaborato IS NULL OR pw.Elaborato = 0);

	OPEN cur;

	FETCH NEXT FROM cur INTO @ID, @Nome, @Cognome, @Email, @Cellulare, @Negozio, @Targa, @Marca, @Modello, @TipoPreventivo, @FasciaDiPrezzo, @MisuraVettura, @CodCar, @CodVel, @Stagione, @Qta, @MisuraMotoAnt, @CodCarMotoAnt, @CodVelMotoAnt, @MisuraMotoPost, @CodCarMotoPost, @CodVelMotoPost, @Km, @TipoManutenzione, @NoteInput;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		-- Reset variabili per ogni ciclo
		SET @IdAnagrafica = NULL;
		SET @IdVeicolo = NULL;
		SET @IdVeicoloEsistenteConTarga = NULL;
		SET @IdAnagraficaEsistente = NULL;
		SET @EmailUtilizzatoreEsistente = NULL;
		SET @CellulareUtilizzatoreEsistente = NULL;
		SET @IdPreventivoProduzione = NULL;
		SET @Errore = NULL;
		SET @Pdv = NULL; -- Resetta anche il PDV

		-- Inizio Transazione per la singola richiesta web
		BEGIN TRAN ProcessaRichiestaWeb;

		BEGIN TRY

			-- ------------------------------------
			-- 1. Validazione e Pulizia Campi
			-- ------------------------------------
			SET @Email = LTRIM(RTRIM(NULLIF(LOWER(@Email), ''))); -- Pulisci e metti in minuscolo, NULL se vuoto
			SET @Cellulare = LTRIM(RTRIM(NULLIF(@Cellulare, '')));
			SET @Targa = LTRIM(RTRIM(NULLIF(UPPER(@Targa), ''))); -- Pulisci e metti in maiuscolo, NULL se vuoto
			SET @Nome = LTRIM(RTRIM(NULLIF(@Nome, '')));
			SET @Cognome = LTRIM(RTRIM(NULLIF(@Cognome, '')));

			SET @Qta = ISNULL(@Qta,4) -- Metto 4 se non hanno specificato la Qta

			-- Validazione Formato Email (base)
			IF @Email IS NOT NULL AND (LEN(@Email) - LEN(REPLACE(@Email, '@', '')) <> 1 OR CHARINDEX('.', @Email, CHARINDEX('@', @Email)) = 0 OR CHARINDEX('@',@Email) = 1 OR CHARINDEX('.', REVERSE(@Email)) = 1)
			BEGIN
				 -- Considera l'email non valida, potresti loggarla o scartarla
				 -- Per ora la mettiamo a NULL per seguire il flusso, ma potresti voler gestire diversamente
				 -- SET @Errore = 'Formato Email non valido: ' + @Email; RAISERROR(@Errore, 16, 1);
				 SET @Email = NULL;
			END

			-- Validazione Formato Cellulare (base)
			IF @Cellulare IS NOT NULL AND (LEN(@Cellulare) < 9 OR LEN(@Cellulare) > 15 OR ISNUMERIC(REPLACE(REPLACE(REPLACE(@Cellulare,'+',''),' ',''),'-','')) = 0 ) -- Tolleriamo +, spazi, trattini ma il resto deve essere numerico
			BEGIN
				 -- Considera cellulare non valido
				 -- SET @Errore = 'Formato Cellulare non valido: ' + @Cellulare; RAISERROR(@Errore, 16, 1);
				 SET @Cellulare = NULL;
			END

			-- Validazione/Gestione Targa
			IF @Targa IS NULL OR LEN(@Targa) < 5 OR LEN(@Targa) > 8 -- Lunghezza base, adatta se necessario
			BEGIN
				SET @Targa = @TargaPlaceholder; -- Imposta la targa generica se non valida o mancante
			END
			ELSE IF @Targa = 'DAIMMATRICOLARE' -- Esempio di altra targa generica
			BEGIN
				 SET @Targa = @TargaPlaceholder;
			END
			-- Aggiungi qui altre logiche per targhe specifiche se necessario

			-- Mappatura Negozio -> PDV
			SET @Pdv = CASE
						   WHEN @Negozio LIKE '%BG1%' THEN 'BG1'
						   WHEN @Negozio LIKE '%BG2%' THEN 'BG2'
						   WHEN @Negozio LIKE '%BG3%' THEN 'BG3'
						   WHEN @Negozio LIKE '%BG4%' THEN 'BG4'
						   WHEN @Negozio LIKE '%BG5%' THEN 'BG5'
						   WHEN @Negozio LIKE '%BG6%' THEN 'BG6'
						   WHEN @Negozio LIKE '%BG7%' THEN 'BG7'

						   ELSE 'BG1' -- Punto vendita di default
					   END;

			-- ------------------------------------
			-- 2. Ricerca Veicolo per Targa (se non è generica)
			-- ------------------------------------
			IF @Targa <> @TargaPlaceholder -- Targa Generica
			BEGIN
				SELECT TOP 1 -- Se ci fossero duplicati di targa (improbabile ma non si sa mai)
					   @IdVeicolo = v.IdVeicolo,
					   @IdAnagrafica = v.V_IdAnagrafica, -- Prendo l'anagrafica collegata al veicolo
					   @CellulareUtilizzatoreEsistente = v.V_TelefonoUtiliz, -- Prendo il Telefono dell'Utilizzatore esistente in DB
					   @EmailUtilizzatoreEsistente = v.V_EmailUtiliz -- Prendo Email dell'Utilizzatore esistente in DB
				FROM   Veicolo v
				WHERE  v.Targa = @Targa;

				IF @IdVeicolo IS NOT NULL
				BEGIN
					SET @IdVeicoloEsistenteConTarga = @IdVeicolo; -- Marco che l'ho trovato via targa

					-- Opzione 1 Uso l'anagrafica collegata al veicolo trovato.
					SET @IdAnagraficaEsistente = @IdAnagrafica;

					-- Opzione 2: Se il telefono differisce, Aggiorno i Dati Utilizzatore con quelli Del WEB
					IF (@Cellulare IS NOT NULL AND @Cellulare <> @CellulareUtilizzatoreEsistente) OR (@Cellulare IS NOT NULL AND @CellulareUtilizzatoreEsistente IS NULL)
					BEGIN
						UPDATE Veicolo
							SET V_TelefonoUtiliz = @Cellulare,
								V_EmailUtiliz = (CASE WHEN @Email IS NOT NULL THEN @Email ELSE V_EmailUtiliz END),
								V_NomeUtiliz = (CASE WHEN @Nome IS NOT NULL THEN @Nome ELSE V_NomeUtiliz END),
								V_CognomeUtiliz = (CASE WHEN @Cognome IS NOT NULL THEN @Cognome ELSE V_CognomeUtiliz END)
						WHERE IdVeicolo = @IdVeicolo
					END

					-- Opzione 3: Se email differisce, Aggiorno i Dati Utilizzatore con quelli Del WEB
					IF (@Email IS NOT NULL AND @Email <> @EmailUtilizzatoreEsistente) OR (@Email IS NOT NULL AND @EmailUtilizzatoreEsistente IS NULL)
					BEGIN
						UPDATE Veicolo
							SET V_TelefonoUtiliz = @Cellulare,
								V_EmailUtiliz = (CASE WHEN @Email IS NOT NULL THEN @Email ELSE V_EmailUtiliz END),
								V_NomeUtiliz = (CASE WHEN @Nome IS NOT NULL THEN @Nome ELSE V_NomeUtiliz END),
								V_CognomeUtiliz = (CASE WHEN @Cognome IS NOT NULL THEN @Cognome ELSE V_CognomeUtiliz END)
						WHERE IdVeicolo = @IdVeicolo
					END

					PRINT 'INFO: Trovata Anagrafica (' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ') via Targa:(' + @Targa + ') Email: ' + @Email;
					SET @Body = 'INFO: Trovata Anagrafica (' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ') via Targa:(' + @Targa + ') Email: ' + @Email;
					SET @Subject = 'Trovata Anagrafica (' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ') via Targa:(' + @Targa + ')'
				END
			END

			-- ----------------------------------------------------------
			-- 3. Ricerca/Creazione Anagrafica (se non trovata con il Veicolo)
			-- ----------------------------------------------------------
			IF @IdAnagraficaEsistente IS NULL -- Non ho trovato un veicolo con targa O la targa era generica
			BEGIN
				-- Seguiamo il flusso del diagramma "NON ESISTE" (targa)

				-- 3.1 Cerco per Cellulare (se presente)
				IF @Cellulare IS NOT NULL
				BEGIN
					SELECT TOP 1 -- Gestisce eventuali duplicati di cellulare, prendendo il primo su Tipocliente "Privato" non Leasing altrimenti la Creo nuova
						   @IdAnagrafica = v.v_IdAnagrafica,
						   @EmailUtilizzatoreEsistente = v.V_EmailUtiliz,
						   @CellulareUtilizzatoreEsistente = v.V_TelefonoUtiliz
					FROM   Veicolo v
						INNER JOIN Anagrafica a ON a.IDAnagrafica = v.V_IdAnagrafica
					WHERE  v.V_TelefonoUtiliz = @Cellulare
						AND (v.V_LeasingCompany IS NULL OR v.V_LeasingCompany = '')
						AND a.TipoCliente = 'PRIVATO'
					ORDER BY v.V_IdAnagrafica DESC

					IF @IdAnagrafica IS NOT NULL -- Trovata Anagrafica per Telefono
					BEGIN
						SET @IdAnagraficaEsistente = @IdAnagrafica;
						
						-- Se necessario, popolare un campo PR_EmailInvio in PreventivoTesta con @Email.
						PRINT 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono. Email diversa o mancante in anagrafica. Email richiesta: ' + ISNULL(@Email,'');
						SET @Body = 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono. Email diversa o mancante in anagrafica. Email richiesta: ' + ISNULL(@Email,'');
						SET @subject = 'Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono: (' + ISNULL(@Cellulare,'') + ')';

						-- Logica di Aggiornamento Dati
						IF @Email IS NOT NULL AND ISNULL(@EmailUtilizzatoreEsistente, '') <> @Email
						BEGIN
							UPDATE Veicolo
							SET V_EmailUtiliz = (CASE WHEN @Email IS NOT NULL THEN @Email ELSE V_EmailUtiliz END),
								V_NomeUtiliz = (CASE WHEN @Nome IS NOT NULL THEN @Nome ELSE V_NomeUtiliz END),
								V_CognomeUtiliz = (CASE WHEN @Cognome IS NOT NULL THEN @Cognome ELSE V_CognomeUtiliz END)
							WHERE IdVeicolo = @IdVeicolo
							-- Se necessario, popolare un campo PR_EmailInvio in PreventivoTesta con @Email.
							PRINT 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono. Email diversa o mancante in anagrafica. Email richiesta: ' + @Email;
							SET @Body = 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono. Email diversa o mancante in anagrafica. Email richiesta: ' + @Email;
							SET @subject = 'Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via telefono: (' + @Cellulare + ')';
						END

						-- Se non ho trovato un veicolo valido per questa anagrafica, ne creo uno nuovo
						IF @IdVeicolo IS NULL OR @IdVeicolo = 0
						BEGIN
							-- Se la Targa è generica, genero una targa univoca
							IF @Targa = @TargaPlaceholder BEGIN
								SET @Targa = 'GEN' + CAST(@IdAnagrafica AS VARCHAR(10))

								-- Verifico se esiste già la Targa Generica --
								SET @IdVeicolo = (SELECT v.IdVeicolo FROM Veicolo v WHERE v.Targa = @Targa)
							END
							-- Altrimenti uso la targa fornita dal cliente
							
							IF @IdVeicolo IS NULL BEGIN
								-- Creo il Veicolo --
								INSERT INTO Veicolo (V_IdAnagrafica, TipologiaVeicolo, Targa, Marca, Modello, V_NomeUtiliz, V_CognomeUtiliz, V_TelefonoUtiliz, V_EmailUtiliz, V_InseritoData, V_InseritoPdv, V_InseritoNome, V_Archiviato)
									VALUES
									(@IdAnagrafica, 'Vettura', @Targa, (CASE WHEN @Marca IS NULL OR @Marca = '' THEN 'GEN' ELSE @Marca END), (CASE WHEN @Modello IS NULL OR @Modello = '' THEN 'GEN' ELSE @Modello END), @Nome, @Cognome, @Cellulare, @Email, GETDATE(), 'WEB', 'PREVENTIVO WEB', 'NO')

								SET @IdVeicolo = SCOPE_IDENTITY()
							END

							SET @IdVeicoloEsistenteConTarga = @IdVeicolo

							PRINT 'INFO: Creato nuovo Veicolo con ID: ' + CAST(@IdVeicolo AS VARCHAR) + ' per Anagrafica esistente ID: ' + CAST(@IdAnagrafica AS VARCHAR) + ' con Targa: ' + @Targa;
							SET @Body = ISNULL(@body,'') + CHAR(10) + CHAR(13) + 'INFO: Creato nuovo Veicolo con ID: ' + CAST(@IdVeicolo AS VARCHAR) + ' per Anagrafica esistente ID: ' + CAST(@IdAnagrafica AS VARCHAR) + ' con Targa: ' + @Targa;
						END
						ELSE
						BEGIN
							SET @IdVeicoloEsistenteConTarga = @IdVeicolo
						END
					END
				END

				-- 3.2 Se non trovata per Cellulare, Cerco per Email (se presente e Anagrafica non ancora trovata)
				IF @IdAnagraficaEsistente IS NULL AND @Email IS NOT NULL
				BEGIN
					SELECT TOP 1
						   @IdAnagrafica = a.IdAnagrafica,
						   @EmailUtilizzatoreEsistente = v.V_EmailUtiliz,
						   @CellulareUtilizzatoreEsistente = v.V_TelefonoUtiliz
					FROM   Veicolo v
						INNER JOIN Anagrafica a ON a.IDAnagrafica = v.V_IdAnagrafica
					WHERE  v.V_EmailUtiliz = @Email
					AND (v.V_LeasingCompany IS NULL OR v.V_LeasingCompany = '')
						AND a.TipoCliente = 'PRIVATO'
					ORDER BY v.V_IdAnagrafica DESC;

					IF @IdAnagrafica IS NOT NULL -- Trovata Anagrafica per Email
					BEGIN
						SET @IdAnagraficaEsistente = @IdAnagrafica;
						-- Diagramma: ESISTE MAIL -> INSERIRE TELEFONO (se presente nella richiesta e diverso/mancante)
						IF @Cellulare IS NOT NULL AND ISNULL(@CellulareUtilizzatoreEsistente, '') <> @Cellulare
						BEGIN
							-- Aggiorniamo i Dati Utilizzatore
							UPDATE Veicolo
							SET V_EmailUtiliz = (CASE WHEN @Email IS NOT NULL THEN @Email ELSE V_EmailUtiliz END),
								V_NomeUtiliz = (CASE WHEN @Nome IS NOT NULL THEN @Nome ELSE V_NomeUtiliz END),
								V_CognomeUtiliz = (CASE WHEN @Cognome IS NOT NULL THEN @Cognome ELSE V_CognomeUtiliz END)
							WHERE IdVeicolo = @IdVeicolo
							PRINT 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via email. Cellulare diverso o mancante in anagrafica. Cellulare richiesta: ' + @Cellulare;
							SET @Body = 'INFO: Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via email. Cellulare diverso o mancante in anagrafica. Cellulare richiesta: ' + @Cellulare;
							SET @subject = 'Trovata Anagrafica ' + CAST(@IdAnagraficaEsistente AS VARCHAR) + ' via email: ' + @Email;
						END

						-- Se non ho trovato un veicolo valido per questa anagrafica, ne creo uno nuovo
						IF @IdVeicolo IS NULL OR @IdVeicolo = 0
						BEGIN
							-- Se la Targa è generica, genero una targa univoca
							IF @Targa = @TargaPlaceholder BEGIN
								SET @Targa = 'GEN' + CAST(@IdAnagrafica AS VARCHAR(10))

								-- Verifico se esiste già la Targa Generica --
								SET @IdVeicolo = (SELECT v.IdVeicolo FROM Veicolo v WHERE v.Targa = @Targa)
							END
							-- Altrimenti uso la targa fornita dal cliente
							
							IF @IdVeicolo IS NULL BEGIN
								
								-- Creo il Veicolo --
								INSERT INTO Veicolo (V_IdAnagrafica, TipologiaVeicolo, Targa, Marca, Modello, V_NomeUtiliz, V_CognomeUtiliz, V_TelefonoUtiliz, V_EmailUtiliz, V_InseritoData, V_InseritoPdv, V_InseritoNome, V_Archiviato)
									VALUES
									(@IdAnagrafica, 'Vettura', @Targa, (CASE WHEN @Marca IS NULL OR @Marca = '' THEN 'GEN' ELSE @Marca END), (CASE WHEN @Modello IS NULL OR @Modello = '' THEN 'GEN' ELSE @Modello END), @Nome, @Cognome, @Cellulare, @Email, GETDATE(), 'WEB', 'PREVENTIVO WEB', 'NO')

								SET @IdVeicolo = SCOPE_IDENTITY()
							END

							SET @IdVeicoloEsistenteConTarga = @IdVeicolo

							PRINT 'INFO: Creato nuovo Veicolo con ID: ' + CAST(@IdVeicolo AS VARCHAR) + ' per Anagrafica esistente ID: ' + CAST(@IdAnagrafica AS VARCHAR) + ' con Targa: ' + @Targa;
							SET @Body = ISNULL(@body,'') + CHAR(10) + CHAR(13) + 'INFO: Creato nuovo Veicolo con ID: ' + CAST(@IdVeicolo AS VARCHAR) + ' per Anagrafica esistente ID: ' + CAST(@IdAnagrafica AS VARCHAR) + ' con Targa: ' + @Targa;
						END
						ELSE
						BEGIN
							SET @IdVeicoloEsistenteConTarga = @IdVeicolo
						END
					END
				END

				-- 3.3 Se Anagrafica ancora non trovata -> Crea Nuova Anagrafica
				IF @IdAnagraficaEsistente IS NULL
				BEGIN
					-- Verifico se ho almeno Nome o Cognome per creare un minimo di anagrafica
					IF @Nome IS NOT NULL OR @Cognome IS NOT NULL
					BEGIN
						INSERT INTO Anagrafica (Nome, Cognome, Email1, Mobile1, TipoCliente, A_Canale, A_InseritodaPdv, NoteAnagrafica, A_InseritoNome)
						VALUES (@Nome, @Cognome, @Email, @Cellulare,'PRIVATO','SITO BG','WEB','CREATA DA PREVENTIVO WEB','PREVENTIVO WEB');

						SET @IdAnagrafica = SCOPE_IDENTITY();
						SET @IdAnagraficaEsistente = @IdAnagrafica; -- Ora abbiamo un'anagrafica (nuova)

						-- Se la Targa non era Presente Genero la GENERICA --
						IF @Targa = @TargaPlaceholder BEGIN
							SET @Targa = 'GEN' + CAST(@IdAnagrafica AS VARCHAR(10))

							-- Verifico se esiste già la Targa Generica --
								SET @IdVeicolo = (SELECT v.IdVeicolo FROM Veicolo v WHERE v.Targa = @Targa)
						END
						
						IF @IdVeicolo IS NULL BEGIN
							-- Creo il Veicolo --
							INSERT INTO Veicolo (V_IdAnagrafica, TipologiaVeicolo, Targa, Marca, Modello, V_NomeUtiliz, V_CognomeUtiliz, V_TelefonoUtiliz, V_EmailUtiliz, V_InseritoData, V_InseritoPdv, V_InseritoNome, V_Archiviato)
								VALUES
								(@IdAnagrafica, 'Vettura', @Targa, (CASE WHEN @Marca IS NULL OR @Marca = '' THEN 'GEN' ELSE @Marca END), (CASE WHEN @Modello IS NULL OR @Modello = '' THEN 'GEN' ELSE @Modello END), @Nome, @Cognome, @Cellulare, @Email, GETDATE(), 'WEB', 'PREVENTIVO WEB', 'NO')

							SET @IdVeicolo = SCOPE_IDENTITY() -- Ora abbiamo un Veicolo (nuovo)
						END

						SET @IdVeicoloEsistenteConTarga = @IdVeicolo -- Uso questa variabile per il Preventivo

						PRINT 'INFO: Creata nuova Anagrafica con ID: ' + CAST(@IdAnagraficaEsistente AS VARCHAR);
						SET @Body = 'INFO: Creata nuova Anagrafica con ID: ' + CAST(@IdAnagraficaEsistente AS VARCHAR);
						SET @subject = 'Creata nuova Anagrafica con ID: ' + CAST(@IdAnagraficaEsistente AS VARCHAR);
					END
					ELSE
					BEGIN
						-- Non ho dati sufficienti per creare un'anagrafica sensata.
						-- Cosa fare? Scartare la richiesta? Loggare? Assegnare ad anagrafica generica?
						SET @Errore = 'Dati insufficienti (Nome/Cognome mancanti) per creare nuova anagrafica. Richiesta Web non processata.';
						SET @Body = 'Dati insufficienti (Nome/Cognome mancanti) per creare nuova anagrafica. Richiesta Web non processata.' + CHAR(10) + CHAR(13) + 'Dati passati:'
						+ CHAR(10) + CHAR(13) + 'Email: ' + ISNULL(@Email,'') + CHAR(10) + CHAR(13) + 'Cellulare: ' + ISNULL(@Cellulare,'') + CHAR(10) + CHAR(13) + 'ID PreventiviWeb: ' + CAST(ISNULL(@ID,'') AS VARCHAR(20))
						SET @subject = 'Dati insufficienti (Nome/Cognome mancanti) per creare nuova anagrafica. Richiesta Web non processata.';
						RAISERROR(@Errore, 16, 1); -- Questo causerà un ROLLBACK nel CATCH
					END
				END
			END -- Fine blocco ricerca/creazione Anagrafica

			-- A questo punto DOVREI avere @IdAnagraficaEsistente valorizzato (o un errore è stato sollevato)
			-- e POTREI avere @IdVeicoloEsistenteConTarga valorizzato.

			-- ------------------------------------
			-- 4. Creazione Testa Preventivo
			-- ------------------------------------
			IF @IdAnagraficaEsistente IS NOT NULL
			BEGIN
			
				DECLARE @NoteRiepilogoWeb VARCHAR(MAX) =
					'--- Riepilogo Richiesta Web Originale ---' + CHAR(13) + CHAR(10) +
					'Nome: '           + ISNULL(LTRIM(RTRIM(@Nome)), 'Non fornito') + CHAR(13) + CHAR(10) +
					'Cognome: '        + ISNULL(LTRIM(RTRIM(@Cognome)), 'Non fornito') + CHAR(13) + CHAR(10) +
					'Email: '          + ISNULL(LTRIM(RTRIM(@Email)), 'Non fornita') + CHAR(13) + CHAR(10) +
					'Cellulare: '      + ISNULL(LTRIM(RTRIM(@Cellulare)), 'Non fornito') + CHAR(13) + CHAR(10) +
					'Negozio Rich.: '  + ISNULL(LTRIM(RTRIM(@Negozio)), 'Non specificato') + CHAR(13) + CHAR(10) +
					'Targa: '          + ISNULL(LTRIM(RTRIM(@Targa)), 'Non fornita') + CHAR(13) + CHAR(10) +
					'Marca: '          + ISNULL(LTRIM(RTRIM(@Marca)), 'Non specificata') + CHAR(13) + CHAR(10) +
					'Modello: '        + ISNULL(LTRIM(RTRIM(@Modello)), 'Non specificato') + CHAR(13) + CHAR(10) +
					'Tipo Richiesta: ' + ISNULL(LTRIM(RTRIM(@TipoPreventivo)), 'Non specificato') + CHAR(13) + CHAR(10) +
					'Fascia di Prezzo: ' + ISNULL(LTRIM(RTRIM(@FasciaDiPrezzo)), 'Non specificato') + CHAR(13) + CHAR(10) +
					'--- Dettagli Pneumatici ---' + CHAR(13) + CHAR(10) +
					'Misura Vettura: ' + ISNULL(LTRIM(RTRIM(@MisuraVettura)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Car Vettura: '+ ISNULL(LTRIM(RTRIM(@CodCar)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Vel Vettura: '+ ISNULL(LTRIM(RTRIM(@CodVel)), 'N/D') + CHAR(13) + CHAR(10) +
					'Stagione: '       + ISNULL(LTRIM(RTRIM(@Stagione)), 'N/D') + CHAR(13) + CHAR(10) +
					'Qta: '            + ISNULL(CAST(@Qta AS VARCHAR(10)), 'N/D') + CHAR(13) + CHAR(10) + -- Converti INT a VARCHAR
					'Misura Moto Ant: '+ ISNULL(LTRIM(RTRIM(@MisuraMotoAnt)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Car Moto Ant:'+ ISNULL(LTRIM(RTRIM(@CodCarMotoAnt)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Vel Moto Ant:'+ ISNULL(LTRIM(RTRIM(@CodVelMotoAnt)), 'N/D') + CHAR(13) + CHAR(10) +
					'Misura Moto Post:'+ ISNULL(LTRIM(RTRIM(@MisuraMotoPost)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Car Moto Post:'+ ISNULL(LTRIM(RTRIM(@CodCarMotoPost)), 'N/D') + CHAR(13) + CHAR(10) +
					'Cod.Vel Moto Post:'+ ISNULL(LTRIM(RTRIM(@CodVelMotoPost)), 'N/D') + CHAR(13) + CHAR(10) +
					'--- Meccanica ---' + CHAR(13) + CHAR(10) +
					'Km: '           + ISNULL(LTRIM(RTRIM(@Km)), 'N/D') + CHAR(13) + CHAR(10) +
					'Tipo Manutenzione: '           + ISNULL(LTRIM(RTRIM(@TipoManutenzione)), 'N/D') + CHAR(13) + CHAR(10) +
					'--- Note Originali Cliente ---' + CHAR(13) + CHAR(10) +
					ISNULL(LTRIM(RTRIM(@NoteInput)), 'Nessuna nota fornita.');

					PRINT @NoteRiepilogoWeb

			DECLARE @SettorePrev VARCHAR(40) = (CASE WHEN @FasciaDiPrezzo LIKE '%USATE%' THEN 'Pneumatici Usati' WHEN @TipoPreventivo = 'Preventivo Pneumatici' THEN 'Pneumatici' WHEN @TipoPreventivo LIKE '%Meccanica%' THEN 'Meccanica' ELSE 'Pneumatici' END)

			DECLARE @TipoVeicolo VARCHAR(40) = (CASE WHEN @TipoPreventivo LIKE '%Moto%' THEN 'Moto/Scooter' ELSE 'Vettura' END)

			-- Se MOTO Controllo se mettere 2 pezzi oppure 1 pezzo nei penuamtici e cercare la promo --
			IF @TipoVeicolo = 'Moto/Scooter' BEGIN
				IF @MisuraMotoPost IS NOT NULL AND @MisuraMotoAnt IS NOT NULL SET @Qta = 2
			END

			-- Creo la Testa Preventivo --
			INSERT INTO PreventivoTesta
				(PR_IdVeicolo, PR_IdAnagrafica, PR_Data, PR_NoteWeb, PR_Cognome, PR_Nome, PR_Mobile, PR_Email, PR_Targa, PR_MarcaVeicolo, PR_ModelloVeicolo, PR_Pdv, PR_MisuraVerificata, PR_TipoVeicolo, PR_CondizionePreventivo, PR_TipoPreventivo, PR_CanalePromo, PR_TipoVeicoloPromo, PR_QtaPromo, PR_StagionePromo, PR_CondPrevData, PR_IvaCompresa, PR_Operatore, PR_Stato, PR_ValiditaPreventivo, PR_SettorePrev)
			SELECT
				@IdVeicoloEsistenteConTarga, @IdAnagraficaEsistente, GETDATE(), ISNULL(LTRIM(RTRIM(@NoteRiepilogoWeb)), '') , @Cognome, @Nome, @Cellulare, @Email, @Targa, @Marca, @Modello, @Pdv, 'WEB', @TipoVeicolo, 'WEB DA ESEGUIRE', 'WEB', 'WEB', @TipoVeicolo, @Qta, (CASE WHEN @Stagione = 'E' THEN 'ESTIVO/4S' WHEN @Stagione = 'I' THEN 'INVERNALE/4S' WHEN @Stagione LIKE '%Q%' THEN 'ESTIVO/4S' ELSE 'ESTIVO/4S' END), GETDATE(), 1, 'PREVENTIVO WEB', 'A', DATEADD(DAY, 15, GETDATE()), @SettorePrev

				SET @IdPreventivoProduzione = SCOPE_IDENTITY();
				PRINT 'INFO: Creata Testa Preventivo ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);

				-- ---------------------------------------------------------- --
				-- 5. Chiamata SP per Creazione Righe (SOLO SE NON MECCANICA)
				-- ---------------------------------------------------------- --
				
				-- Fascia USATE --

				IF @FasciaDiPrezzo LIKE ('%T4 USATE%')
				BEGIN
					-- Verifico che ci siano i campi che servono --
					IF @MisuraVettura IS NOT NULL AND @Stagione IS NOT NULL AND @CodCar IS NOT NULL AND @CodVel IS NOT NULL
					BEGIN
						PRINT 'INFO: Chiamata SP Righe per Preventivo ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);

						-- Esegui la stored procedure passando i parametri necessari
						EXEC SP_PreventiviWebUsateRigheAutomatiche
								@Idpreventivo = @IdPreventivoProduzione,
								@Misura = @MisuraVettura,
								@CodCar = @CodCar,
								@CodVel = @CodVel,
								@Stagione = @Stagione,
								@Qta = @Qta

					END
					ELSE
					BEGIN
						 PRINT 'WARN: Parametri insufficienti (es. Misura) per chiamare SP Righe per Preventivo ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);
					END
				END

				-- Fascie NUOVE --

				IF @FasciaDiPrezzo LIKE ('%T1%') OR @FasciaDiPrezzo LIKE ('%T2%') OR @FasciaDiPrezzo LIKE ('%T3%') OR @FasciaDiPrezzo LIKE ('%T5%')
				BEGIN
					
					IF @Qta IS NOT NULL AND @Stagione IS NOT NULL -- Aggiungi controlli su altri parametri se necessario
					BEGIN
						PRINT 'INFO: Chiamata SP Righe per Preventivo ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);

						-- Esegui la stored procedure passando i parametri necessari
						EXEC SP_PreventiviWebNuoveRigheAutomatiche
								@Idpreventivo = @IdPreventivoProduzione,
								@Misura = @MisuraVettura,
								@CodCar = @CodCar,
								@CodVel = @CodVel,
								@Stagione = @Stagione,
								@Qta = @Qta
					END
					ELSE
					BEGIN
						 PRINT 'WARN: Parametri insufficienti (es. Misura) per chiamare SP Righe per Preventivo ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);
					END
				END

				-- Altre Fascie Prezzo (Meccanica, Moto)
				ELSE
				BEGIN
					 PRINT 'INFO: Tipo Preventivo (' + @TipoPreventivo + ') non richiede generazione righe automatica per ID: ' + CAST(@IdPreventivoProduzione AS VARCHAR);
				END

				-- ------------------------------------
				-- 6. Aggiorna Stato Richiesta Web
				-- ------------------------------------
				-- Aggiorna la riga corrente del cursore per marcarla come elaborata
				UPDATE PreventiviWeb
				SET    Elaborato = 1,
					   DataElaborazione = GETDATE(),
					   IdPreventivoCreato = @IdPreventivoProduzione,
					   NoteSistema = ISNULL(NoteSistema,'') + ISNULL(@body,'Processato OK. ')
				WHERE ID = @ID

				-- Aggiungo il numero Preventivo se esiste --
				IF @IdPreventivoProduzione IS NOT NULL BEGIN

					-- Mappatura Mail Negozio -> PDV
					DECLARE @MailPdv varchar(30) = CASE
						WHEN @Pdv = 'BG1' THEN 'bg1team@bolognagomme.com'
						WHEN @Pdv = 'BG2' THEN 'bg2team@bolognagomme.com'
						WHEN @Pdv = 'BG3' THEN 'bg3team@bolognagomme.com'
						WHEN @Pdv = 'BG4' THEN 'bg4team@bolognagomme.com'
						WHEN @Pdv = 'BG5' THEN 'bg5team@bolognagomme.com'
						WHEN @Pdv = 'BG6' THEN 'bg6team@bolognagomme.com'
						WHEN @Pdv = 'BG7' THEN 'bg7team@bolognagomme.com'
						ELSE 'antonio.sacco@bolognagomme.com' -- email di default
					END;

					-- Assicuriamoci che @body non sia NULL
					SET @body = ISNULL(@body, '') + char(10) + char(13) + 'Numero Preventivo Creato: ' + CAST(@IdPreventivoProduzione AS varchar(20)) + char(10) + char(13) + 'Pdv: ' + LTRIM(RTRIM(@Negozio)) + ' - ' + LTRIM(RTRIM(@MailPdv))
					
					-- Assicuriamoci che @subject non sia NULL
					SET @subject = ISNULL(@subject, 'Preventivo Web') + ' - Preventivo: ' + CAST(@IdPreventivoProduzione AS varchar(20))
				END

				-- Assicuriamoci che i parametri dell'email siano sempre impostati
				SET @body = ISNULL(@body, 'Nessun messaggio specificato')
				SET @subject = 'Preventivo Web in Entrata da Gestire Nr: ' + CAST(@IdPreventivoProduzione AS varchar(20))  --ISNULL(@subject, 'Preventivo Web')

				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'SQL',
					@recipients = @to_mails,
					@subject = @subject,
					@body = @body

			END
			ELSE
			BEGIN
				-- Questo non dovrebbe succedere se la logica sopra è corretta, ma per sicurezza
				SET @Errore = 'ERRORE IMPREVISTO: IdAnagraficaEsistente non valorizzato alla fine del processo.';
				SET @Body = 'ERRORE IMPREVISTO: IdAnagraficaEsistente non valorizzato alla fine del processo.' + CHAR(10) + CHAR(13) + 'ID PreventiviWeb: ' + CAST(ISNULL(@ID,'') AS VARCHAR(20))
				SET @subject = 'ERRORE IMPREVISTO: IdAnagraficaEsistente non valorizzato alla fine del processo.';

				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'SQL',
					@recipients = @to_mails,
					@subject = @subject,
					@body = @body

				RAISERROR(@Errore, 16, 1);
			END

			-- Se tutto ok, conferma la transazione
			COMMIT TRAN ProcessaRichiestaWeb;

		END TRY
		BEGIN CATCH
			-- Se si verifica un errore, annulla la transazione
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN ProcessaRichiestaWeb;

			-- Logga l'errore e marca la riga come fallita
			SET @Errore = 'ERRORE Elaborazione Preventivo Web: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS VARCHAR) + ')';
			SET @Body = 'ERRORE Elaborazione Preventivo Web: ' + ERROR_MESSAGE() + ' (Linea: ' + CAST(ERROR_LINE() AS VARCHAR) + ')' + CHAR(10) + CHAR(13) + 'ID PreventiviWeb: ' + CAST(ISNULL(@ID,'') AS VARCHAR(20))
			SET @subject = 'ERRORE Elaborazione Preventivo Web';
			PRINT @Errore;

			-- Aggiorna la riga corrente del cursore per marcarla come fallita
			-- Usiamo un UPDATE separato perché il contesto della transazione è perso
			UPDATE PreventiviWeb
			SET    Elaborato = 2, -- O un altro stato per indicare errore
				   DataElaborazione = @DataCorrente,
				   NoteSistema = ISNULL(NoteSistema,'') + @Errore
			WHERE  ID = @ID; -- Attenzione: WHERE CURRENT OF CUR funziona solo se il FETCH è avvenuto prima del CATCH

			EXEC msdb.dbo.sp_send_dbmail
				@profile_name = 'SQL',
				@recipients = @to_mails,
				@subject = @subject,
				@body = @body

		END CATCH;

		-- Passa alla riga successiva del cursore
		FETCH NEXT FROM cur INTO  @ID, @Nome, @Cognome, @Email, @Cellulare, @Negozio, @Targa, @Marca, @Modello, @TipoPreventivo, @FasciaDiPrezzo, @MisuraVettura, @CodCar, @CodVel, @Stagione, @Qta, @MisuraMotoAnt, @CodCarMotoAnt, @CodVelMotoAnt, @MisuraMotoPost, @CodCarMotoPost, @CodVelMotoPost, @Km, @TipoManutenzione, @NoteInput;

	END; -- Fine WHILE

	CLOSE cur;
	DEALLOCATE cur;

	PRINT 'Elaborazione Preventivi Web terminata.';

END