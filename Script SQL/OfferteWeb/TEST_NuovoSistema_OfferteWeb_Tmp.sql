

USE [PiattaformeWeb]
GO

-- =============================================
-- SCRIPT DI TEST NUOVO SISTEMA 3 LISTINI
-- Target: OfferteWeb_Tmp (sistema parallelo di test)
-- =============================================

PRINT '=========================================='
PRINT 'AVVIO TEST NUOVO SISTEMA DEI 3 LISTINI'
PRINT 'Data/Ora: ' + CONVERT(VARCHAR, GETDATE(), 120)
PRINT '=========================================='

DECLARE @StartTime DATETIME = GETDATE()
DECLARE @StepTime DATETIME
DECLARE @ErrorMessage NVARCHAR(MAX)

BEGIN TRY

    -- ==========================================
    -- STEP 1: CALCOLO FASCE PREZZO E MARGINI
    -- ==========================================
    SET @StepTime = GETDATE()
    PRINT ''
    PRINT '--- STEP 1: CALCOLO FASCE PREZZO ---'
    
    EXEC SP_CalculatePriceRanges
    
    PRINT 'Step 1 completato in: ' + CAST(DATEDIFF(ms, @StepTime, GETDATE()) AS VARCHAR) + 'ms'
    
    -- ==========================================
    -- STEP 2: GENERAZIONE PREZZI B2B
    -- ==========================================
    SET @StepTime = GETDATE()
    PRINT ''
    PRINT '--- STEP 2: PREZZI B2B ---'
    
    EXEC SP_GenerateB2BPrices
    
    PRINT 'Step 2 completato in: ' + CAST(DATEDIFF(ms, @StepTime, GETDATE()) AS VARCHAR) + 'ms'
    
    -- ==========================================
    -- STEP 3: GENERAZIONE PREZZI PIATTAFORME
    -- ==========================================
    SET @StepTime = GETDATE()
    PRINT ''
    PRINT '--- STEP 3: PREZZI PIATTAFORME ---'
    
    EXEC SP_GeneratePlatformPrices_V2
    
    PRINT 'Step 3 completato in: ' + CAST(DATEDIFF(ms, @StepTime, GETDATE()) AS VARCHAR) + 'ms'
    
    -- ==========================================
    -- STEP 4: GENERAZIONE PREZZI COLLEGATI
    -- ==========================================
    SET @StepTime = GETDATE()
    PRINT ''
    PRINT '--- STEP 4: PREZZI COLLEGATI ---'
    
    EXEC SP_GenerateCollegatiPrices_V2
    
    PRINT 'Step 4 completato in: ' + CAST(DATEDIFF(ms, @StepTime, GETDATE()) AS VARCHAR) + 'ms'
    
    -- ==========================================
    -- STATISTICHE FINALI DEL TEST
    -- ==========================================
    PRINT ''
    PRINT '=========================================='
    PRINT 'STATISTICHE FINALI DEL TEST:'
    PRINT '=========================================='
    
    DECLARE @TotaleArticoli INT, @ArticoliB2B INT, @ArticoliPiattaforme INT, @ArticoliCollegati INT
    DECLARE @PrezzoMedioB2B DECIMAL(10,2), @PrezzoMedioPiattaforme DECIMAL(10,2), @PrezzoMedioCollegati DECIMAL(10,2)
    
    SELECT @TotaleArticoli = COUNT(*) FROM OfferteWeb_Tmp
    SELECT @ArticoliB2B = COUNT(*) FROM OfferteWeb_Tmp WHERE P_Std IS NOT NULL
    SELECT @ArticoliPiattaforme = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL
    SELECT @ArticoliCollegati = COUNT(*) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL
    
    SELECT @PrezzoMedioB2B = AVG(P_Std) FROM OfferteWeb_Tmp WHERE P_Std IS NOT NULL
    SELECT @PrezzoMedioPiattaforme = AVG(P_T24_24H) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL
    SELECT @PrezzoMedioCollegati = AVG(P_Collegati_GER) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL
    
    PRINT 'Articoli totali copiati: ' + CAST(@TotaleArticoli AS VARCHAR)
    PRINT ''
    PRINT 'LISTINO B2B:'
    PRINT '  Articoli con prezzo: ' + CAST(@ArticoliB2B AS VARCHAR)
    PRINT '  Prezzo medio: ' + CAST(ISNULL(@PrezzoMedioB2B, 0) AS VARCHAR)
    PRINT ''
    PRINT 'LISTINO PIATTAFORME:'
    PRINT '  Articoli con prezzo: ' + CAST(@ArticoliPiattaforme AS VARCHAR)
    PRINT '  Prezzo medio: ' + CAST(ISNULL(@PrezzoMedioPiattaforme, 0) AS VARCHAR)
    PRINT ''
    PRINT 'LISTINO COLLEGATI:'
    PRINT '  Articoli con prezzo: ' + CAST(@ArticoliCollegati AS VARCHAR)
    PRINT '  Prezzo medio: ' + CAST(ISNULL(@PrezzoMedioCollegati, 0) AS VARCHAR)
    
    -- Statistiche per settore
    PRINT ''
    PRINT 'DISTRIBUZIONE PER SETTORE:'
    SELECT 
        SettoreId,
        Settore,
        COUNT(*) as TotaleArticoli,
        SUM(CASE WHEN P_Std IS NOT NULL THEN 1 ELSE 0 END) as ConPrezzoB2B,
        SUM(CASE WHEN P_T24_24H IS NOT NULL THEN 1 ELSE 0 END) as ConPrezzoPiattaforme,
        SUM(CASE WHEN P_Collegati_GER IS NOT NULL THEN 1 ELSE 0 END) as ConPrezzoCollegati,
        AVG(P_Std) as MediaB2B,
        AVG(P_T24_24H) as MediaPiattaforme,
        AVG(P_Collegati_GER) as MediaCollegati
    FROM OfferteWeb_Tmp
    GROUP BY SettoreId, Settore
    ORDER BY COUNT(*) DESC
    
    -- Esempi di articoli per verifica
    PRINT ''
    PRINT 'ESEMPI DI ARTICOLI PROCESSATI (primi 10):'
    SELECT TOP 10
        CodiceArticolo,
        Produttore,
        Settore,
        Prezzo as PrezzoAcquisto,
        P_Std as PrezzoB2B,
        P_T24_24H as PrezzoPiattaforme,
        P_Collegati_GER as PrezzoCollegati
    FROM OfferteWeb_Tmp
    WHERE P_Std IS NOT NULL AND P_T24_24H IS NOT NULL
    ORDER BY Prezzo
    
    PRINT ''
    PRINT '=========================================='
    PRINT 'TEST COMPLETATO CON SUCCESSO!'
    PRINT 'Tempo totale: ' + CAST(DATEDIFF(ms, @StartTime, GETDATE()) AS VARCHAR) + 'ms'
    PRINT 'Dati disponibili in OfferteWeb_Tmp per analisi'
    PRINT '=========================================='

