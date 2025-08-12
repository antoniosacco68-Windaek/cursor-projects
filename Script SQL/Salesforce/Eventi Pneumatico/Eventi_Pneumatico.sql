-- ==============================================================================
-- EVENTI PNEUMATICO - VERSIONE ALLINEATA ALL'ANAGRAFICA "Pneumatico SalesForce.sql"
-- - Usa ESATTAMENTE la stessa logica di anagrafica (External_Id__c con IdScheda)
-- - Gestisce ANTERIORI e POSTERIORI
-- - Smontaggi/Depositi: data evento da Deposito.Data (mai D_ModificatoData)
-- - Matching su CodiceArticolo COMPLETO (nessun LEFT)
-- - Evita duplicati con DISTINCT e chiavi stabili
-- ==============================================================================

WITH AnagraficaPneumaticiCompleta AS (
    -- PNEUMATICI MONTATI (STESSA LOGICA DELL'ANAGRAFICA, CON IdScheda PER JOIN)
    SELECT 
        sl.S_IdVeicolo AS IdVeicolo,
        asl.Art_Codice AS CodiceArticolo,
        dw.ART_ID AS IdArticolo,
        COALESCE(
            NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT, ''))), ''),
            FORMAT(DATEPART(week, DATEADD(day, -90, sl.Data_Lavori)), '00') + FORMAT(sl.Data_Lavori, 'yy')
        ) AS DOT__c,
        CAST(
            sl.S_IdVeicolo AS VARCHAR(10)) + '_' + 
            CAST(dw.ART_ID AS VARCHAR(10)) + '_' + 
            COALESCE(
                NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT, ''))), ''),
                FORMAT(DATEPART(week, DATEADD(day, -90, sl.Data_Lavori)), '00') + FORMAT(sl.Data_Lavori, 'yy')
            ) + '_' + CAST(sl.IdSchedaLavoro AS VARCHAR(10))
        AS External_Id__c,
        'NEWLY_MOUNTED' AS TipoPneumatico,
        sl.IdSchedaLavoro AS Fonte_SchedaLavoro,
        sl.Data_Lavori AS Fonte_DataLavori
    FROM SchedaLavoro sl
    INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro  
    INNER JOIN Ant_Descrittori_WebSmall dw ON asl.Art_Codice = dw.ART_CODICE
    WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
      AND asl.Art_Fascia IN ('A','B','C','U','R')
      
    UNION ALL
    
    -- PNEUMATICI SOLO DEPOSITO (ANTERIORI)
    SELECT 
        primo_deposito.D_IdVeicolo, primo_deposito.D_ArtCodice, dw.ART_ID,
        COALESCE(
            NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito.D_DotAnt, ''))), ''),
            FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo.Data_Lavori)), '00') + FORMAT(sl_primo.Data_Lavori, 'yy')
        ) AS DOT__c,
        CAST(primo_deposito.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' + 
            COALESCE(
                NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito.D_DotAnt, ''))), ''),
                FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo.Data_Lavori)), '00') + FORMAT(sl_primo.Data_Lavori, 'yy')
            ) + '_' + CAST(primo_deposito.D_IdSchedaLavoro AS VARCHAR(10)) AS External_Id__c,
        'SOLO_DEPOSITO' AS TipoPneumatico,
        primo_deposito.D_IdSchedaLavoro AS Fonte_SchedaLavoro,
        sl_primo.Data_Lavori AS Fonte_DataLavori
    FROM (
        SELECT d.D_IdVeicolo, d.D_ArtCodice, d.D_DotAnt, d.D_IdSchedaLavoro,
            ROW_NUMBER() OVER(PARTITION BY d.D_IdVeicolo, d.D_ArtCodice ORDER BY sl.Data_Lavori ASC) AS RankDeposito
        FROM Deposito d
        INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
        WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId) AND d.D_IdSchedaLavoro > 0 AND d.D_ArtCodice IS NOT NULL
    ) primo_deposito
    INNER JOIN SchedaLavoro sl_primo ON sl_primo.IdSchedaLavoro = primo_deposito.D_IdSchedaLavoro
    INNER JOIN Ant_Descrittori_WebSmall dw ON primo_deposito.D_ArtCodice = dw.ART_CODICE
    WHERE primo_deposito.RankDeposito = 1
      AND NOT EXISTS (
          SELECT 1 FROM SchedaLavoro sl_check
          INNER JOIN ArtSchedaLavoro asl_check ON asl_check.Art_IdSchedaLavoro = sl_check.IdSchedaLavoro
          WHERE sl_check.S_IdVeicolo = primo_deposito.D_IdVeicolo AND asl_check.Art_Codice = primo_deposito.D_ArtCodice
            AND asl_check.Art_Fascia IN ('A','B','C','U','R')
            AND sl_check.Data_Lavori < sl_primo.Data_Lavori  -- Solo schede PRECEDENTI al deposito
      )
      
    UNION ALL
    
    -- PNEUMATICI SOLO DEPOSITO (POSTERIORI)
    SELECT 
        primo_deposito_post.D_IdVeicolo, primo_deposito_post.D_ArtCodicePost, dw_post.ART_ID,
        COALESCE(
            NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito_post.D_DotPost, ''))), ''),
            FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo_post.Data_Lavori)), '00') + FORMAT(sl_primo_post.Data_Lavori, 'yy')
        ) AS DOT__c,
        CAST(primo_deposito_post.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw_post.ART_ID AS VARCHAR(10)) + '_' + 
            COALESCE(
                NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito_post.D_DotPost, ''))), ''),
                FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo_post.Data_Lavori)), '00') + FORMAT(sl_primo_post.Data_Lavori, 'yy')
            ) + '_' + CAST(primo_deposito_post.D_IdSchedaLavoro AS VARCHAR(10)) AS External_Id__c,
        'SOLO_DEPOSITO_POST' AS TipoPneumatico,
        primo_deposito_post.D_IdSchedaLavoro AS Fonte_SchedaLavoro,
        sl_primo_post.Data_Lavori AS Fonte_DataLavori
    FROM (
        SELECT d.D_IdVeicolo, d.D_ArtCodicePost, d.D_DotPost, d.D_IdSchedaLavoro,
            ROW_NUMBER() OVER(PARTITION BY d.D_IdVeicolo, d.D_ArtCodicePost ORDER BY sl.Data_Lavori ASC) AS RankDeposito
        FROM Deposito d
        INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
        WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId) AND d.D_IdSchedaLavoro > 0 AND d.D_ArtCodicePost IS NOT NULL
    ) primo_deposito_post
    INNER JOIN SchedaLavoro sl_primo_post ON sl_primo_post.IdSchedaLavoro = primo_deposito_post.D_IdSchedaLavoro
    INNER JOIN Ant_Descrittori_WebSmall dw_post ON primo_deposito_post.D_ArtCodicePost = dw_post.ART_CODICE
    WHERE primo_deposito_post.RankDeposito = 1
      AND NOT EXISTS (
          SELECT 1 FROM SchedaLavoro sl_check
          INNER JOIN ArtSchedaLavoro asl_check ON asl_check.Art_IdSchedaLavoro = sl_check.IdSchedaLavoro
          WHERE sl_check.S_IdVeicolo = primo_deposito_post.D_IdVeicolo AND asl_check.Art_Codice = primo_deposito_post.D_ArtCodicePost
            AND asl_check.Art_Fascia IN ('A','B','C','U','R')
            AND sl_check.Data_Lavori < sl_primo_post.Data_Lavori  -- Solo schede PRECEDENTI al deposito
      )
),

