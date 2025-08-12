-- RICERCA RAPIDA GIACENZE - SENZA SINCRONIZZAZIONE COMPLETA
-- Per quando hai bisogno del risultato SUBITO

DECLARE @PowerShellScript NVARCHAR(500) = 'C:\Antonio\SamV6\ScriptPS\ApiCaller.ps1';
DECLARE @IdArticolo INT = 512534;  -- ⬅️ CAMBIA QUI L'ID ARTICOLO
DECLARE @Cmd NVARCHAR(4000), @Result TABLE (line NVARCHAR(4000));

PRINT '=== RICERCA RAPIDA GIACENZE ARTICOLO: ' + CAST(@IdArticolo as NVARCHAR) + ' ===';

-- === STRATEGIA 1: Controllo cache locale se esiste ===
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CacheGiacenze]') AND type in (N'U'))
    AND EXISTS (SELECT 1 FROM [dbo].[CacheGiacenze])
BEGIN
    PRINT '🔍 Controllo cache locale esistente...';
    
    IF EXISTS (SELECT 1 FROM [dbo].[CacheGiacenze] WHERE idartico = @IdArticolo)
    BEGIN
        PRINT '✅ TROVATO IN CACHE LOCALE!';
        SELECT 
            'CACHE LOCALE' as Fonte,
            idmag as IdMagazzino,
            qttgiai as Giacenza,
            qttimpi as Impegnata,
            (qttgiai - qttimpi) as Disponibile,
            LastUpdate as UltimoAggiornamento
        FROM [dbo].[CacheGiacenze] 
        WHERE idartico = @IdArticolo
        ORDER BY qttgiai DESC;
        
        DECLARE @CacheAge INT = (SELECT DATEDIFF(hour, MAX(LastUpdate), GETDATE()) FROM [dbo].[CacheGiacenze]);
        PRINT 'Cache aggiornata ' + CAST(@CacheAge as NVARCHAR) + ' ore fa';
        
        IF @CacheAge < 8  -- Cache recente
        BEGIN
            PRINT '✅ Cache recente - risultati affidabili';
            RETURN;
        END
        ELSE
        BEGIN
            PRINT '⚠️  Cache datata - continuando con ricerca API...';
        END
    END
    ELSE
    BEGIN
        PRINT '❌ Articolo non trovato in cache locale';
        PRINT '🔍 Continuando con ricerca API...';
    END
END

-- === STRATEGIA 2: Ricerca Intelligente a Blocchi ===
PRINT '';
PRINT '🚀 RICERCA INTELLIGENTE SU API...';

-- Ottieni info totali
DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\ricerca_rapida.json';
DECLARE @Endpoint NVARCHAR(200) = '/api/v1/giaMag?pageno=1&pagesize=1';

SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd;

DECLARE @JsonInfo NVARCHAR(MAX);
SELECT @JsonInfo = BulkColumn FROM OPENROWSET(BULK 'C:\temp\ricerca_rapida.json', SINGLE_CLOB) as j;

DECLARE @TotalRecords INT = CAST(JSON_VALUE(@JsonInfo, '$.paging.totalrecordcount') as INT);
DECLARE @PageSize INT = 1000;  -- Blocchi grandi
DECLARE @MaxBlocks INT = 10;   -- Massimo 10 blocchi = 10.000 record

PRINT 'Totale record: ' + CAST(@TotalRecords as NVARCHAR);
PRINT 'Cercando nei primi ' + CAST(@MaxBlocks * @PageSize as NVARCHAR) + ' record...';

-- === Ricerca a blocchi ===
DECLARE @BlockNum INT = 1;
DECLARE @Found BIT = 0;