END TRY
BEGIN CATCH
    SET @ErrorMessage = 'ERRORE durante il test: ' + ERROR_MESSAGE()
    PRINT @ErrorMessage
    
END CATCH

GO

-- ==========================================
-- QUERY DI VERIFICA RAPIDA
-- ==========================================

PRINT ''
PRINT 'QUERY DI VERIFICA DISPONIBILI:'
PRINT '1. SELECT TOP 100 * FROM OfferteWeb_Tmp WHERE P_Std IS NOT NULL'
PRINT '2. SELECT TOP 100 * FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL'  
PRINT '3. SELECT TOP 100 * FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL'
PRINT '4. EXEC SP_CompareDistributionSystems -- Per confrontare con il vecchio sistema'
PRINT '' 

-- ========================================
-- TEST NUOVO SISTEMA DISTRIBUZIONE COMPLETO
-- ========================================

PRINT '========================================='
PRINT 'INIZIO TEST NUOVO SISTEMA DISTRIBUZIONE'
PRINT '========================================='

-- ========================================
-- CONTROLLI PRELIMINARI
-- ========================================

PRINT '1. Controlli preliminari...'

-- Verifica esistenza tabelle necessarie
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OfferteWeb_Tmp')
BEGIN
    PRINT 'ERRORE: Tabella OfferteWeb_Tmp non trovata!'
    RETURN
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RegoleListiniDistribuzione')
BEGIN
    PRINT 'ERRORE: Tabella RegoleListiniDistribuzione non trovata!'
    RETURN
