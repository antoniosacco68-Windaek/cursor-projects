-- SOLUZIONE DEFINITIVA: SQL -> PowerShell -> API (NESSUN LIMITE DI LUNGHEZZA)
-- Richiede: xp_cmdshell abilitato

-- === CONFIGURAZIONE ===
DECLARE @PowerShellScript NVARCHAR(500) = 'C:\temp\ApiCaller.ps1';  -- Percorso dello script PowerShell
DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\api_response.json';     -- File per la risposta JSON completa
DECLARE @Endpoint NVARCHAR(500) = '/api/v1/artico?pageno=1&pagesize=10'; -- Endpoint da chiamare
DECLARE @Cmd NVARCHAR(4000), @Result TABLE (line NVARCHAR(4000));

-- === VERIFICA PREREQUISITI ===
-- Verifica se xp_cmdshell è abilitato
IF NOT EXISTS (SELECT * FROM sys.configurations WHERE name = 'xp_cmdshell' AND value_in_use = 1)
BEGIN
    PRINT 'ERRORE: xp_cmdshell non è abilitato. Esegui:'
    PRINT 'EXEC sp_configure ''xp_cmdshell'', 1'
    PRINT 'RECONFIGURE'
    RETURN;
END

-- Verifica se lo script PowerShell esiste
SET @Cmd = 'if exist "' + @PowerShellScript + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT * FROM @Result WHERE line = 'NOT_FOUND')
BEGIN
    PRINT 'ERRORE: Script PowerShell non trovato in: ' + @PowerShellScript;
    PRINT 'Crea il file ApiCaller.ps1 nel percorso specificato.';
    RETURN;
END

DELETE FROM @Result;

-- === CHIAMATA COMPLETA: TOKEN + API ===
PRINT '=== CHIAMATA API TRAMITE POWERSHELL ===';
PRINT 'Endpoint: ' + @Endpoint;
PRINT 'File output: ' + @OutputFile;

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';

PRINT 'Eseguendo comando: ' + @Cmd;

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- === MOSTRA RISULTATI ===
PRINT '';
PRINT '=== RISULTATI POWERSHELL ===';
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as LineNum, line as Output 
FROM @Result 
WHERE line IS NOT NULL
ORDER BY LineNum;

-- === VERIFICA SE IL FILE JSON È STATO CREATO ===
DELETE FROM @Result;
SET @Cmd = 'if exist "' + @OutputFile + '" (dir "' + @OutputFile + '" /-c | find "bytes") else echo FILE_NOT_FOUND';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

SELECT 'File JSON creato:' as Stato, line as Dettagli FROM @Result WHERE line IS NOT NULL;

-- === ESEMPIO: LETTURA DEL FILE JSON DA SQL ===
PRINT '';
PRINT '=== PER LEGGERE IL JSON COMPLETO USA: ===';
PRINT 'DECLARE @JSON NVARCHAR(MAX);';
PRINT 'SELECT @JSON = BulkColumn FROM OPENROWSET(BULK ''' + @OutputFile + ''', SINGLE_CLOB) as j;';
PRINT 'SELECT @JSON as JSONCompleto;';
PRINT '';
PRINT '=== PER PARSING JSON USA: ===';
PRINT 'SELECT * FROM OPENJSON(@JSON, ''$.data'') WITH (';
PRINT '    id INT ''$.id'',';
PRINT '    codice NVARCHAR(100) ''$.codice'',';
PRINT '    descr NVARCHAR(200) ''$.descr'',';
PRINT '    volume DECIMAL(10,4) ''$.volume'',';
PRINT '    netto DECIMAL(10,3) ''$.netto''';
PRINT ');';

-- === COMANDI UTILI PER IL FUTURO ===
PRINT '';
PRINT '=== COMANDI UTILI ===';
PRINT '1. Solo token:';
PRINT '   powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action token';
PRINT '';
PRINT '2. Solo API con token esistente:';
PRINT '   powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action api -Token "YOUR_TOKEN" -Endpoint "/api/v1/clienti" -OutputFile "C:\temp\clienti.json"';
PRINT '';
PRINT '3. Processo completo per qualsiasi endpoint:';
PRINT '   powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/QUALSIASI_ENDPOINT" -OutputFile "C:\temp\output.json"';
