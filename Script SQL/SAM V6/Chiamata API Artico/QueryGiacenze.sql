-- QUERY RAPIDE GIACENZE DA CACHE LOCALE
-- Usa questo script per interrogazioni veloci dopo la sincronizzazione

DECLARE @IdArticolo INT = 512534;  -- ⬅️ CAMBIA QUI L'ID ARTICOLO

-- === VERIFICA CACHE ===
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CacheGiacenze]') AND type in (N'U'))
BEGIN
    PRINT '❌ ERRORE: Tabella CacheGiacenze non esiste!';
    PRINT '👉 Esegui prima SincronizzaGiacenze.sql';
    RETURN;
END

DECLARE @TotalRecords INT = (SELECT COUNT(*) FROM CacheGiacenze);
DECLARE @LastUpdate DATETIME = (SELECT MAX(LastUpdate) FROM CacheGiacenze);

PRINT '=== QUERY GIACENZE ARTICOLO: ' + CAST(@IdArticolo as NVARCHAR) + ' ===';
PRINT 'Record in cache: ' + CAST(@TotalRecords as NVARCHAR);
PRINT 'Ultimo aggiornamento: ' + ISNULL(CONVERT(NVARCHAR, @LastUpdate, 120), 'N/A');
PRINT '';

-- === GIACENZE PER ARTICOLO SPECIFICO ===
PRINT '🎯 GIACENZE DETTAGLIATE:';
SELECT 
    idartico as 'ID Articolo',
    idmag as 'ID Magazzino', 
    qttgiai as 'Qta Giacenza',
    qttimpi as 'Qta Impegnata',
    (qttgiai - qttimpi) as 'Qta Disponibile',
    qttgiam as 'Giacenza Min',
    qttmani as 'Qta Manuale',
    qttspei as 'Qta Spedizione',
    qttordi as 'Qta Ordinata'
FROM CacheGiacenze 
WHERE idartico = @IdArticolo
ORDER BY idmag;

-- === RIEPILOGO ARTICOLO ===
PRINT '';
PRINT '📊 RIEPILOGO TOTALE:';
SELECT 
    @IdArticolo as 'ID Articolo',
    COUNT(*) as 'Num Magazzini',
    SUM(qttgiai) as 'Totale Giacenza',
    SUM(qttimpi) as 'Totale Impegnata', 
    SUM(qttgiai - qttimpi) as 'Totale Disponibile',
    MIN(CASE WHEN qttgiai > 0 THEN idmag END) as 'Primo Mag con Stock',
    MAX(qttgiai) as 'Max Qta Singolo Mag'
FROM CacheGiacenze 
WHERE idartico = @IdArticolo;

-- === MAGAZZINI CON DISPONIBILITÀ ===
PRINT '';
PRINT '✅ MAGAZZINI CON DISPONIBILITÀ:';
SELECT 
    idmag as 'ID Magazzino',
    qttgiai as 'Giacenza',
    qttimpi as 'Impegnata', 
    (qttgiai - qttimpi) as 'Disponibile'
FROM CacheGiacenze 
WHERE idartico = @IdArticolo 
    AND (qttgiai - qttimpi) > 0
ORDER BY (qttgiai - qttimpi) DESC;

-- === CONTROLLO CACHE AGGIORNATA ===
DECLARE @CacheAge INT = DATEDIFF(hour, @LastUpdate, GETDATE());
IF @CacheAge > 24
BEGIN
    PRINT '';
    PRINT '⚠️  ATTENZIONE: Cache vecchia di ' + CAST(@CacheAge as NVARCHAR) + ' ore';
    PRINT '👉 Considera di rieseguire SincronizzaGiacenze.sql';
END

-- === QUERY PERSONALIZZABILI ===
/*
-- 🔍 ESEMPI DI QUERY UTILI:

-- Trova articoli con poca giacenza
SELECT idartico, SUM(qttgiai) as TotGiacenza
FROM CacheGiacenze 
GROUP BY idartico
HAVING SUM(qttgiai) < 100
ORDER BY TotGiacenza;

-- Articoli per magazzino specifico
SELECT idartico, qttgiai, qttimpi, (qttgiai-qttimpi) as Disponibile
FROM CacheGiacenze 
WHERE idmag = 13739  -- Cambia ID magazzino
    AND qttgiai > 0
ORDER BY qttgiai DESC;

-- Top 10 articoli per giacenza
SELECT TOP 10 idartico, SUM(qttgiai) as TotaleGiacenza
FROM CacheGiacenze 
GROUP BY idartico
ORDER BY TotaleGiacenza DESC;

-- Cerca articoli con giacenza in magazzino specifico
SELECT * FROM CacheGiacenze 
WHERE idmag = 13739 
    AND qttgiai > 0 
    AND idartico LIKE '%512%';  -- Pattern ricerca
*/ 