-- SCRIPT CREAZIONE FATTURA COMPLETA
-- 1) Crea testata fattura (/fatTes-fattura/simplified)
-- 2) Estrae ID dal JSON response
-- 3) Aggiunge riga alla fattura (/fatRig-fattura/simplified)

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @BodyFattes NVARCHAR(500) = 'C:\temp\bodyFattes.json';
DECLARE @BodyFatrig NVARCHAR(500) = 'C:\temp\bodyFatrig.json';
DECLARE @ResponseFattes NVARCHAR(500) = 'C:\temp\response_fattes.json';
DECLARE @ResponseFatrig NVARCHAR(500) = 'C:\temp\response_fatrig.json';
DECLARE @Cmd NVARCHAR(4000)
DECLARE @Result TABLE (line NVARCHAR(4000));

PRINT '=== CREAZIONE FATTURA COMPLETA ===';

-- === STEP 0: PULIZIA FILE PRECEDENTI ===
PRINT '0. Cancellando file response precedenti...';

-- Cancella file response esistenti per evitare confusione
SET @Cmd = 'if exist "' + @ResponseFattes + '" del "' + @ResponseFattes + '"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

SET @Cmd = 'if exist "' + @ResponseFatrig + '" del "' + @ResponseFatrig + '"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Cancella anche eventuali file temporanei precedenti
SET @Cmd = 'if exist "C:\temp\bodyFatrig_temp.json" del "C:\temp\bodyFatrig_temp.json"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'File precedenti cancellati';
DELETE FROM @Result; -- Pulisci tabella per i prossimi output

-- === STEP 1: CREA TESTATA FATTURA ===
PRINT '1. Creando testata fattura...';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/fatTes-fattura/simplified" -Method POST -BodyFile "' + @BodyFattes + '" -OutputFile "' + @ResponseFattes + '"';

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Verifica se il file JSON response è stato creato
DECLARE @FileCheck TABLE (line NVARCHAR(4000));
SET @Cmd = 'if exist "' + @ResponseFattes + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'FILE_NOT_FOUND')
BEGIN
    PRINT 'ERRORE: File response testata non creato';
    RETURN;
END

PRINT 'Testata fattura creata con successo';

-- === STEP 2: ESTRAI ID DAL JSON RESPONSE ===
PRINT '2. Estraendo ID fattura dal JSON response...';

-- Leggi il JSON response completo
DECLARE @JsonResponse NVARCHAR(MAX);
SELECT @JsonResponse = BulkColumn FROM OPENROWSET(BULK 'C:\temp\response_fattes.json', SINGLE_CLOB) as j;

-- Estrai l'ID usando JSON_VALUE
DECLARE @IdFattura NVARCHAR(20);
SET @IdFattura = JSON_VALUE(@JsonResponse, '$.id');

IF @IdFattura IS NULL OR @IdFattura = ''
BEGIN
    PRINT 'ERRORE: Impossibile estrarre ID dalla risposta JSON';
    RETURN;
END

PRINT 'ID fattura estratto: ' + @IdFattura;

-- === STEP 3: CREA NUOVO BODY RIGA COMPATTO (UNA SOLA RIGA) ===
PRINT '3. Creando body riga con ID fattura corretto...';

-- JSON COMPATTO - tutto su una sola riga per PowerShell
DECLARE @BodyRigaDiretto NVARCHAR(MAX) = '{"idfat": ' + @IdFattura + ', "idartico": 758484, "descr": "CARBURANTE PERLAVORAZIONI AUTO CLIENTI", "qta1": 1.0, "qta2": 1.0, "qta3": 1.0, "prezzo": 12.91, "imptot": 12.91, "idmagpre": 14791, "sernum": "542735", "riferi1": "DX287GH", "riferi2": "851986", "riferi3": "542735", "idrepcdc": 8}';

PRINT 'Body riga creato con idfat: ' + @IdFattura;
PRINT 'JSON compatto: ' + @BodyRigaDiretto;

-- === DEBUG: VERIFICA CHE IL FILE RESPONSE FATRIG NON ESISTA ===
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @ResponseFatrig + '" echo ALREADY_EXISTS else echo NOT_EXISTS';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

DECLARE @FileStatus NVARCHAR(100);
SELECT @FileStatus = line FROM @FileCheck;
PRINT 'File response_fatrig PRIMA della chiamata: ' + ISNULL(@FileStatus, 'NULL');

-- === STEP 4: AGGIUNGI RIGA ALLA FATTURA ===
PRINT '4. Aggiungendo riga alla fattura...';

