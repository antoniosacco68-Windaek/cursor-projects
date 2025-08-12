-- ====================================================================
-- TEST CODIFICA UTF-16 
-- ====================================================================

USE [PiattaformeWeb];
GO

PRINT '🔍 TEST CODIFICA UTF-16';
PRINT '=====================================';

-- Test UTF-16 Little Endian
PRINT '📥 Test UTF-16 Little Endian (1200)';
DECLARE @jsonContent1 NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent1 = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB, 
        CODEPAGE = '1200'
    ) AS j;
    
    PRINT '✅ File caricato: ' + CAST(LEN(@jsonContent1) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔍 JSON valido: ' + CASE WHEN ISJSON(@jsonContent1) = 1 THEN 'SÌ' ELSE 'NO' END;
    PRINT '📄 Primi 200 caratteri:';
    PRINT LEFT(@jsonContent1, 200);
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE: ' + ERROR_MESSAGE();
END CATCH

PRINT '';
PRINT '=====================================';

-- Test UTF-16 Big Endian
PRINT '📥 Test UTF-16 Big Endian (1201)';
DECLARE @jsonContent2 NVARCHAR(MAX);

BEGIN TRY
    SELECT @jsonContent2 = BulkColumn 
    FROM OPENROWSET(
        BULK 'C:\Antonio\PrezziDistribuzione\FileDiImportazioneJSON\PrezziManualiDistribuzioneIT.json', 
        SINGLE_BLOB, 
        CODEPAGE = '1201'
    ) AS j;
    
    PRINT '✅ File caricato: ' + CAST(LEN(@jsonContent2) AS NVARCHAR(10)) + ' caratteri';
    PRINT '🔍 JSON valido: ' + CASE WHEN ISJSON(@jsonContent2) = 1 THEN 'SÌ' ELSE 'NO' END;
    PRINT '📄 Primi 200 caratteri:';
    PRINT LEFT(@jsonContent2, 200);
    
END TRY
BEGIN CATCH
    PRINT '❌ ERRORE: ' + ERROR_MESSAGE();
END CATCH

GO 