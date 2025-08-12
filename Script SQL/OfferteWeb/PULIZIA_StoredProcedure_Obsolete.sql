USE [PiattaformeWeb]
GO

-- =============================================
-- SCRIPT PULIZIA STORED PROCEDURE OBSOLETE
-- Elimina le stored procedure create durante lo sviluppo che non servono più
-- =============================================

PRINT '=========================================='
PRINT 'PULIZIA STORED PROCEDURE OBSOLETE'
PRINT 'Data/Ora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

-- ==========================================
-- STORED PROCEDURE DA ELIMINARE
-- ==========================================

-- 1. Versione vecchia senza logica TipoPubPiatt
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GeneratePlatformPrices')
BEGIN
    DROP PROCEDURE SP_GeneratePlatformPrices
    PRINT '✅ Eliminata: SP_GeneratePlatformPrices (sostituita da SP_GeneratePlatformPrices_V2)'
END
ELSE
    PRINT '⚠️  SP_GeneratePlatformPrices non trovata'

-- 2. Versione orchestratore vecchia
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_NewDistributionSystem')
BEGIN
    DROP PROCEDURE SP_NewDistributionSystem
    PRINT '✅ Eliminata: SP_NewDistributionSystem (sostituita da script di test specifici)'
END
ELSE
    PRINT '⚠️  SP_NewDistributionSystem non trovata'

-- 3. Versione integrata se esiste
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_NewDistributionSystem_Integrated')
BEGIN
    DROP PROCEDURE SP_NewDistributionSystem_Integrated
    PRINT '✅ Eliminata: SP_NewDistributionSystem_Integrated (sostituita da script specifici)'
END
ELSE
    PRINT '⚠️  SP_NewDistributionSystem_Integrated non trovata'

-- 4. Eventuali versioni di test
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GenerateCollegatiPrices')
BEGIN
    DROP PROCEDURE SP_GenerateCollegatiPrices
    PRINT '✅ Eliminata: SP_GenerateCollegatiPrices (sostituita da SP_GenerateCollegatiPrices_V2)'
END
ELSE
    PRINT '⚠️  SP_GenerateCollegatiPrices non trovata'

PRINT ''
PRINT '=========================================='
PRINT 'STORED PROCEDURE FINALI DA USARE:'
PRINT '=========================================='
PRINT '1. SP_InitializeDistributionTables'
PRINT '2. SP_CalculatePriceRanges'  
PRINT '3. SP_GenerateB2BPrices'
PRINT '4. SP_GeneratePlatformPrices_V2'
PRINT '5. SP_GenerateCollegatiPrices_V2'
PRINT '6. SP_CompareDistributionSystems'
PRINT ''
PRINT 'SCRIPT DI TEST:'
PRINT '- TEST_NuovoSistema_OfferteWeb_Tmp.sql'
PRINT ''
PRINT '=========================================='
PRINT 'PULIZIA COMPLETATA!'
PRINT '=========================================='

GO 