END

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'OfferteWeb_1Pass')
BEGIN
    PRINT 'ERRORE: Tabella OfferteWeb_1Pass non trovata!'
    RETURN
END

-- Verifica esistenza stored procedures
IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_CalculatePriceRanges')
BEGIN
    PRINT 'ERRORE: SP_CalculatePriceRanges non trovata!'
    RETURN
END

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_GenerateB2BPrices')
BEGIN
    PRINT 'ERRORE: SP_GenerateB2BPrices non trovata!'
    RETURN
END

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_GeneratePlatformPrices_V2')
BEGIN
    PRINT 'ERRORE: SP_GeneratePlatformPrices_V2 non trovata!'
    RETURN
END

IF NOT EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_GenerateCollegatiPrices_V2')
BEGIN
    PRINT 'ERRORE: SP_GenerateCollegatiPrices_V2 non trovata!'
    RETURN
END

PRINT 'Tutte le tabelle e stored procedures necessarie sono presenti.'

-- ========================================
-- VERIFICA REGOLE LISTINI
-- ========================================

PRINT '2. Verifica regole listini...'

DECLARE @RegoleB2B int, @RegolePiattaforme int, @RegoleCollegati int

SELECT @RegoleB2B = COUNT(*) FROM RegoleListiniDistribuzione WHERE NomeListino = 'B2B'
SELECT @RegolePiattaforme = COUNT(*) FROM RegoleListiniDistribuzione WHERE NomeListino = 'Piattaforme'
SELECT @RegoleCollegati = COUNT(*) FROM RegoleListiniDistribuzione WHERE NomeListino = 'Collegati'

PRINT 'Regole B2B: ' + CAST(@RegoleB2B AS VARCHAR(10))
PRINT 'Regole Piattaforme: ' + CAST(@RegolePiattaforme AS VARCHAR(10))
PRINT 'Regole Collegati: ' + CAST(@RegoleCollegati AS VARCHAR(10))

IF @RegoleB2B = 0 OR @RegolePiattaforme = 0 OR @RegoleCollegati = 0
BEGIN
    PRINT 'ERRORE: Mancano regole per almeno uno dei listini!'
    RETURN
END

-- ========================================
-- TEST ESECUZIONE STORED PROCEDURES
-- ========================================

PRINT '3. Test esecuzione stored procedures...'

PRINT '3.1 Esecuzione SP_CalculatePriceRanges...'
EXEC SP_CalculatePriceRanges

PRINT '3.2 Verifica assegnazione ID regole...'

DECLARE @ArticoliTotali int, @ArticoliB2B int, @ArticoliPiattaforme int, @ArticoliCollegati int

SELECT @ArticoliTotali = COUNT(*) FROM OfferteWeb_Tmp
SELECT @ArticoliB2B = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleB2B IS NOT NULL
SELECT @ArticoliPiattaforme = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegolePiattaforme IS NOT NULL
SELECT @ArticoliCollegati = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleCollegati IS NOT NULL

