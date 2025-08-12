-- =============================================
-- QUERY VELOCI PER GESTIONE REGOLE DISTRIBUZIONE
-- Copia e incolla queste query in SQL Management Studio
-- =============================================

-- ========================================
-- 📋 CONSULTAZIONE CON FILTRI EXCEL-LIKE
-- ========================================

-- Visualizza tutte le regole con filtri (modifica WHERE per filtrare)
SELECT 
    ID,
    NomeListino,
    CONCAT(CifraIn, ' - ', CifraOut, ' €') AS FasciaPrezzo,
    CONCAT(Margine, ' €') AS Margine,
    Settore,
    CASE 
        WHEN RicaricoPercentuale IS NOT NULL 
        THEN CONCAT(ROUND((RicaricoPercentuale - 1) * 100, 1), '%')
        ELSE 'Margine Fisso'
    END AS TipoCalcolo,
    ProvvPiatt,
    FORMAT(DataModifica, 'dd/MM/yyyy HH:mm') AS UltimaModifica
FROM RegoleListiniDistribuzione
WHERE 1=1
-- ⬇️ DECOMMENTA E MODIFICA I FILTRI CHE TI SERVONO ⬇️
    -- AND NomeListino = 'B2B'                    -- Solo B2B
    -- AND Settore = 'Vettura'                     -- Solo Vettura  
    -- AND CifraIn >= 100 AND CifraOut <= 200      -- Fascia 100-200€
    -- AND Margine > 15                            -- Margine > 15€
    -- AND RicaricoPercentuale IS NOT NULL         -- Solo con ricarico %
    -- AND DataModifica >= '2025-01-01'            -- Modificate da gennaio
ORDER BY NomeListino, Settore, CifraIn;

-- ========================================
-- ⚡ MODIFICHE RAPIDE MULTIPLE
-- ========================================

-- 🔧 Aumenta tutti i margini B2B Vettura del 10%
UPDATE RegoleListiniDistribuzione 
SET Margine = ROUND(Margine * 1.10, 2),
    DataModifica = GETDATE()
WHERE NomeListino = 'B2B' AND Settore = 'Vettura';

-- 🔧 Imposta ricarico 25% per fascia 200-300€ tutte le piattaforme
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = 1.25,
    DataModifica = GETDATE()
WHERE NomeListino = 'Piattaforme' 
AND CifraIn >= 200 AND CifraOut <= 300;

-- 🔧 Azzera margini stagionali per autocarri
UPDATE RegoleListiniDistribuzione 
SET MargMenoEstivo = NULL,
    MargMenoAS = NULL,
    MargMenoInvernale = NULL,
    DataModifica = GETDATE()
WHERE Settore = 'Autocarro';

-- ========================================
-- 📊 REPORT E ANALISI VELOCI
-- ========================================

-- 📈 Confronto margini medi per listino/settore
SELECT 
    NomeListino,
    Settore,
    COUNT(*) AS NumRegole,
    ROUND(AVG(Margine), 2) AS MargineMediaEuro,
    ROUND(MIN(Margine), 2) AS MargineMinimo,
    ROUND(MAX(Margine), 2) AS MargineMassimo
FROM RegoleListiniDistribuzione
GROUP BY NomeListino, Settore
ORDER BY NomeListino, Settore;

-- 📈 Fasce di prezzo più usate
SELECT 
    CONCAT(CifraIn, ' - ', CifraOut, ' €') AS FasciaPrezzo,
    COUNT(*) AS Utilizzi,
    STRING_AGG(CONCAT(NomeListino, ' (', Settore, ')'), ', ') AS Listini
FROM RegoleListiniDistribuzione
GROUP BY CifraIn, CifraOut
HAVING COUNT(*) > 1  -- Solo fasce usate per più listini
ORDER BY COUNT(*) DESC;

-- 📈 Regole con potenziali sovrapposizioni (da verificare)
SELECT 
    r1.ID AS ID1,
    r1.NomeListino AS Listino1,
    r1.Settore,
    CONCAT(r1.CifraIn, '-', r1.CifraOut) AS Fascia1,
    r2.ID AS ID2,
    CONCAT(r2.CifraIn, '-', r2.CifraOut) AS Fascia2,
    'SOVRAPPOSIZIONE!' AS Problema