-- === SALVA JSON IN FILE TEMPORANEO (METODO CHE FUNZIONA) ===
DECLARE @BodyRigaFile NVARCHAR(500) = 'C:\temp\bodyFatrig_dynamic.json';

-- Rimuovi file precedente se esiste
SET @Cmd = 'if exist "' + @BodyRigaFile + '" del "' + @BodyRigaFile + '"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Salva JSON in file usando echo (metodo semplice e affidabile)
SET @Cmd = 'echo ' + @BodyRigaDiretto + ' > "' + @BodyRigaFile + '"';
PRINT 'Salvando JSON nel file: ' + @BodyRigaFile;
PRINT 'Comando echo: ' + @Cmd;

DELETE FROM @Result;
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Verifica che il file sia stato creato
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @BodyRigaFile + '" echo TEMP_FILE_CREATED else echo TEMP_FILE_FAILED';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT @FileStatus = line FROM @FileCheck;
PRINT 'Stato file temporaneo: ' + ISNULL(@FileStatus, 'NULL');

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'TEMP_FILE_FAILED')
BEGIN
    PRINT 'ERRORE: Impossibile creare file temporaneo JSON';
    RETURN;
END

-- === USA -BodyFile INSTEAD OF -BodyJson (METODO CHE FUNZIONA) ===
SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/fatRig-fattura/simplified" -Method POST -BodyFile "' + @BodyRigaFile + '" -OutputFile "' + @ResponseFatrig + '"';

PRINT 'Comando con BodyFile (metodo testata):';
PRINT @Cmd;

DELETE FROM @Result;
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Debug output riga
PRINT 'Output PowerShell riga COMPLETO:';
DECLARE @riga_counter INT = 1;
DECLARE riga_cursor CURSOR FOR SELECT ISNULL(line, '[NULL]') FROM @Result;
OPEN riga_cursor;
DECLARE @riga_line NVARCHAR(4000);

FETCH NEXT FROM riga_cursor INTO @riga_line;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT 'R' + CAST(@riga_counter AS NVARCHAR) + ': ' + @riga_line;
    SET @riga_counter = @riga_counter + 1;
    FETCH NEXT FROM riga_cursor INTO @riga_line;
END

CLOSE riga_cursor;
DEALLOCATE riga_cursor;

-- === DEBUG: VERIFICA SE IL FILE È STATO CREATO DOPO LA CHIAMATA ===
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @ResponseFatrig + '" echo NOW_EXISTS else echo STILL_NOT_EXISTS';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT @FileStatus = line FROM @FileCheck;
PRINT 'File response_fatrig DOPO la chiamata: ' + ISNULL(@FileStatus, 'NULL');

-- Se il file esiste, verifica le dimensioni
IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'NOW_EXISTS')
BEGIN
    DELETE FROM @FileCheck;
    SET @Cmd = 'dir "' + @ResponseFatrig + '" | find "bytes"';
    INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;
    
    DECLARE @FileDimensions NVARCHAR(200);
    SELECT @FileDimensions = line FROM @FileCheck;
    PRINT 'Dimensioni file: ' + ISNULL(@FileDimensions, 'Non trovato');
END

-- Verifica se il file JSON response della riga è stato creato
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @ResponseFatrig + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'FILE_NOT_FOUND')
BEGIN
    PRINT 'ERRORE: File response riga NON CREATO - chiamata API fallita';
    PRINT 'La chiamata PowerShell non ha prodotto il file di output';
    RETURN;
END

PRINT 'Riga aggiunta con successo';

-- === STEP 5: MOSTRA RISULTATI ===
PRINT '';
PRINT '=== RISULTATI FINALI ===';

-- Leggi anche la risposta della riga per mostrarla
DECLARE @JsonResponseRiga NVARCHAR(MAX);
SELECT @JsonResponseRiga = BulkColumn FROM OPENROWSET(BULK 'C:\temp\response_fatrig.json', SINGLE_CLOB) as j;

PRINT 'ID Fattura Creata: ' + @IdFattura;
PRINT 'JSON Testata: ' + LEFT(@JsonResponse, 200);
PRINT 'JSON Riga: ' + LEFT(@JsonResponseRiga, 200);

PRINT '';
PRINT '=== FATTURA COMPLETA CREATA CON SUCCESSO ===';
PRINT 'ID Fattura: ' + @IdFattura;
PRINT 'File Testata: ' + @ResponseFattes;
PRINT 'File Riga: ' + @ResponseFatrig; 