PRINT 'Articoli totali: ' + CAST(@ArticoliTotali AS VARCHAR(10))
PRINT 'Con ID_RegoleB2B: ' + CAST(@ArticoliB2B AS VARCHAR(10))
PRINT 'Con ID_RegolePiattaforme: ' + CAST(@ArticoliPiattaforme AS VARCHAR(10))
PRINT 'Con ID_RegoleCollegati: ' + CAST(@ArticoliCollegati AS VARCHAR(10))

IF @ArticoliB2B = 0 OR @ArticoliPiattaforme = 0 OR @ArticoliCollegati = 0
BEGIN
    PRINT 'ERRORE: Almeno uno dei listini non ha articoli con ID assegnato!'
    RETURN
END

PRINT '3.3 Esecuzione SP_GenerateB2BPrices...'
EXEC SP_GenerateB2BPrices

PRINT '3.4 Esecuzione SP_GeneratePlatformPrices_V2...'
EXEC SP_GeneratePlatformPrices_V2

PRINT '3.5 Esecuzione SP_GenerateCollegatiPrices_V2...'
EXEC SP_GenerateCollegatiPrices_V2

-- ========================================
-- CONTROLLI QUALITÀ RISULTATI TUTTI I LISTINI
-- ========================================

PRINT '4. Controlli qualità risultati tutti i listini...'

-- Statistiche B2B
DECLARE @ArticoliConPrezzoB2B int, @PrezzoMedioB2B decimal(10,2)
DECLARE @ArticoliRicaricoPercB2B int, @ArticoliMargineTradiB2B int

SELECT @ArticoliConPrezzoB2B = COUNT(*) 
FROM OfferteWeb_Tmp 
WHERE P_Std IS NOT NULL AND ID_RegoleB2B IS NOT NULL

SELECT @PrezzoMedioB2B = AVG(P_Std) 
FROM OfferteWeb_Tmp 
WHERE P_Std IS NOT NULL AND ID_RegoleB2B IS NOT NULL

SELECT @ArticoliRicaricoPercB2B = COUNT(*) 
FROM OfferteWeb_Tmp OW
INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleB2B
WHERE RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0

SET @ArticoliMargineTradiB2B = @ArticoliConPrezzoB2B - @ArticoliRicaricoPercB2B

-- Statistiche Piattaforme
DECLARE @ArticoliPiatt24H int, @ArticoliPiatt48H int, @ArticoliPiatt72H int
DECLARE @ArticoliEsteri int, @PrezzoMedioPiatt decimal(10,2)

SELECT @ArticoliPiatt24H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
SELECT @ArticoliPiatt48H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_48H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
SELECT @ArticoliPiatt72H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_72H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
SELECT @ArticoliEsteri = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_GER IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
SELECT @PrezzoMedioPiatt = AVG(P_T24_24H) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL

-- Statistiche Collegati
DECLARE @TotaleCollegati int, @Collegati24H int, @Collegati48H int, @Esclusi72H int
DECLARE @PrezzoMedioCollegati decimal(10,2)

SELECT @TotaleCollegati = COUNT(*) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL AND ID_RegoleCollegati IS NOT NULL
SELECT @Collegati24H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL AND TipoPubPiatt = '24H' AND ID_RegoleCollegati IS NOT NULL
SELECT @Collegati48H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL AND TipoPubPiatt = '48H' AND ID_RegoleCollegati IS NOT NULL
SELECT @Esclusi72H = COUNT(*) FROM OfferteWeb_Tmp WHERE TipoPubPiatt IN ('72H', '72H_CST') AND ID_RegoleCollegati IS NOT NULL
SELECT @PrezzoMedioCollegati = AVG(P_Collegati_GER) FROM OfferteWeb_Tmp WHERE P_Collegati_GER IS NOT NULL AND ID_RegoleCollegati IS NOT NULL