FROM RegoleListiniDistribuzione r1
JOIN RegoleListiniDistribuzione r2 ON 
    r1.NomeListino = r2.NomeListino 
    AND r1.Settore = r2.Settore
    AND r1.ID < r2.ID
WHERE 
    (r1.CifraIn < r2.CifraOut AND r1.CifraOut > r2.CifraIn);

-- ========================================
-- 🔄 OPERAZIONI DI MANUTENZIONE
-- ========================================

-- 🔍 Trova gaps nelle fasce di prezzo
WITH FasceOrdinate AS (
    SELECT 
        NomeListino,
        Settore,
        CifraOut,
        LEAD(CifraIn) OVER (PARTITION BY NomeListino, Settore ORDER BY CifraIn) AS ProssimaCifraIn
    FROM RegoleListiniDistribuzione
)
SELECT 
    NomeListino,
    Settore,
    CONCAT(CifraOut + 0.01, ' - ', ProssimaCifraIn - 0.01, ' €') AS FasciaVuota,
    'GAP!' AS Problema
FROM FasceOrdinate
WHERE ProssimaCifraIn IS NOT NULL 
AND CifraOut + 0.01 < ProssimaCifraIn
ORDER BY NomeListino, Settore, CifraOut;

-- 🧹 Pulisci regole duplicate (ATTENZIONE: esegui prima la query sopra per vedere cosa elimineresti)
-- DELETE r1 FROM RegoleListiniDistribuzione r1
-- JOIN RegoleListiniDistribuzione r2 ON 
--     r1.NomeListino = r2.NomeListino 
--     AND r1.Settore = r2.Settore
--     AND r1.CifraIn = r2.CifraIn
--     AND r1.CifraOut = r2.CifraOut
--     AND r1.ID > r2.ID;

-- ========================================
-- 💾 EXPORT VELOCE PER EXCEL
-- ========================================

-- 📤 Export in formato Excel-ready (copia risultato e incolla in Excel)
SELECT 
    ID,
    NomeListino,
    CifraIn,
    CifraOut,
    Margine,
    ISNULL(MargPiu, 0) AS MargPiu,
    ISNULL(MargMeno, 0) AS MargMeno,
    Settore,
    ISNULL(RicaricoPercentuale, 0) AS RicaricoPercentuale,
    ProvvPiatt,
    ISNULL(MargMenoEstivo, 0) AS MargMenoEstivo,
    ISNULL(MargMenoAS, 0) AS MargMenoAS,
    ISNULL(MargMenoInvernale, 0) AS MargMenoInvernale,
    FORMAT(DataCreazione, 'dd/MM/yyyy HH:mm') AS DataCreazione,
    FORMAT(DataModifica, 'dd/MM/yyyy HH:mm') AS DataModifica
FROM RegoleListiniDistribuzione
ORDER BY NomeListino, Settore, CifraIn;

-- ========================================
-- 🎯 TEMPLATE PER INSERIMENTI RAPIDI
-- ========================================

-- 📝 Template per aggiungere nuove fasce (modifica i valori)
INSERT INTO RegoleListiniDistribuzione (
    NomeListino, CifraIn, CifraOut, Margine, Settore, 
    ProvvPiatt, CostoTrasportoIt, TipoListForn
) VALUES 
('B2B', 350.00, 400.00, 40.00, 'Vettura', 1.0000, 4.40, '24H'),
('Piattaforme', 350.00, 400.00, 40.00, 'Vettura', 1.0130, 4.40, '24H'),
('Collegati', 350.00, 400.00, 40.00, 'Vettura', 1.0000, 4.40, '24H');

-- ========================================
-- ⚙️ CREAZIONE LISTINO COPIANDO DA ESISTENTE
-- ========================================

