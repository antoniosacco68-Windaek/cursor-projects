-- DEBUG SINCRONIZZAZIONE GIACENZE
-- Per capire dove si blocca la chiamata API

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @Cmd NVARCHAR(4000);
DECLARE @Result TABLE (line NVARCHAR(4000));

PRINT '=== DEBUG SINCRONIZZAZIONE GIACENZE ===';

-- === VERIFICA 1: File PowerShell esiste? ===
PRINT '1. Verificando esistenza file PowerShell...';
SET @Cmd = 'if exist "' + @PowerShellScript + '" echo POWERSHELL_EXISTS else echo POWERSHELL_NOT_FOUND';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

SELECT 'Verifica PowerShell' as Controllo, line as Risultato FROM @Result;
DELETE FROM @Result;

-- === VERIFICA 2: Test chiamata semplice ===
PRINT '';
PRINT '2. Test chiamata API semplice...';

DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\debug_giacenze.json';
DECLARE @Endpoint NVARCHAR(200) = '/api/v1/giaMag?pageno=1&pagesize=3';  -- Solo 3 record per test

-- Pulizia file precedente
SET @Cmd = 'del "' + @OutputFile + '" 2>nul';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;
DELETE FROM @Result;

-- Comando completo
SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';

PRINT 'Comando eseguito:';
PRINT @Cmd;
PRINT '';

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT 'Output PowerShell:';
SELECT 'PS Output ' + CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NVARCHAR) as Riga, 
       ISNULL(line, '[NULL]') as Contenuto 
FROM @Result;

-- === VERIFICA 3: File creato? ===
PRINT '';
PRINT '3. Verificando file di output...';

DELETE FROM @Result;
SET @Cmd = 'if exist "' + @OutputFile + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

SELECT 'Verifica File' as Controllo, line as Risultato FROM @Result;

-- === VERIFICA 4: Contenuto file (se esiste) ===
IF EXISTS (SELECT 1 FROM @Result WHERE line = 'FILE_EXISTS')
BEGIN
    PRINT '';
    PRINT '4. Contenuto file JSON:';
    
    BEGIN TRY
        DECLARE @JsonContent NVARCHAR(MAX);
        DECLARE @sql NVARCHAR(MAX) = N'SELECT @JsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @OutputFile + ''', SINGLE_CLOB) as j;';
        EXEC sp_executesql @sql, N'@JsonOut NVARCHAR(MAX) OUTPUT', @JsonOut = @JsonContent OUTPUT;
        
        PRINT 'Lunghezza JSON: ' + CAST(LEN(@JsonContent) as NVARCHAR);
        PRINT 'Anteprima (primi 500 caratteri):';
        PRINT LEFT(@JsonContent, 500);
        
        -- Test parsing JSON
        IF CHARINDEX('"data":', @JsonContent) > 0
        BEGIN
            PRINT '';
            PRINT '✅ JSON VALIDO - Contiene campo "data"';
            
            -- Conta record in data
            SELECT 'Record in data' as Info, COUNT(*) as Valore
            FROM OPENJSON(@JsonContent, '$.data');
            
            -- Mostra paging info se presente
            SELECT 
                'Paging Info' as Tipo,
                JSON_VALUE(@JsonContent, '$.paging.totalrecordcount') as TotalRecords,
                JSON_VALUE(@JsonContent, '$.paging.pagecount') as TotalPages,
                JSON_VALUE(@JsonContent, '$.paging.pageno') as CurrentPage
        END
        ELSE
        BEGIN
            PRINT '❌ JSON NON VALIDO - Manca campo "data"';
            PRINT 'Possibile token invece di dati, o errore API';
        END
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE lettura JSON: ' + ERROR_MESSAGE();
    END CATCH
END
ELSE
BEGIN
    PRINT '';
    PRINT '❌ FILE NON CREATO - Problema con chiamata PowerShell';
    
    -- === VERIFICA 5: Test chiamata diretta ===
    PRINT '';
    PRINT '5. Test PowerShell diretto (senza ApiCaller)...';
    
    DELETE FROM @Result;
    SET @Cmd = 'powershell.exe -Command "Write-Host ''PowerShell funziona''; $PSVersionTable.PSVersion"';
    INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    
    SELECT 'Test PS Diretto' as Test, line as Output FROM @Result;
    
    -- === VERIFICA 6: Directory temp accessibile? ===
    PRINT '';
    PRINT '6. Verifica directory C:\temp...';
    
    DELETE FROM @Result;
    SET @Cmd = 'dir C:\temp\*.json /B 2>nul';
    INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    
    SELECT 'File JSON in temp' as Info, ISNULL(line, '[NESSUN FILE]') as Filename FROM @Result;
END

-- === SUGGERIMENTI FINALI ===
PRINT '';
PRINT '=== DIAGNOSI AUTOMATICA ===';

-- Controlla se il problema è l'endpoint
IF EXISTS (SELECT 1 FROM @Result WHERE line LIKE '%404%' OR line LIKE '%endpoint%')
    PRINT '🔍 POSSIBILE CAUSA: Endpoint API non valido o non raggiungibile';

-- Controlla se il problema è il token
IF EXISTS (SELECT 1 FROM @Result WHERE line LIKE '%token%' OR line LIKE '%401%' OR line LIKE '%authorization%')
    PRINT '🔍 POSSIBILE CAUSA: Problema di autenticazione/token scaduto';

-- Controlla se il problema è il file PowerShell
IF NOT EXISTS (SELECT 1 FROM @Result WHERE line = 'POWERSHELL_EXISTS')
    PRINT '🔍 POSSIBILE CAUSA: File ApiCaller.ps1 non trovato nel percorso specificato';

-- Controlla se il problema è xp_cmdshell
IF NOT EXISTS (SELECT 1 FROM @Result WHERE line IS NOT NULL)
    PRINT '🔍 POSSIBILE CAUSA: xp_cmdshell disabilitato o problema di sicurezza';

PRINT '';
PRINT '💡 PROSSIMI PASSI:';
PRINT '1. Controlla i risultati sopra per identificare il problema';
PRINT '2. Se ApiCaller.ps1 non esiste, verifica il percorso';
PRINT '3. Se JSON non valido, potrebbe essere problema di token scaduto';
PRINT '4. Se tutto sembra OK ma file non creato, problema di permessi?'; 