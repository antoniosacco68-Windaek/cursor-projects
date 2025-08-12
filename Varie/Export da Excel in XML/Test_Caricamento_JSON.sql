-- ====================================================================
-- TEST CARICAMENTO FILE JSON
-- ====================================================================

USE [PiattaformeWeb];
GO

PRINT '🔍 TEST CARICAMENTO FILE JSON';
PRINT '=====================================';

-- Test 1: Caricamento senza CODEPAGE
PRINT '📥 Test 1: Caricamento senza CODEPAGE';
DECLARE @jsonContent1 NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent1 = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB
    ) AS j;
    
    PRINT '✅ File caricato: ' + CAST(LEN(@jsonContent1) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔍 JSON valido: ' + CASE WHEN ISJSON(@jsonContent1) = 1 THEN 'SÌ' ELSE 'NO' END;
    PRINT '📄 Primi 200 caratteri:';
    PRINT LEFT(@jsonContent1, 200);
    PRINT '📄 Ultimi 200 caratteri:';
    PRINT RIGHT(@jsonContent1, 200);
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '=====================================';

-- Test 2: Caricamento con UTF-8
PRINT '📥 Test 2: Caricamento con CODEPAGE 65001 (UTF-8)';
DECLARE @jsonContent2 NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent2 = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB, 
        CODEPAGE = '65001'
    ) AS j;
    
    PRINT '✅ File caricato: ' + CAST(LEN(@jsonContent2) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔍 JSON valido: ' + CASE WHEN ISJSON(@jsonContent2) = 1 THEN 'SÌ' ELSE 'NO' END;
    PRINT '📄 Primi 200 caratteri:';
    PRINT LEFT(@jsonContent2, 200);
    PRINT '📄 Ultimi 200 caratteri:';
    PRINT RIGHT(@jsonContent2, 200);
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '=====================================';

-- Test 3: Caricamento con Windows-1252
PRINT '📥 Test 3: Caricamento con CODEPAGE 1252 (Windows-1252)';
DECLARE @jsonContent3 NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent3 = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB, 
        CODEPAGE = '1252'
    ) AS j;
    
    PRINT '✅ File caricato: ' + CAST(LEN(@jsonContent3) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔍 JSON valido: ' + CASE WHEN ISJSON(@jsonContent3) = 1 THEN 'SÌ' ELSE 'NO' END;
    PRINT '📄 Primi 200 caratteri:';
    PRINT LEFT(@jsonContent3, 200);
    PRINT '📄 Ultimi 200 caratteri:';
    PRINT RIGHT(@jsonContent3, 200);
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '=====================================';

-- Test 4: Verifica configurazione SQL Server
PRINT '🔧 Test 4: Verifica configurazione OPENROWSET';

BEGIN TRY
    -- Controlla se Ad Hoc Distributed Queries è abilitato
    IF EXISTS (
        SELECT * FROM sys.configurations 
        WHERE name = 'Ad Hoc Distributed Queries' 
        AND value = 1
    )
        PRINT '✅ Ad Hoc Distributed Queries: ABILITATO';
    ELSE
        PRINT '❌ Ad Hoc Distributed Queries: DISABILITATO';

    -- Verifica esistenza file
    IF EXISTS (
        SELECT * FROM sys.dm_os_file_exists('C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json') 
        WHERE file_exists = 1
    )
        PRINT '✅ File esistente: SÌ';
    ELSE
        PRINT '❌ File esistente: NO';

END TRY
BEGIN CATCH
    PRINT '❌ ERRORE verifica configurazione: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '=====================================';
PRINT '🎯 QUALE TEST FUNZIONA?';
PRINT 'Copia il risultato e dimmi quale test ha caricato correttamente il JSON!';

GO 