WHILE @BlockNum <= @MaxBlocks AND @Found = 0
BEGIN
    PRINT 'Blocco ' + CAST(@BlockNum as NVARCHAR) + ': record ' + 
          CAST(((@BlockNum-1) * @PageSize + 1) as NVARCHAR) + '-' + 
          CAST((@BlockNum * @PageSize) as NVARCHAR);
    
    -- Scarica blocco corrente
    SET @Endpoint = '/api/v1/giaMag?pageno=' + CAST(@BlockNum as NVARCHAR) + '&pagesize=' + CAST(@PageSize as NVARCHAR);
    SET @OutputFile = 'C:\temp\blocco_' + CAST(@BlockNum as NVARCHAR) + '.json';
    
    DELETE FROM @Result;
    SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';
    INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    
    -- Controlla se trovato
    DECLARE @FileExists TABLE (line NVARCHAR(4000));
    SET @Cmd = 'if exist "' + @OutputFile + '" echo FILE_EXISTS else echo FILE_NOT_FOUND';
    INSERT INTO @FileExists EXEC xp_cmdshell @Cmd;
    
    IF EXISTS (SELECT 1 FROM @FileExists WHERE line = 'FILE_EXISTS')
    BEGIN
        DECLARE @JsonBlock NVARCHAR(MAX);
        -- Correzione: OPENROWSET non accetta variabili per il percorso file, quindi bisogna usare SQL dinamico
        DECLARE @sql NVARCHAR(MAX) = N'SELECT @JsonBlockOut = BulkColumn FROM OPENROWSET(BULK ''' + @OutputFile + ''', SINGLE_CLOB) as j;';
        EXEC sp_executesql @sql, N'@JsonBlockOut NVARCHAR(MAX) OUTPUT', @JsonBlockOut = @JsonBlock OUTPUT;
        
        -- Cerca articolo in questo blocco
        IF EXISTS (
            SELECT 1 FROM OPENJSON(@JsonBlock, '$.data') 
            WHERE JSON_VALUE(value, '$.idartico') = CAST(@IdArticolo as NVARCHAR)
        )
        BEGIN
            PRINT '🎯 ARTICOLO TROVATO nel blocco ' + CAST(@BlockNum as NVARCHAR) + '!';
            
            -- Mostra risultati
            SELECT 
                'API BLOCCO ' + CAST(@BlockNum as NVARCHAR) as Fonte,
                JSON_VALUE(value, '$.idartico') as IdArticolo,
                JSON_VALUE(value, '$.idmag') as IdMagazzino,
                CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)) as Giacenza,
                CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3)) as Impegnata,
                CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)) - 
                CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3)) as Disponibile
            FROM OPENJSON(@JsonBlock, '$.data') 
            WHERE JSON_VALUE(value, '$.idartico') = CAST(@IdArticolo as NVARCHAR)
            ORDER BY CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3)) DESC;
            
            -- Riepilogo
            SELECT 
                @IdArticolo as IdArticolo,
                COUNT(*) as NumMagazzini,
                SUM(CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3))) as TotaleGiacenza,
                SUM(CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3))) as TotaleImpegnata,
                SUM(CAST(JSON_VALUE(value, '$.qttgiai') as DECIMAL(15,3))) - 
                SUM(CAST(JSON_VALUE(value, '$.qttimpi') as DECIMAL(15,3))) as TotaleDisponibile
            FROM OPENJSON(@JsonBlock, '$.data') 
            WHERE JSON_VALUE(value, '$.idartico') = CAST(@IdArticolo as NVARCHAR);
            
            SET @Found = 1;
        END
        
        -- Pulizia
        SET @Cmd = 'del "' + @OutputFile + '"';
        INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    END
    
    DELETE FROM @FileExists;
    SET @BlockNum = @BlockNum + 1;
END

-- === Risultato finale ===
IF @Found = 0
BEGIN
    PRINT '';
    PRINT '❌ ARTICOLO NON TROVATO nei primi ' + CAST(@MaxBlocks * @PageSize as NVARCHAR) + ' record';
    PRINT '';
    PRINT '💡 SOLUZIONI:';
    PRINT '1. 🔄 Esegui SincronizzaGiacenze.sql per scaricare tutto';
    PRINT '2. 🔢 Prova con un ID articolo diverso';
    PRINT '3. 📞 Verifica che l''articolo esista nel gestionale';
    
    -- Mostra campione dei primi record per debug
    PRINT '';
    PRINT '🔍 CAMPIONE PRIMI RECORD (per debug):';
    SET @OutputFile = 'C:\temp\sample.json';
    SET @Endpoint = '/api/v1/giaMag?pageno=1&pagesize=5';
    
    DELETE FROM @Result;
    SET @Cmd = 'powershell.exe -ExecutionPolicy Bypass -File "' + @PowerShellScript + '" -Action full -Endpoint "' + @Endpoint + '" -OutputFile "' + @OutputFile + '"';
    INSERT INTO @Result EXEC xp_cmdshell @Cmd;
    
    DECLARE @JsonSample NVARCHAR(MAX);
    SELECT @JsonSample = BulkColumn FROM OPENROWSET(BULK 'C:\temp\sample.json', SINGLE_CLOB) as j;
    
    SELECT 
        'CAMPIONE' as Tipo,
        JSON_VALUE(value, '$.idartico') as IdArticolo,
        JSON_VALUE(value, '$.idmag') as IdMagazzino,
        JSON_VALUE(value, '$.qttgiai') as Giacenza
    FROM OPENJSON(@JsonSample, '$.data');
END
ELSE
BEGIN
    PRINT '';
    PRINT '✅ RICERCA COMPLETATA con successo!';
    PRINT '⏱️  Tempo di ricerca: molto più veloce della sincronizzazione completa';
END

-- Pulizia finale
SET @Cmd = 'del "C:\temp\ricerca_rapida.json" "C:\temp\sample.json" "C:\temp\blocco_*.json"';
INSERT INTO @Result EXEC xp_cmdshell @Cmd; 