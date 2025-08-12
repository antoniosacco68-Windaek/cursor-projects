/*

Importazione 

*/


USE I24DB

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @Sql1 varchar(800),@Sql2 varchar(800),@PdvInv varchar(60),@NotaInventario varchar(30),@RicNotaInventario varchar(30),@Tabella varchar(100),@NotaInventarioSost varchar(30)
DECLARE @Targa varchar(100),@TPosizione varchar(100),@ID int,@Pdv Varchar(3),@IdDep int	,@PosizioneLinea int,@SoloTarga Varchar (20),@Qta int,@Note Varchar(100)
DECLARE @FindLinea int,@IdTbl int,@TTarga varchar(20),@FindIdDeposito int,@Posizione varchar(40) --,@SoloTarga varchar(20),@TPosizione varchar(40),@IdDep int,@Targa varchar(20)
DECLARE @FindDeposito int,@OldPosizione varchar(40), @FindTargaNew VARCHAR(20)

--======================================================================================================================================================

UPDATE Inventario_Depositi
SET
	TargaDoppia=NULL,
	Note=NULL,
	NonElaborareTargaDoppia=NULL,
	IdAbbinato=NULL,
	PosizioneMultipla=NULL,
	SoloTarga=NULL,
	Qta=0,
	Elaborato=NULL,
	ID=NULL,
	PDV=NULL
WHERE Elaborato IS NULL

Declare CursInvEstivo CURSOR FAST_FORWARD READ_ONLY LOCAL FOR select Targa,IdTbl from Inventario_Depositi

open CursInvEstivo
	fetch next from CursInvEstivo into @Targa,@ID
	WHILE @@FETCH_STATUS = 0
	begin
        -- Azzeramento variabili all'inizio del ciclo
        SET @TPosizione = NULL;
        SET @Pdv = NULL;
        SET @SoloTarga = NULL;
        SET @IdDep = NULL;
        SET @Qta = 0;
        SET @Note = NULL;
		IF @Targa like '%BG1.%' or @Targa like '%BG1-%' SET @TPosizione = @Targa
		IF @Targa like '%BG2.%' or @Targa like '%BG2-%' SET @TPosizione = @Targa
		IF @Targa like '%BG3.%' or @Targa like '%BG3-%' SET @TPosizione = @Targa
		IF @Targa like '%BG4.%' or @Targa like '%BG4-%' SET @TPosizione = @Targa
		IF @Targa like '%BG5.%' or @Targa like '%BG5-%' SET @TPosizione = @Targa
		IF @Targa like '%BG6.%' or @Targa like '%BG6-%' SET @TPosizione = @Targa
		IF @Targa like '%BG7.%' or @Targa like '%BG7-%' SET @TPosizione = @Targa
		IF @Targa like '%BGA.%' or @Targa like '%BGA-%' SET @TPosizione = @Targa
		
		IF @TPosizione like '%BG1.%' or @TPosizione like '%BG1-%' SET @Pdv = 'BG1'
		IF @TPosizione like '%BG2.%' or @TPosizione like '%BG2-%' SET @Pdv = 'BG2'
		IF @TPosizione like '%BG3.%' or @TPosizione like '%BG3-%' SET @Pdv = 'BG3'
		IF @TPosizione like '%BG4.%' or @TPosizione like '%BG4-%' SET @Pdv = 'BG4'
		IF @TPosizione like '%BG5.%' or @TPosizione like '%BG5-%' SET @Pdv = 'BG5'
		IF @TPosizione like '%BG6.%' or @TPosizione like '%BG6-%' SET @Pdv = 'BG6'
		IF @TPosizione like '%BG7.%' or @TPosizione like '%BG7-%' SET @Pdv = 'BG7'
		IF @TPosizione like '%BGA.%' or @TPosizione like '%BGA-%' SET @Pdv = 'BGA'
		
		SET @PosizioneLinea = CHARINDEX('-',@Targa)
		IF @PosizioneLinea > 2
		BEGIN
			SET @SoloTarga = (SUBSTRING(@Targa,1,@PosizioneLinea - 1))
			SET @IdDep = I24BO.dbo.RimuoveCaratteriNonNumerici(SUBSTRING(@Targa,@PosizioneLinea,LEN(@Targa)))
			SET @Qta = (SELECT isnull(Quantita,0) + isnull(D_Quantita_Post,0) FROM Deposito WHERE IdDeposito = @IdDep and D_Targa = @SoloTarga)
			SET @Note = NULL
		END
		IF @PosizioneLinea = 0 BEGIN
			SET @SoloTarga = LTRIM(RTRIM(@Targa))
			SET @IdDep = (SELECT TOP 1 IdDeposito from Deposito where D_Targa = @SoloTarga AND Note_Inventario IS NULL ORDER BY Data DESC)
			--SET @Qta = (SELECT top 1 isnull(Quantita,0) + isnull(D_Quantita_Post,0) FROM Deposito WHERE @Targa = D_Targa ORDER BY Data DESC)
			--IF @TPosizione = @Targa SET @Note = 'Cancellare'
		END
		
		UPDATE Inventario_Depositi
			SET Posizione =  @TPosizione ,PDV = @Pdv ,Id =  @IdDep ,SoloTarga =  @SoloTarga ,Note =  @Note
		WHERE IdTbl =  @ID
		
		
		fetch next from CursInvEstivo into @Targa,@ID
	END