-- LINEA TEMPORALE per trovare rimontaggi e legare smontaggi
CronologiaLineare AS (
    SELECT 
        ascl.Id_Articoli,
        sl.IdSchedaLavoro,
        sl.Km,
        sl.Data_Lavori,
        ascl.Art_Qta,
        v.IdVeicolo,
        ascl.Art_Codice,
        ascl.Art_Fascia,
        d.IdDeposito,
        d.D_ArtCodice,
        d.D_ArtCodicePost,
        d.D_TipoDepositoR1,
        d.D_TipoDepositoR2,
        d.Data AS DataDeposito,
        d.D_DotAnt,
        d.D_DotPost,
        ROW_NUMBER() OVER(PARTITION BY v.IdVeicolo ORDER BY sl.Data_Lavori, sl.IdSchedaLavoro) AS NumeroRiga
    FROM Veicolo v (NOLOCK)
    INNER JOIN SchedaLavoro sl (NOLOCK) ON v.IdVeicolo = sl.S_IdVeicolo
    LEFT JOIN Deposito d (NOLOCK) ON d.D_IdSchedaLavoro = sl.IdSchedaLavoro AND sl.S_IdVeicolo = d.D_IdVeicolo
    LEFT JOIN ArtSchedaLavoro ascl (NOLOCK) ON sl.IdSchedaLavoro = ascl.Art_IdSchedaLavoro
    WHERE ascl.Art_Qta > 0 
      AND (ascl.Art_Fascia IN ('A', 'B', 'C', 'U') OR ascl.Art_Codice LIKE '%MS_STAG%' OR ascl.Art_Codice LIKE '%MSNUOVO%')
      AND v.IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
),

