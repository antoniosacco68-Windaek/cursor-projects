-- TEST FILTRO GIACENZE PER ARTICOLO SPECIFICO
-- Prova vari metodi per ottenere giacenze di un articolo

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @IdArticolo NVARCHAR(20) = '512534'; -- CAMBIA QUI L'ID ARTICOLO
DECLARE @Cmd NVARCHAR(4000), @Result TABLE (line NVARCHAR(4000));

PRINT '=== TEST FILTRO GIACENZE ARTICOLO: ' + @IdArticolo + ' ===';

-- === METODO 1: Query Parameter idartico ===
PRINT '';
PRINT '1. Testando: ?idartico=' + @IdArticolo;

DECLARE @Endpoint1 NVARCHAR(200) = '/api/v1/giaMag?idartico=' + @IdArticolo;
DECLARE @OutputFile1 NVARCHAR(500) = 'C:\temp\giacenze_method1.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint1 + '" -OutputFile "' + @OutputFile1 + '"';

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Verifica risultato metodo 1
DECLARE @FileCheck TABLE (line NVARCHAR(4000));
SET @Cmd = 'if exist "' + @OutputFile1 + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'FILE_EXISTS')
BEGIN
    DECLARE @JsonContent1 NVARCHAR(MAX);
    SELECT @JsonContent1 = BulkColumn FROM OPENROWSET(BULK 'C:\temp\giacenze_method1.json', SINGLE_CLOB) as j;
    
    IF CHARINDEX('"data":', @JsonContent1) > 0
    BEGIN
        PRINT '✅ METODO 1 FUNZIONA! Trovati dati per articolo ' + @IdArticolo;
        PRINT 'Lunghezza risposta: ' + CAST(LEN(@JsonContent1) AS NVARCHAR);
        PRINT 'Anteprima: ' + LEFT(@JsonContent1, 200) + '...';
    END
    ELSE
    BEGIN
        PRINT '❌ Metodo 1: Nessun dato trovato o errore';
        PRINT 'Risposta: ' + LEFT(@JsonContent1, 200);
    END
END
ELSE
BEGIN
    PRINT '❌ Metodo 1: File non creato - endpoint non valido';
END

-- === METODO 2: Endpoint Specifico ===
PRINT '';
PRINT '2. Testando: /article/' + @IdArticolo;

DELETE FROM @Result;
DECLARE @Endpoint2 NVARCHAR(200) = '/api/v1/giaMag/article/' + @IdArticolo;
DECLARE @OutputFile2 NVARCHAR(500) = 'C:\temp\giacenze_method2.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint2 + '" -OutputFile "' + @OutputFile2 + '"';

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Verifica risultato metodo 2
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @OutputFile2 + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'FILE_EXISTS')
BEGIN
    DECLARE @JsonContent2 NVARCHAR(MAX);
    SELECT @JsonContent2 = BulkColumn FROM OPENROWSET(BULK 'C:\temp\giacenze_method2.json', SINGLE_CLOB) as j;
    
    IF CHARINDEX('"data":', @JsonContent2) > 0 OR CHARINDEX('"qttgiai":', @JsonContent2) > 0
    BEGIN
        PRINT '✅ METODO 2 FUNZIONA! Trovati dati per articolo ' + @IdArticolo;
        PRINT 'Lunghezza risposta: ' + CAST(LEN(@JsonContent2) AS NVARCHAR);
        PRINT 'Anteprima: ' + LEFT(@JsonContent2, 200) + '...';
    END
    ELSE
    BEGIN
        PRINT '❌ Metodo 2: Nessun dato trovato o errore';
        PRINT 'Risposta: ' + LEFT(@JsonContent2, 200);
    END
END
ELSE
BEGIN
    PRINT '❌ Metodo 2: File non creato - endpoint non valido';
END

-- === METODO 3: Filtraggio Manuale ===
PRINT '';
PRINT '3. Metodo fallback: Scarica tutto e filtra in SQL';

DELETE FROM @Result;
DECLARE @Endpoint3 NVARCHAR(200) = '/api/v1/giaMag?pageno=1&pagesize=100';  -- Pagina più grande
DECLARE @OutputFile3 NVARCHAR(500) = 'C:\temp\giacenze_all.json';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint3 + '" -OutputFile "' + @OutputFile3 + '"';

INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Analizza il JSON per trovare l'articolo
DELETE FROM @FileCheck;
SET @Cmd = 'if exist "' + @OutputFile3 + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'FILE_EXISTS')
BEGIN
    DECLARE @JsonContent3 NVARCHAR(MAX);
    SELECT @JsonContent3 = BulkColumn FROM OPENROWSET(BULK 'C:\temp\giacenze_all.json', SINGLE_CLOB) as j;
    
    -- Filtra per l'articolo specifico usando OPENJSON
    SELECT 
        JSON_VALUE(value, '$.id') as GiacenzaID,
        JSON_VALUE(value, '$.idartico') as IdArticolo,
        JSON_VALUE(value, '$.idmag') as IdMagazzino,
        CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)) as QuantitaGiacenza,
        CAST(JSON_VALUE(value, '$.qttgiam') as DECIMAL(15,3)) as QuantitaGiacenzaMin,
        CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3)) as QuantitaImpegnata
    FROM OPENJSON(@JsonContent3, '$.data') 
    WHERE JSON_VALUE(value, '$.idartico') = @IdArticolo;
    
    -- Riepilogo quantità per articolo
    SELECT 
        @IdArticolo as IdArticolo,
        COUNT(*) as NumeroMagazzini,
        SUM(CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3))) as TotaleQuantitaGiacenza,
        SUM(CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3))) as TotaleQuantitaImpegnata,
        SUM(CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3))) - 
        SUM(CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3))) as QuantitaDisponibile
    FROM OPENJSON(@JsonContent3, '$.data') 
    WHERE JSON_VALUE(value, '$.idartico') = @IdArticolo;
    
END

PRINT '';
PRINT '=== FINE TEST ===';
PRINT 'Controlla quale metodo ha funzionato e usa quello per le query future!'; 