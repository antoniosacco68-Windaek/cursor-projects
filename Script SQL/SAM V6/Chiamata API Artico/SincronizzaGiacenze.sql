-- SINCRONIZZAZIONE GIACENZE - SCARICA TUTTO IN TABELLA LOCALE
-- Esegui questo script una volta al giorno (o quando necessario)

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @Cmd NVARCHAR(4000);
DECLARE @Result TABLE (line NVARCHAR(4000));

-- === CREA TABELLA CACHE GIACENZE (se non esiste) ===
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
    
    -- Indice per ricerche rapide per articolo
    CREATE INDEX IX_CacheGiacenze_IdArticolo ON [dbo].[CacheGiacenze] ([idartico]);
    CREATE INDEX IX_CacheGiacenze_IdMag ON [dbo].[CacheGiacenze] ([idmag]);
    
    PRINT '✅ Tabella CacheGiacenze creata con successo';
END

-- === OTTIENI INFO PAGINAZIONE ===
PRINT '=== INIZIO SINCRONIZZAZIONE GIACENZE ===';
PRINT '1. Ottenendo informazioni totali...';

DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\giacenze_info.json';
DECLARE @Endpoint NVARCHAR(200) = '/api/v1/giaMag?pageno=1&pagesize=1';  -- Solo per ottenere info paging

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

-- Leggi info paginazione
DECLARE @JsonInfo NVARCHAR(MAX);
SELECT @JsonInfo = BulkColumn FROM OPENROWSET(BULK 'C:\temp\giacenze_info.json', SINGLE_CLOB) as j;

DECLARE @TotalPages INT = CAST(JSON_VALUE(@JsonInfo, '$.paging.pagecount') as INT);
DECLARE @TotalRecords INT = CAST(JSON_VALUE(@JsonInfo, '$.paging.totalrecordcount') as INT);
DECLARE @PageSize INT = 500; -- Pagine più grandi per meno chiamate

PRINT 'Totale Pagine: ' + CAST(@TotalPages as NVARCHAR);
PRINT 'Totale Record: ' + CAST(@TotalRecords as NVARCHAR);
PRINT 'Pagesize usato: ' + CAST(@PageSize as NVARCHAR);

-- === SVUOTA CACHE PRECEDENTE ===
TRUNCATE TABLE [dbo].[CacheGiacenze];
PRINT '2. Cache precedente svuotata';

-- === CICLO ATTRAVERSO TUTTE LE PAGINE ===
DECLARE @CurrentPage INT = 1;
DECLARE @MaxPage INT = CEILING(CAST(@TotalRecords as FLOAT) / @PageSize);
DECLARE @ProcessedRecords INT = 0;

PRINT '3. Inizio download di ' + CAST(@MaxPage as NVARCHAR) + ' pagine...';

WHILE @CurrentPage <= @MaxPage
BEGIN
    -- Progress ogni 10 pagine
    IF @CurrentPage % 10 = 0 OR @CurrentPage = 1
        PRINT 'Processando pagina ' + CAST(@CurrentPage as NVARCHAR) + ' di ' + CAST(@MaxPage as NVARCHAR);
    
    -- Scarica pagina corrente
    SET @Endpoint = '/api/v1/giaMag?pageno=' + CAST(@CurrentPage as NVARCHAR) + '&pagesize=' + CAST(@PageSize as NVARCHAR);
    SET @OutputFile = 'C:\temp\giacenze_page_' + CAST(@CurrentPage as NVARCHAR) + '.json';
    
    DELETE FROM @Result;
    SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';
    INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    
    -- Leggi e inserisci dati direttamente (senza controllo file che causava problemi)
    BEGIN TRY
        DECLARE @JsonPage NVARCHAR(MAX);
        -- OPENROWSET non accetta variabili come percorso file, quindi bisogna usare SQL dinamico
        DECLARE @sql NVARCHAR(MAX) = N'SELECT @JsonPageOut = BulkColumn FROM OPENROWSET(BULK ''' + @OutputFile + ''', SINGLE_CLOB) as j;';
        EXEC sp_executesql @sql, N'@JsonPageOut NVARCHAR(MAX) OUTPUT', @JsonPageOut = @JsonPage OUTPUT;
        
        -- Verifica che il JSON contenga dati
        IF @JsonPage IS NOT NULL AND LEN(@JsonPage) > 50 AND CHARINDEX('"data":', @JsonPage) > 0
        BEGIN
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
            FROM OPENJSON(@JsonPage, '$.data');
            
            SET @ProcessedRecords = @ProcessedRecords + @@ROWCOUNT;
            
            -- Rimuovi file temporaneo
            SET @Cmd = 'del "' + @OutputFile + '"';
            INSERT INTO @Result EXEC xp_cmdshell @Cmd;
        END
        ELSE
        BEGIN
            PRINT '⚠️ WARNING: Pagina ' + CAST(@CurrentPage as NVARCHAR) + ' - JSON vuoto o non valido';
        END
    END TRY
    BEGIN CATCH
        PRINT '❌ ERRORE pagina ' + CAST(@CurrentPage as NVARCHAR) + ': ' + ERROR_MESSAGE();
        -- Continua con la pagina successiva invece di fermarsi
    END CATCH
    SET @CurrentPage = @CurrentPage + 1;
END

-- === RIEPILOGO FINALE ===
PRINT '=== SINCRONIZZAZIONE COMPLETATA ===';
PRINT 'Record processati: ' + CAST(@ProcessedRecords as NVARCHAR);
PRINT 'Record in cache: ' + CAST((SELECT COUNT(*) FROM [dbo].[CacheGiacenze]) as NVARCHAR);
PRINT 'Ultimo aggiornamento: ' + CONVERT(NVARCHAR, GETDATE(), 120);

-- Pulizia file temporanei
SET @Cmd = 'del "C:\temp\giacenze_*.json"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

PRINT '✅ Cache giacenze sincronizzata con successo!';
PRINT '';
PRINT '🎯 Ora puoi usare query rapide tipo:';
PRINT 'SELECT * FROM CacheGiacenze WHERE idartico = 512534'; 