EventiSequenziali AS (
    SELECT 
        cl.IdVeicolo, cl.Data_Lavori, cl.Km, cl.IdSchedaLavoro, cl.Id_Articoli, cl.NumeroRiga,
        CASE WHEN cl.Art_Fascia IN ('A','B','C','U','R') THEN cl.Art_Codice ELSE NULL END AS PneumaticoMontato,
        CASE WHEN cl.D_ArtCodice IS NOT NULL THEN cl.D_ArtCodice ELSE NULL END AS PneumaticoSmontato,
        CASE WHEN cl.D_ArtCodicePost IS NOT NULL THEN cl.D_ArtCodicePost ELSE NULL END AS PneumaticoSmontatoPost,
        CASE WHEN cl.Art_Codice LIKE '%MS_STAG%' THEN 1 ELSE 0 END AS ServizioStagionale,
        cl.D_TipoDepositoR1, cl.D_TipoDepositoR2,
        cl.DataDeposito,
        -- DOT calcolati per disambiguare correttamente lo smontaggio
        COALESCE(NULLIF(cl.D_DotAnt, ''), FORMAT(DATEPART(week, DATEADD(day, -90, cl.DataDeposito)), '00') + FORMAT(cl.DataDeposito, 'yy')) AS DotAntCalcolato,
        COALESCE(NULLIF(cl.D_DotPost, ''), FORMAT(DATEPART(week, DATEADD(day, -90, cl.DataDeposito)), '00') + FORMAT(cl.DataDeposito, 'yy')) AS DotPostCalcolato,
        CASE WHEN NULLIF(cl.D_DotAnt,'') IS NULL THEN 0 ELSE 1 END AS HaDotAnt,
        CASE WHEN NULLIF(cl.D_DotPost,'') IS NULL THEN 0 ELSE 1 END AS HaDotPost,
        LAG(CASE WHEN cl.D_ArtCodice IS NOT NULL THEN cl.D_ArtCodice ELSE NULL END, 1) 
            OVER(PARTITION BY cl.IdVeicolo ORDER BY cl.Data_Lavori, cl.IdSchedaLavoro) AS UltimoPneumaticoInDeposito,
        LAG(CASE WHEN cl.D_ArtCodicePost IS NOT NULL THEN cl.D_ArtCodicePost ELSE NULL END, 1) 
            OVER(PARTITION BY cl.IdVeicolo ORDER BY cl.Data_Lavori, cl.IdSchedaLavoro) AS UltimoPneumaticoInDepositoPost
    FROM CronologiaLineare cl
),

