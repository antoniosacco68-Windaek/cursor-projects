-- TEST INSERIMENTO CACHE GIACENZE
-- Usa i file JSON che sappiamo essere corretti per testare l'inserimento

-- === CREA TABELLA CACHE SE NON ESISTE ===
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CacheGiacenze]') AND type in (N'U'))
BEGIN
    CREATE TABLE [dbo].[CacheGiacenze] (
        [id] INT PRIMARY KEY,
        [idartico] INT NOT NULL,
        [idmag] INT NOT NULL,
        [qttgiai] DECIMAL(15,3) DEFAULT 0,
        [qttgiam] DECIMAL(15,3) DEFAULT 0,
        [qttimpi] DECIMAL(15,3) DEFAULT 0,
        [qttmani] DECIMAL(15,3) DEFAULT 0,
        [qttspei] DECIMAL(15,3) DEFAULT 0,
        [qttordi] DECIMAL(15,3) DEFAULT 0,
        [codudc] INT DEFAULT 0,
        [LastUpdate] DATETIME DEFAULT GETDATE()
    );
    
    CREATE INDEX IX_CacheGiacenze_IdArticolo ON [dbo].[CacheGiacenze] ([idartico]);
    CREATE INDEX IX_CacheGiacenze_IdMag ON [dbo].[CacheGiacenze] ([idmag]);
    
    PRINT '✅ Tabella CacheGiacenze creata';
END

-- === PULIZIA CACHE PER TEST ===
TRUNCATE TABLE [dbo].[CacheGiacenze];
PRINT '🧹 Cache pulita per test';

-- === TEST 1: File piccolo (1 record) ===
PRINT '';
PRINT '=== TEST 1: File test_giamag_small.json (1 record) ===';

DECLARE @JsonFile1 NVARCHAR(500) = 'C:\temp\test_giamag_small.json';
DECLARE @JsonContent1 NVARCHAR(MAX);

-- Verifica esistenza file
DECLARE @FileCheck TABLE (line NVARCHAR(4000));
DECLARE @Cmd NVARCHAR(1000) = 'if exist "' + @JsonFile1 + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'EXISTS')
BEGIN
    PRINT '✅ File trovato: ' + @JsonFile1;
    
    -- Leggi file con SQL dinamico
    DECLARE @sql1 NVARCHAR(MAX) = N'SELECT @JsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @JsonFile1 + ''', SINGLE_CLOB) as j;';
    
    BEGIN TRY
        EXEC sp_executesql @sql1, N'@JsonOut NVARCHAR(MAX) OUTPUT', @JsonOut = @JsonContent1 OUTPUT;
        
        PRINT 'Lunghezza JSON: ' + CAST(LEN(@JsonContent1) as NVARCHAR);
        PRINT 'Anteprima: ' + LEFT(@JsonContent1, 100) + '...';
        
        -- Test parsing JSON
        SELECT 'Data Records' as Info, COUNT(*) as Valore
        FROM OPENJSON(@JsonContent1, '$.data');
        
        -- Inserimento in cache
        INSERT INTO [dbo].[CacheGiacenze] 
        (id, idartico, idmag, qttgiai, qttgiam, qttimpi, qttmani, qttspei, qttordi, codudc)
        SELECT 
            CAST(JSON_VALUE(value, '$.id') as INT),
            CAST(JSON_VALUE(value, '$.idartico') as INT),
            CAST(JSON_VALUE(value, '$.idmag') as INT),
            CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttgiam') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttmani') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttspei') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttordi') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.codudc') as INT)
        FROM OPENJSON(@JsonContent1, '$.data');
        
        PRINT '✅ Record inseriti: ' + CAST(@@ROWCOUNT as NVARCHAR);
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE elaborazione JSON: ' + ERROR_MESSAGE();
    END CATCH
    
END
ELSE
BEGIN
    PRINT '❌ File non trovato: ' + @JsonFile1;
END

-- === TEST 2: File con 10 record ===
PRINT '';
PRINT '=== TEST 2: File test_giamag_base.json (10 record) ===';

DELETE FROM @FileCheck;
DECLARE @JsonFile2 NVARCHAR(500) = 'C:\temp\test_giamag_base.json';
DECLARE @JsonContent2 NVARCHAR(MAX);

SET @Cmd = 'if exist "' + @JsonFile2 + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileCheck EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT 1 FROM @FileCheck WHERE line = 'EXISTS')
BEGIN
    PRINT '✅ File trovato: ' + @JsonFile2;
    
    DECLARE @sql2 NVARCHAR(MAX) = N'SELECT @JsonOut = BulkColumn FROM OPENROWSET(BULK ''' + @JsonFile2 + ''', SINGLE_CLOB) as j;';
    
    BEGIN TRY
        EXEC sp_executesql @sql2, N'@JsonOut NVARCHAR(MAX) OUTPUT', @JsonOut = @JsonContent2 OUTPUT;
        
        PRINT 'Lunghezza JSON: ' + CAST(LEN(@JsonContent2) as NVARCHAR);
        
        -- Conta record prima dell'inserimento
        SELECT 'Data Records Disponibili' as Info, COUNT(*) as Valore
        FROM OPENJSON(@JsonContent2, '$.data');
        
        -- Inserimento
        INSERT INTO [dbo].[CacheGiacenze] 
        (id, idartico, idmag, qttgiai, qttgiam, qttimpi, qttmani, qttspei, qttordi, codudc)
        SELECT 
            CAST(JSON_VALUE(value, '$.id') as INT),
            CAST(JSON_VALUE(value, '$.idartico') as INT),
            CAST(JSON_VALUE(value, '$.idmag') as INT),
            CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttgiam') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttmani') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttspei') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.qttordi') as DECIMAL(15,3)),
            CAST(JSON_VALUE(value, '$.codudc') as INT)
        FROM OPENJSON(@JsonContent2, '$.data');
        
        PRINT '✅ Record inseriti: ' + CAST(@@ROWCOUNT as NVARCHAR);
        
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE elaborazione JSON: ' + ERROR_MESSAGE();
    END CATCH
    
END

-- === VERIFICA FINALE ===
PRINT '';
PRINT '=== VERIFICA CACHE FINALE ===';

SELECT 'Totale record in cache' as Info, COUNT(*) as Valore FROM [dbo].[CacheGiacenze];

-- Mostra i primi record inseriti
SELECT TOP 5 
    id,
    idartico,
    idmag,
    qttgiai as Giacenza,
    qttimpi as Impegnata,
    (qttgiai - qttimpi) as Disponibile
FROM [dbo].[CacheGiacenze]
ORDER BY id;

-- Test query dell'articolo 28959 (primo nei file)
SELECT 'Test Query Articolo 28959' as Test, COUNT(*) as Trovati 
FROM [dbo].[CacheGiacenze] 
WHERE idartico = 28959;

PRINT '';
PRINT '💡 Se questo test funziona, il problema è nel ciclo di SincronizzaGiacenze.sql';
PRINT '💡 Se non funziona, il problema è nella lettura/parsing del JSON'; 