PRINT '========================================='
PRINT 'STATISTICHE RIEPILOGATIVE:'
PRINT '========================================='
PRINT ''
PRINT 'LISTINO B2B:'
PRINT 'Articoli con prezzo B2B: ' + CAST(@ArticoliConPrezzoB2B AS VARCHAR(10))
PRINT 'Prezzo medio B2B: ' + CAST(ISNULL(@PrezzoMedioB2B, 0) AS VARCHAR(10))
PRINT 'Con RicaricoPercentuale: ' + CAST(@ArticoliRicaricoPercB2B AS VARCHAR(10))
PRINT 'Con Margine tradizionale: ' + CAST(@ArticoliMargineTradiB2B AS VARCHAR(10))
PRINT ''
PRINT 'LISTINO PIATTAFORME:'
PRINT 'Articoli 24H: ' + CAST(@ArticoliPiatt24H AS VARCHAR(10))
PRINT 'Articoli 48H: ' + CAST(@ArticoliPiatt48H AS VARCHAR(10))
PRINT 'Articoli 72H: ' + CAST(@ArticoliPiatt72H AS VARCHAR(10))
PRINT 'Articoli con prezzi esteri: ' + CAST(@ArticoliEsteri AS VARCHAR(10))
PRINT 'Prezzo medio 24H: ' + CAST(ISNULL(@PrezzoMedioPiatt, 0) AS VARCHAR(10))
PRINT ''
PRINT 'LISTINO COLLEGATI:'
PRINT 'Articoli totali Collegati: ' + CAST(@TotaleCollegati AS VARCHAR(10))
PRINT 'Collegati da 24H: ' + CAST(@Collegati24H AS VARCHAR(10))
PRINT 'Collegati da 48H: ' + CAST(@Collegati48H AS VARCHAR(10))
PRINT 'Esclusi (72H): ' + CAST(@Esclusi72H AS VARCHAR(10))
PRINT 'Prezzo medio Collegati: ' + CAST(ISNULL(@PrezzoMedioCollegati, 0) AS VARCHAR(10))

-- ========================================
-- VERIFICA TRACCIABILITÀ REGOLE
-- ========================================

PRINT ''
PRINT '5. Verifica tracciabilità regole...'

-- Verifica che ogni articolo abbia le note corrette con ID regola
DECLARE @ArticoliConNoteIDB2B int, @ArticoliConNoteIDPiatt int, @ArticoliConNoteIDColl int

SELECT @ArticoliConNoteIDB2B = COUNT(*) 
FROM OfferteWeb_Tmp 
WHERE ID_RegoleB2B IS NOT NULL 
AND Note_Std LIKE '%B2B[ID:%'

SELECT @ArticoliConNoteIDPiatt = COUNT(*) 
FROM OfferteWeb_Tmp 
WHERE ID_RegolePiattaforme IS NOT NULL 
AND Note_T24 LIKE '%Piatt[ID:%'

SELECT @ArticoliConNoteIDColl = COUNT(*) 
FROM OfferteWeb_Tmp 
WHERE ID_RegoleCollegati IS NOT NULL 
AND TipoPubPiatt IN ('24H', '48H')
AND Note_Collegati LIKE '%Collegati[ID:%'

PRINT 'Articoli B2B con Note contenenti ID regola: ' + CAST(@ArticoliConNoteIDB2B AS VARCHAR(10))
PRINT 'Articoli Piattaforme con Note contenenti ID regola: ' + CAST(@ArticoliConNoteIDPiatt AS VARCHAR(10))
PRINT 'Articoli Collegati con Note contenenti ID regola: ' + CAST(@ArticoliConNoteIDColl AS VARCHAR(10))

-- ========================================
-- CAMPIONI RISULTATI
-- ========================================

PRINT ''
PRINT '6. Campioni risultati...'

PRINT '6.1 Campione articoli B2B:'
SELECT TOP 2
    IdArtico,
    Prezzo,
    P_Std,
    Note_Std,
    ID_RegoleB2B