close CursInvEstivo

deallocate CursInvEstivo


Declare CurInv CURSOR FAST_FORWARD READ_ONLY LOCAL FOR select IdTbl,Targa,posizione,Id,SoloTarga from Inventario_Depositi WHERE Elaborato IS NULL /*AND SoloTarga = 'GR535SJ'*/ ORDER BY Targa

open CurInv
	fetch next from CurInv into @IdTbl,@Targa,@Posizione,@IdDep,@SoloTarga
	WHILE @@FETCH_STATUS = 0
		BEGIN
            -- Azzeramento variabili all'inizio del ciclo
            SET @TTarga = NULL;
            SET @TPosizione = NULL;
            SET @FindIdDeposito = NULL;
            SET @FindTargaNew = NULL;
            SET @OldPosizione = NULL;
			SET @TTarga = @Targa
			SET @TPosizione = @Posizione
			
			UPDATE Inventario_Depositi
				SET SoloTarga = @SoloTarga
			WHERE IdTbl = @IdTbl
			
			SET @FindIdDeposito = (SELECT IdDeposito from Deposito WHERE IdDeposito = @IdDep and D_Targa = @SoloTarga)

			UPDATE Inventario_Depositi
				SET IdAbbinato =  @FindIdDeposito
			WHERE IdTbl = @IdTbl
		
			IF @FindIdDeposito IS NULL BEGIN

				SET @FindIdDeposito = (SELECT TOP 1 IdDeposito from Deposito WHERE D_Targa = @SoloTarga AND Note_Inventario IS NULL ORDER BY IdDeposito DESC)

				IF @FindIdDeposito is NOT NULL BEGIN
					update Inventario_Depositi
						SET IdAbbinato = @FindIdDeposito ,Note = isnull(replace(Note,'Abbinamento Forzato',''),'') + 'Abbinamento Forzato'
					WHERE IdTbl = @IdTbl
				END
								
			END

			-- ===== Se non sono ancora riuscito ad abbinare IdDeposito guardo se c'� IdDeposito e cambio la targa perch� magari � sbagliata ===== --
			IF @FindIdDeposito IS NULL AND @IdDep IS NOT NULL BEGIN

				SET @FindIdDeposito = (SELECT TOP 1 IdDeposito from Deposito WHERE IdDeposito = @IdDep)
				SET @FindTargaNew = (SELECT TOP 1 D_Targa from Deposito WHERE IdDeposito = @IdDep)

				IF @FindIdDeposito is NOT NULL BEGIN
					update Inventario_Depositi
						SET IdAbbinato = @FindIdDeposito ,Note = isnull(replace(Note,'Abbinamento Forzato',''),'') + 'Abbinamento Forzato su Targa: ' + LTRIM(RTRIM(@FindTargaNew ) )
					WHERE IdTbl = @IdTbl
				END
								
			END

			-- ===== Se non sono ancora riuscito ad abbinare IdDeposito guardo se riesco a prendere l'ultimo deposito che trovo senza rimontaggio non importa se in STATO C oppure no ===== --
			IF @FindIdDeposito IS NULL BEGIN

				SET @FindIdDeposito = (SELECT TOP 1 IdDeposito from Deposito WHERE D_Targa = @SoloTarga AND (Rimontate IS NULL OR Rimontate = 0) ORDER BY IdDeposito DESC)

				IF @FindIdDeposito is NOT NULL BEGIN
					update Inventario_Depositi
						SET IdAbbinato = @FindIdDeposito ,Note = isnull(replace(Note,'Abbinamento Forzato',''),'') + 'Abbinamento Forzato ultimo Dep Senza Rimontaggio'
					WHERE IdTbl = @IdTbl
				END
								
			END

			-- ===== Se non sono ancora riuscito ad abbinare IdDeposito Prendo ID dell'ULTIMO DEPOSITO non importa se in STATO C oppure no se Rimontato oppure no ===== --
			IF @FindIdDeposito IS NULL BEGIN

				SET @FindIdDeposito = (SELECT TOP 1 IdDeposito from Deposito WHERE D_Targa = @SoloTarga ORDER BY IdDeposito DESC)

				IF @FindIdDeposito is NOT NULL BEGIN
					update Inventario_Depositi
						SET IdAbbinato = @FindIdDeposito ,Note = isnull(replace(Note,'Abbinamento Forzato',''),'') + 'Abbinamento Forzato Ultimo Deposito'
					WHERE IdTbl = @IdTbl
				END
								
			END
			
			FETCH NEXT FROM CurInv INTO @IdTbl,@Targa,@Posizione,@IdDep,@SoloTarga

			IF @TTarga = @Targa BEGIN

				IF @TPosizione = @Posizione BEGIN

					UPDATE Inventario_Depositi
						SET TargaDoppia = 1,Note = isnull(replace(Note,'Targa Doppia',''),'') + 'Targa Doppia',NonElaborareTargaDoppia = 1
					WHERE Targa = @TTarga
					
					UPDATE Inventario_Depositi
						SET NonElaborareTargaDoppia = 1
					WHERE IdTbl = @IdTbl
					
				END
				ELSE BEGIN

					SET @OldPosizione = @TPosizione
					
					update Inventario_Depositi
						SET TargaDoppia = -1,Note = isnull(replace(Note,'Doppia Posizione',''),'') + 'Doppia Posizione',PosizioneMultipla = @Posizione + '(' + @TPosizione + ')'
					WHERE Targa = @TTarga
					
				END				
			END
		END
		