-- 🔄 Copia tutte le regole B2B per creare nuovo listino "TestB2B"
INSERT INTO RegoleListiniDistribuzione (
    NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore,
    RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, MargMenoAS, MargMenoInvernale,
    CostoTrasportoIt, TipoListForn
)
SELECT 
    'TestB2B' AS NomeListino,  -- ⬅️ Cambia qui il nome del nuovo listino
    CifraIn, CifraOut, 
    Margine * 1.10 AS Margine,  -- ⬅️ Aumenta margini del 10%
    MargPiu, MargMeno, Settore,
    RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, MargMenoAS, MargMenoInvernale,
    CostoTrasportoIt, TipoListForn
FROM RegoleListiniDistribuzione
WHERE NomeListino = 'B2B';  -- ⬅️ Listino da copiare

-- ========================================
-- 🚨 QUERY DI SICUREZZA E VALIDAZIONE
-- ========================================

-- ⚠️ Controlla regole potenzialmente problematiche
SELECT 
    'MARGINE TROPPO BASSO' AS Problema,
    ID, NomeListino, Settore, 
    CONCAT(CifraIn, '-', CifraOut, ' €') AS Fascia,
    CONCAT(Margine, ' €') AS MargineAttuale
FROM RegoleListiniDistribuzione
WHERE Margine < 3.00 AND Settore != 'Autocarro'

UNION ALL

SELECT 
    'FASCIA PREZZO SOSPETTA' AS Problema,
    ID, NomeListino, Settore,
    CONCAT(CifraIn, '-', CifraOut, ' €') AS Fascia,
    CONCAT(CifraOut - CifraIn, ' € ampiezza') AS MargineAttuale
FROM RegoleListiniDistribuzione
WHERE (CifraOut - CifraIn) > 100  -- Fasce troppo ampie

UNION ALL

SELECT 
    'RICARICO PERCENTUALE SOSPETTO' AS Problema,
    ID, NomeListino, Settore,
    CONCAT(CifraIn, '-', CifraOut, ' €') AS Fascia,
    CONCAT(ROUND((RicaricoPercentuale - 1) * 100, 1), '%') AS MargineAttuale
FROM RegoleListiniDistribuzione
WHERE RicaricoPercentuale > 2.0 OR RicaricoPercentuale < 1.01

ORDER BY Problema, NomeListino, Settore;

-- ========================================
-- 💡 QUERY UTILITIES
-- ========================================

-- 📊 Ultimo backup disponibile
SELECT 
    TABLE_NAME AS NomeBackup,
    SUBSTRING(TABLE_NAME, 26, LEN(TABLE_NAME)) AS DataBackup
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_NAME LIKE 'RegoleListiniDistribuzione_Backup_%'
ORDER BY TABLE_NAME DESC;

-- 🔄 Ripristina da backup (ATTENZIONE!)
-- TRUNCATE TABLE RegoleListiniDistribuzione;
-- INSERT INTO RegoleListiniDistribuzione SELECT * FROM [RegoleListiniDistribuzione_Backup_YYYYMMDD_HHMMSS];

-- 📈 Performance: quante regole sono attivamente utilizzate
SELECT 
    'UTILIZZO REGOLE' AS Statistica,
    r.NomeListino,
    COUNT(DISTINCT r.ID) AS RegoleTotali,
    COUNT(DISTINCT o.ID_RegoleB2B) + COUNT(DISTINCT o.ID_RegolePiattaforme) + COUNT(DISTINCT o.ID_RegoleCollegati) AS RegoleInUso,
    ROUND(
        (COUNT(DISTINCT o.ID_RegoleB2B) + COUNT(DISTINCT o.ID_RegolePiattaforme) + COUNT(DISTINCT o.ID_RegoleCollegati)) * 100.0 / COUNT(DISTINCT r.ID), 
        1
    ) AS PercentualeUso
FROM RegoleListiniDistribuzione r
LEFT JOIN OfferteWeb_Tmp o ON r.ID IN (o.ID_RegoleB2B, o.ID_RegolePiattaforme, o.ID_RegoleCollegati)
GROUP BY r.NomeListino
ORDER BY PercentualeUso DESC;