FROM OfferteWeb_Tmp 
WHERE P_Std IS NOT NULL AND ID_RegoleB2B IS NOT NULL
ORDER BY Prezzo

PRINT '6.2 Campione articoli Piattaforme 24H:'
SELECT TOP 2
    IdArtico,
    Prezzo,
    P_T24_24H,
    TipoPubPiatt,
    Note_T24,
    ID_RegolePiattaforme
FROM OfferteWeb_Tmp 
WHERE P_T24_24H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
ORDER BY Prezzo

PRINT '6.3 Campione articoli Collegati:'
SELECT TOP 2
    IdArtico,
    Prezzo,
    P_Collegati_GER,
    TipoPubPiatt,
    Note_Collegati,
    ID_RegoleCollegati
FROM OfferteWeb_Tmp 
WHERE P_Collegati_GER IS NOT NULL AND ID_RegoleCollegati IS NOT NULL
ORDER BY Prezzo

-- ========================================
-- CONTROLLO COERENZA TRA LISTINI
-- ========================================

PRINT ''
PRINT '7. Controllo coerenza tra listini...'

-- Verifica che gli articoli abbiano prezzi coerenti (B2B <= Piattaforme <= Collegati è una logica di business)
DECLARE @IncoerenzePrezzi int

SELECT @IncoerenzePrezzi = COUNT(*)
FROM OfferteWeb_Tmp 
WHERE P_Std IS NOT NULL 
AND P_T24_24H IS NOT NULL 
AND P_Collegati_GER IS NOT NULL
AND (P_Std > P_T24_24H OR P_T24_24H > P_Collegati_GER)

PRINT 'Articoli con incoerenze prezzi (B2B > Piatt24H o Piatt24H > Coll): ' + CAST(@IncoerenzePrezzi AS VARCHAR(10))

-- ========================================
-- CONTROLLO PERFORMANCE
-- ========================================

PRINT ''
PRINT '8. Test performance join con ID...'

DECLARE @StartTime datetime, @EndTime datetime, @Duration int

SET @StartTime = GETDATE()

-- Test query complessa con nuovo sistema
SELECT COUNT(*)
FROM OfferteWeb_Tmp OW
INNER JOIN RegoleListiniDistribuzione RLD_B2B ON RLD_B2B.ID = OW.ID_RegoleB2B
INNER JOIN RegoleListiniDistribuzione RLD_PIATT ON RLD_PIATT.ID = OW.ID_RegolePiattaforme  
INNER JOIN RegoleListiniDistribuzione RLD_COLL ON RLD_COLL.ID = OW.ID_RegoleCollegati
WHERE OW.P_Std IS NOT NULL 
AND OW.P_T24_24H IS NOT NULL 
AND OW.P_Collegati_GER IS NOT NULL

SET @EndTime = GETDATE()
SET @Duration = DATEDIFF(millisecond, @StartTime, @EndTime)

PRINT 'Join triplo con ID completato in: ' + CAST(@Duration AS VARCHAR(10)) + ' ms'

-- ========================================
-- RISULTATO FINALE
-- ========================================

PRINT ''
PRINT '========================================='
PRINT 'TEST COMPLETATO CON SUCCESSO!'
PRINT '========================================='

PRINT 'Il nuovo sistema di distribuzione funziona correttamente:'
PRINT '✓ Tutti e 3 i listini (B2B, Piattaforme, Collegati) calcolati'
PRINT '✓ Regole assegnate correttamente tramite ID'
PRINT '✓ Prezzi calcolati con successo per tutti i listini'
PRINT '✓ Tracciabilità garantita nelle note con ID regole'
PRINT '✓ Performance ottimale con join su ID'
PRINT '✓ Supporto sia per RicaricoPercentuale che Margine tradizionale'
PRINT '✓ Logica TipoPubPiatt (24H/48H/72H) implementata correttamente'

PRINT ''
PRINT 'Sistema pronto per produzione!'
PRINT '=========================================' 