close CurInv
deallocate CurInv;

--======================================================================================================================================================

UPDATE Inventario_Depositi
	SET Note = isnull(replace(Note,'Verificare',''),'') + 'Verificare'
WHERE IdAbbinato IS NULL

DECLARE @files TABLE (ID int IDENTITY, Number int) -- creo la TBL Temporanea
INSERT INTO
	@files 
SELECT
	T1.IdAbbinato
FROM (SELECT ROW_NUMBER() OVER(PARTITION BY IdAbbinato ORDER BY Targa) AS [NumeroCodici],* FROM Inventario_Depositi) as T1 where T1.NumeroCodici>1 and T1.Note is NULL

UPDATE Inventario_Depositi
	SET Note = isnull(replace(Note,'IdAbbinato Duplicato',''),'') + 'IdAbbinato Duplicato'
FROM Inventario_Depositi INNER JOIN @files ON Number = IdAbbinato

UPDATE Inventario_Depositi -- Scrivo nel mio File Dell'inventario la QTA dei pneumatici con IdAbbinato
	SET Qta = ISNULL(Quantita,0) + ISNULL(D_Quantita_Post,0)
FROM Deposito INNER JOIN Inventario_Depositi ON IdAbbinato = IdDeposito
WHERE IdAbbinato IS NOT NULL