-- Abbina smontaggi con logica FIFO (prima anagrafica vista = prima a essere smontata)
AnagraficheAnterioriFIFO AS (
    SELECT 
        ap.IdVeicolo,
        ap.CodiceArticolo,
        ap.External_Id__c,
        ap.Fonte_DataLavori,
        ROW_NUMBER() OVER(
            PARTITION BY ap.IdVeicolo, ap.CodiceArticolo 
            ORDER BY ap.Fonte_DataLavori ASC, ap.Fonte_SchedaLavoro ASC
        ) AS RN_Ana
    FROM AnagraficaPneumaticiCompleta ap
    WHERE ap.TipoPneumatico IN ('NEWLY_MOUNTED','SOLO_DEPOSITO')
),

SmontaggiAnterioriFIFO AS (
    SELECT 
        d.D_IdVeicolo AS IdVeicolo,
        d.D_ArtCodice AS CodiceArticolo,
        d.Data AS DataDeposito,
        sl.IdSchedaLavoro,
        sl.Km,
        d.D_TipoDepositoR1 AS TipoDeposito,
        ROW_NUMBER() OVER(
            PARTITION BY d.D_IdVeicolo, d.D_ArtCodice 
            ORDER BY d.Data ASC, sl.IdSchedaLavoro ASC
        ) AS RN_Smont
    FROM Deposito d
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    WHERE d.D_ArtCodice IS NOT NULL AND d.D_IdSchedaLavoro > 0
      AND d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
),

AnagrafichePosterioriFIFO AS (
    SELECT 
        ap.IdVeicolo,
        ap.CodiceArticolo,
        ap.External_Id__c,
        ap.Fonte_DataLavori,
        ROW_NUMBER() OVER(
            PARTITION BY ap.IdVeicolo, ap.CodiceArticolo 
            ORDER BY ap.Fonte_DataLavori ASC, ap.Fonte_SchedaLavoro ASC
        ) AS RN_Ana
    FROM AnagraficaPneumaticiCompleta ap
    WHERE ap.TipoPneumatico IN ('NEWLY_MOUNTED','SOLO_DEPOSITO_POST')
),

SmontaggiPosterioriFIFO AS (
    SELECT 
        d.D_IdVeicolo AS IdVeicolo,
        d.D_ArtCodicePost AS CodiceArticolo,
        d.Data AS DataDeposito,
        sl.IdSchedaLavoro,
        sl.Km,
        d.D_TipoDepositoR2 AS TipoDeposito,
        ROW_NUMBER() OVER(
            PARTITION BY d.D_IdVeicolo, d.D_ArtCodicePost 
            ORDER BY d.Data ASC, sl.IdSchedaLavoro ASC
        ) AS RN_Smont
    FROM Deposito d
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    WHERE d.D_ArtCodicePost IS NOT NULL AND d.D_IdSchedaLavoro > 0
      AND d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
)

