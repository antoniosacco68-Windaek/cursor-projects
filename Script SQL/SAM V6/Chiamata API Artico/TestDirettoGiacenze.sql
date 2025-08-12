-- TEST DIRETTO ENDPOINT GIACENZE
-- Per capire perché giaMag non funziona mentre fatture sì

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @Cmd NVARCHAR(4000);
DECLARE @Result TABLE (line NVARCHAR(4000));

PRINT '=== TEST DIRETTO ENDPOINT GIACENZE ===';

-- === TEST 1: Endpoint che funziona (confronto) ===
PRINT '1. Test endpoint fatture (per confronto)...';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action token';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Test token (dovrebbe funzionare):';
SELECT 'Token Test' as Tipo, ISNULL(line, '[NULL]') as Output FROM @Result;

-- === TEST 2: Endpoint giaMag con parametri diversi ===
PRINT '';
PRINT '2. Test giaMag con parametri base...';

DELETE FROM @Result;
DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\test_giamag_base.json';

-- Prova prima senza parametri di paginazione
SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/giaMag" -OutputFile "' + @OutputFile + '"';

PRINT 'Comando senza paginazione:';
PRINT @Cmd;

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Output PowerShell:';
SELECT 'GiaMag Base' as Test, ISNULL(line, '[NULL]') as Output FROM @Result;

-- Verifica file
DECLARE @FileCheck TABLE (line NVARCHAR(4000));
SET @Cmd = 'if exist "' + @OutputFile + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT 'File Check' as Info, line as Risultato FROM @FileCheck;

-- === TEST 3: Endpoint giaMag con pageno=1 (senza pagesize) ===
PRINT '';
PRINT '3. Test giaMag solo con pageno=1...';

DELETE FROM @Result;
DELETE FROM @FileCheck;
SET @OutputFile = 'C:\temp\test_giamag_page1.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/giaMag?pageno=1" -OutputFile "' + @OutputFile + '"';

PRINT 'Comando solo pageno:';
PRINT @Cmd;

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Output PowerShell:';
SELECT 'GiaMag Page1' as Test, ISNULL(line, '[NULL]') as Output FROM @Result;

-- Verifica file
SET @Cmd = 'if exist "' + @OutputFile + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT 'File Check Page1' as Info, line as Risultato FROM @FileCheck;

-- === TEST 4: Verifica se è un problema di pagesize ===
PRINT '';
PRINT '4. Test giaMag con pagesize piccolo...';

DELETE FROM @Result;
DELETE FROM @FileCheck;
SET @OutputFile = 'C:\temp\test_giamag_small.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/giaMag?pageno=1&pagesize=1" -OutputFile "' + @OutputFile + '"';

PRINT 'Comando pagesize=1:';
PRINT @Cmd;

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Output PowerShell:';
SELECT 'GiaMag Small' as Test, ISNULL(line, '[NULL]') as Output FROM @Result;

-- Verifica file
SET @Cmd = 'if exist "' + @OutputFile + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT 'File Check Small' as Info, line as Risultato FROM @FileCheck;

-- === TEST 5: Confronto con endpoint artico ===
PRINT '';
PRINT '5. Test endpoint artico (dovrebbe funzionare)...';

DELETE FROM @Result;
DELETE FROM @FileCheck;
SET @OutputFile = 'C:\temp\test_artico.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "/api/v1/artico?pageno=1&pagesize=1" -OutputFile "' + @OutputFile + '"';

PRINT 'Comando artico (confronto):';
PRINT @Cmd;

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Output PowerShell artico:';
SELECT 'Artico Test' as Test, ISNULL(line, '[NULL]') as Output FROM @Result;

-- Verifica file
SET @Cmd = 'if exist "' + @OutputFile + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

SELECT 'File Check Artico' as Info, line as Risultato FROM @FileCheck;

-- === CONFRONTO RISULTATI ===
PRINT '';
PRINT '=== ANALISI RISULTATI ===';

-- Verifica quali file sono stati creati
DELETE FROM @FileCheck;
SET @Cmd = 'dir C:\temp\test_*.json /B';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

PRINT 'File creati:';
SELECT 'File Creati' as Info, ISNULL(line, '[NESSUNO]') as NomeFile FROM @FileCheck;

PRINT '';
PRINT '💡 CONCLUSIONI:';
PRINT 'Se artico funziona ma giaMag no → problema specifico endpoint giaMag';
PRINT 'Se nessuno funziona → problema generale ApiCaller o token';
PRINT 'Se solo alcuni pagesize funzionano → problema di timeout o memoria'; 