UPDATE Inventario_Depositi -- Scrivo nel mio File Dell'inventario la QTA dei pneumatici dove nel mio file la Qta = 0 e invece le gomme sono inventariate (Capita se nella targa non c'� ID del Deposito perch� magari e scritta a mano dai ragazzi)
	SET Qta = ISNULL(Quantita,0) + ISNULL(D_Quantita_Post,0),Note = 'Abbinamento Forzato'
FROM Deposito INNER JOIN Inventario_Depositi ON Targa = D_Targa
WHERE Qta = 0 AND Inventariato = 1

--======================================================================================================================================================================--
--=================== ELIMINO i DUPLICATI (Mettere alla fine perch� altrimenti mi cancellava le Posizioni duplicate della 1 Riga e non andava bene) ====================--
--======================================================================================================================================================================--

DELETE T1 FROM (SELECT ROW_NUMBER() OVER(PARTITION BY Targa,Posizione ORDER BY Targa) AS [NumeroCodici],* FROM Inventario_Depositi) as T1 
where T1.NumeroCodici>1  -- Cancella i duplicati in ordine di Targa

-- Cancello le righe con solo le Psoirzioni
DELETE Inventario_Depositi
WHERE Targa = Posizione

--======================================================================================================================================================================--

--SELECT * from Inventario_Depositi WHERE Note IS NOT NULL ORDER BY Targa,IdAbbinato,Note

--SELECT * from Inventario_Depositi WHERE Note IS NOT NULL ORDER BY Targa,IdAbbinato,Note

--SELECT [Targa],[Posizione],[Id],[SoloTarga],[Qta],[IdAbbinato],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV]
--from Inventario_Depositi WHERE Note IS NOT NULL and PDV = 'BG1' ORDER BY Targa,IdAbbinato,Note

--SELECT [Targa],[Posizione],[Id],[SoloTarga],[Qta],[IdAbbinato],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV]
--from Inventario_Depositi WHERE Note IS NOT NULL and PDV = 'BG2' ORDER BY Targa,IdAbbinato,Note

--SELECT [Targa],[Posizione],[Id],[SoloTarga],[Qta],[IdAbbinato],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV]
--from Inventario_Depositi WHERE Note IS NOT NULL and PDV = 'BG3' ORDER BY Targa,IdAbbinato,Note

--SELECT [Targa],[Posizione],[Id],[SoloTarga],[Qta],[IdAbbinato],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV]
--from Inventario_Depositi WHERE Note IS NOT NULL and PDV = 'BG4' ORDER BY Targa,IdAbbinato,Note

--========= Da USare se Si Vuole il Backup e Poi Aggiungere l'Inventario dei PDV Precedenti ! (Quando Fatto a Pezzi...) ===================--
--INSERT INTO [I24DB].[dbo].[Inventario_Depositi_Bck]
--	([Targa],[Posizione],[Id],[SoloTarga],[Qta],[Elaborato],[IdAbbinato],[DepositiLiberi],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV])
--SELECT
--	[Targa],[Posizione],[Id],[SoloTarga],[Qta],[Elaborato],[IdAbbinato],[DepositiLiberi],[TargaDoppia],[NonElaborareTargaDoppia],[Note],[PosizioneMultipla],[PDV]
--FROM @Table
--======================================================================================================================================================

UPDATE Inventario_Depositi
	SET Note = Note  + ' Cancellare'
WHERE Targa = Posizione

SELECT * FROM Inventario_Depositi WHERE Note LIKE '%Cancellare%'

DELETE Inventario_Depositi  WHERE Note LIKE '%Cancellare%'

SELECT * FROM Inventario_Depositi  WHERE IdAbbinato IS NULL

-- Visualizza subito le targhe da verificare
SELECT * FROM Inventario_Depositi WHERE Note LIKE '%Verificare%';