-- ========================= RISULTATO EVENTI =========================
-- 1) MONTAGGI (nuove)
SELECT DISTINCT
    ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ap.External_Id__c + '_MONT_' + FORMAT(sl.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Montaggio' AS Tipo__c,
    sl.Data_Lavori AS Data_evento__c,
    sl.Km AS Km_da_scheda_di_lavoro__c,
    sl.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    es.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    'Montaggio pneumatico' AS Note__c
FROM AnagraficaPneumaticiCompleta ap
INNER JOIN EventiSequenziali es ON es.IdVeicolo = ap.IdVeicolo AND es.PneumaticoMontato = ap.CodiceArticolo AND es.IdSchedaLavoro = ap.Fonte_SchedaLavoro
INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = es.IdSchedaLavoro
WHERE ap.TipoPneumatico = 'NEWLY_MOUNTED'

UNION ALL

-- 2) SMONTAGGI ANTERIORI (data da Deposito.Data)
SELECT DISTINCT
    ana.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ana.External_Id__c + '_SMONT_' + FORMAT(sm.DataDeposito, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Smontaggio' AS Tipo__c,
    sm.DataDeposito AS Data_evento__c,
    sm.Km AS Km_da_scheda_di_lavoro__c,
    sm.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    NULL AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    CASE 
        WHEN sm.TipoDeposito LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale'
        WHEN sm.TipoDeposito LIKE '%finite%' THEN 'Smontaggio per deposito (finite)'
        WHEN sm.TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento'
        WHEN sm.TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente'
        ELSE 'Smontaggio per ' + ISNULL(sm.TipoDeposito, 'deposito')
    END AS Note__c
FROM SmontaggiAnterioriFIFO sm
INNER JOIN AnagraficheAnterioriFIFO ana
    ON ana.IdVeicolo = sm.IdVeicolo
    AND ana.CodiceArticolo = sm.CodiceArticolo
    AND ana.RN_Ana = sm.RN_Smont

UNION ALL

-- 3) SMONTAGGI POSTERIORI (data da Deposito.Data)
SELECT DISTINCT
    ana.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ana.External_Id__c + '_SMONT_' + FORMAT(sm.DataDeposito, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Smontaggio' AS Tipo__c,
    sm.DataDeposito AS Data_evento__c,
    sm.Km AS Km_da_scheda_di_lavoro__c,
    sm.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    NULL AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    CASE 
        WHEN sm.TipoDeposito LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale (posteriore)'
        WHEN sm.TipoDeposito LIKE '%finite%' THEN 'Smontaggio per deposito (finite) (posteriore)'
        WHEN sm.TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento (posteriore)'
        WHEN sm.TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente (posteriore)'
        ELSE 'Smontaggio per ' + ISNULL(sm.TipoDeposito, 'deposito') + ' (posteriore)'
    END AS Note__c
FROM SmontaggiPosterioriFIFO sm
INNER JOIN AnagrafichePosterioriFIFO ana
    ON ana.IdVeicolo = sm.IdVeicolo
    AND ana.CodiceArticolo = sm.CodiceArticolo
    AND ana.RN_Ana = sm.RN_Smont

UNION ALL

-- 4) RIMONTAGGI ANTERIORI (scheda con @MS_STAG)
SELECT DISTINCT
    ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ap.External_Id__c + '_RIMONT_' + FORMAT(es.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Rimontaggio' AS Tipo__c,
    es.Data_Lavori AS Data_evento__c,
    es.Km AS Km_da_scheda_di_lavoro__c,
    es.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    es.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    'Rimontaggio da deposito (cambio stagionale)' AS Note__c
FROM EventiSequenziali es
INNER JOIN AnagraficaPneumaticiCompleta ap ON ap.IdVeicolo = es.IdVeicolo AND ap.CodiceArticolo = es.UltimoPneumaticoInDeposito
WHERE es.ServizioStagionale = 1 AND es.UltimoPneumaticoInDeposito IS NOT NULL

UNION ALL

-- 5) RIMONTAGGI POSTERIORI (scheda con @MS_STAG)
SELECT DISTINCT
    ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ap.External_Id__c + '_RIMONT_' + FORMAT(es.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Rimontaggio' AS Tipo__c,
    es.Data_Lavori AS Data_evento__c,
    es.Km AS Km_da_scheda_di_lavoro__c,
    es.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    es.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    'Rimontaggio da deposito (cambio stagionale posteriore)' AS Note__c
FROM EventiSequenziali es
INNER JOIN AnagraficaPneumaticiCompleta ap ON ap.IdVeicolo = es.IdVeicolo AND ap.CodiceArticolo = es.UltimoPneumaticoInDepositoPost
WHERE es.ServizioStagionale = 1 AND es.UltimoPneumaticoInDepositoPost IS NOT NULL

ORDER BY [Pneumatico__r:Pneumatico__c:External_Id__c], Data_evento__c;


