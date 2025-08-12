-- =====================================================
-- Script per Analisi Fornitori e Marche
-- Raggruppa per fornitore (CodMagForn) e marca (Produttore)
-- Conta gli articoli univoci (CodArtPiatt) per ogni combinazione
-- =====================================================

-- Query principale: raggruppa per fornitore e marca
SELECT 
    CodMagForn AS [Codice Fornitore],
    Produttore AS [Marca],
    COUNT(DISTINCT CodArtPiatt) AS [Numero Articoli Univoci]
FROM OfferteWeb
WHERE CodMagForn IS NOT NULL 
    AND CodMagForn <> '' 
    AND Produttore IS NOT NULL 
    AND Produttore <> ''
    AND CodArtPiatt IS NOT NULL 
    AND CodArtPiatt <> ''
GROUP BY CodMagForn, Produttore
ORDER BY CodMagForn, Produttore;

-- =====================================================
-- Query alternativa: raggruppa solo per fornitore 
-- con dettaglio delle marche e totali
-- =====================================================

SELECT 
    CodMagForn AS [Codice Fornitore],
    COUNT(DISTINCT Produttore) AS [Numero Marche Totali],
    COUNT(DISTINCT CodArtPiatt) AS [Numero Articoli Totali],
    STUFF((
        SELECT DISTINCT ', ' + Produttore
        FROM OfferteWeb o2
        WHERE o2.CodMagForn = o1.CodMagForn
            AND o2.Produttore IS NOT NULL 
            AND o2.Produttore <> ''
        FOR XML PATH('')
    ), 1, 2, '') AS [Elenco Marche]
FROM OfferteWeb o1
WHERE CodMagForn IS NOT NULL 
    AND CodMagForn <> '' 
    AND Produttore IS NOT NULL 
    AND Produttore <> ''
    AND CodArtPiatt IS NOT NULL 
    AND CodArtPiatt <> ''
GROUP BY CodMagForn
ORDER BY CodMagForn;

-- =====================================================
-- Query dettagliata: vista completa con tutte le info
-- =====================================================

WITH FornitoriMarche AS (
    SELECT 
        CodMagForn,
        Produttore,
        COUNT(DISTINCT CodArtPiatt) AS ArticoliUnivoci
    FROM OfferteWeb
    WHERE CodMagForn IS NOT NULL 
        AND CodMagForn <> '' 
        AND Produttore IS NOT NULL 
        AND Produttore <> ''
        AND CodArtPiatt IS NOT NULL 
        AND CodArtPiatt <> ''
    GROUP BY CodMagForn, Produttore
),
TotaliFornitori AS (
    SELECT 
        CodMagForn,
        COUNT(*) AS NumeroMarche,
        SUM(ArticoliUnivoci) AS TotaleArticoli
    FROM FornitoriMarche
    GROUP BY CodMagForn
)

SELECT 
    fm.CodMagForn AS [Codice Fornitore],
    tf.NumeroMarche AS [Numero Marche],
    tf.TotaleArticoli AS [Totale Articoli],
    fm.Produttore AS [Marca],
    fm.ArticoliUnivoci AS [Articoli per Marca]
FROM FornitoriMarche fm
INNER JOIN TotaliFornitori tf ON fm.CodMagForn = tf.CodMagForn
ORDER BY fm.CodMagForn, fm.ArticoliUnivoci DESC, fm.Produttore;

-- =====================================================
-- Query per esportazione CSV
-- Formato semplice per eventuali report
-- =====================================================

SELECT 
    CodMagForn + '|' + Produttore + '|' + CAST(COUNT(DISTINCT CodArtPiatt) AS VARCHAR(10)) AS [Fornitore_Marca_Articoli]
FROM OfferteWeb
WHERE CodMagForn IS NOT NULL 
    AND CodMagForn <> '' 
    AND Produttore IS NOT NULL 
    AND Produttore <> ''
    AND CodArtPiatt IS NOT NULL 
    AND CodArtPiatt <> ''
GROUP BY CodMagForn, Produttore
ORDER BY CodMagForn, Produttore; 