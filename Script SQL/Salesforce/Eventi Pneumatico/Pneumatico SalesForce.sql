-- ==============================================================================
-- TABELLA PNEUMATICO SALESFORCE - ANAGRAFICA CORRETTA FINALE
-- ==============================================================================
-- Usa la STESSA logica di anagrafica della query eventi

WITH AnagraficaPneumaticiCompleta AS (
    -- PNEUMATICI MONTATI
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
        
        -- Dati Salesforce
        ISNULL(LTRIM(RTRIM(dw.classificatore3)),'') AS Diametro__c,
        ISNULL(LTRIM(RTRIM(dw.classificatore1)),'') AS Larghezza__c,
        dw.MARCA AS Marca__c,
        LEFT(
            LTRIM(RTRIM(dw.ext_Misura)) + '_' + 
            LTRIM(RTRIM(ISNULL(dw.IND_CARICO,''))) + 
            LTRIM(RTRIM(ISNULL(dw.IND_VELOCITA,''))) + '_' + 
            LTRIM(RTRIM(dw.ART_STAGIONEShort)) + '_' + 
            LTRIM(RTRIM(dw.MARCA)), 80
        ) AS Name,
        ISNULL(LTRIM(RTRIM(dw.classificatore2)),'') AS Spalla__c,
        ISNULL(dw.ART_STAGIONE,'ESTIVO') AS Stagione__c,
        asl.Art_Qta AS Quantita__c
        
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
        
        -- Dati Salesforce
        ISNULL(LTRIM(RTRIM(dw.classificatore3)),'') AS Diametro__c,
        ISNULL(LTRIM(RTRIM(dw.classificatore1)),'') AS Larghezza__c,
        dw.MARCA AS Marca__c,
        LEFT(
            LTRIM(RTRIM(dw.ext_Misura)) + '_' + 
            LTRIM(RTRIM(ISNULL(dw.IND_CARICO,''))) + 
            LTRIM(RTRIM(ISNULL(dw.IND_VELOCITA,''))) + '_' + 
            LTRIM(RTRIM(dw.ART_STAGIONEShort)) + '_' + 
            LTRIM(RTRIM(dw.MARCA)), 80
        ) AS Name,
        ISNULL(LTRIM(RTRIM(dw.classificatore2)),'') AS Spalla__c,
        ISNULL(dw.ART_STAGIONE,'ESTIVO') AS Stagione__c,
        1 AS Quantita__c
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
        
        -- Dati Salesforce
        ISNULL(LTRIM(RTRIM(dw_post.classificatore3)),'') AS Diametro__c,
        ISNULL(LTRIM(RTRIM(dw_post.classificatore1)),'') AS Larghezza__c,
        dw_post.MARCA AS Marca__c,
        LEFT(
            LTRIM(RTRIM(dw_post.ext_Misura)) + '_' + 
            LTRIM(RTRIM(ISNULL(dw_post.IND_CARICO,''))) + 
            LTRIM(RTRIM(ISNULL(dw_post.IND_VELOCITA,''))) + '_' + 
            LTRIM(RTRIM(dw_post.ART_STAGIONEShort)) + '_' + 
            LTRIM(RTRIM(dw_post.MARCA)), 80
        ) AS Name,
        ISNULL(LTRIM(RTRIM(dw_post.classificatore2)),'') AS Spalla__c,
        ISNULL(dw_post.ART_STAGIONE,'ESTIVO') AS Stagione__c,
        1 AS Quantita__c
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

-- Cronologia per determinare ultimo stato
CronologiaLineare AS (
    SELECT 
        v.IdVeicolo, sl.IdSchedaLavoro, sl.Data_Lavori, ascl.Art_Codice, ascl.Art_Fascia, d.D_ArtCodice, d.D_TipoDepositoR1,
        ROW_NUMBER() OVER(PARTITION BY v.IdVeicolo ORDER BY sl.Data_Lavori, sl.IdSchedaLavoro) AS NumeroRiga
    FROM Veicolo v (NOLOCK) 
    INNER JOIN SchedaLavoro sl (NOLOCK) ON v.IdVeicolo = sl.S_IdVeicolo 
    LEFT JOIN Deposito d (NOLOCK) ON d.D_IdSchedaLavoro = sl.IdSchedaLavoro AND sl.S_IdVeicolo = d.D_IdVeicolo 
    LEFT JOIN ArtSchedaLavoro ascl (NOLOCK) ON sl.IdSchedaLavoro = ascl.Art_IdSchedaLavoro
    WHERE ascl.Art_Qta > 0 
      AND (ascl.Art_Fascia IN ('A', 'B', 'C', 'U') OR ascl.Art_Codice LIKE '%MS_STAG%' OR ascl.Art_Codice LIKE '%MSNUOVO%')
      AND v.IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
),

-- Ultimo evento per ogni pneumatico (deposito o smaltimento)
UltimoEventoPneumatico AS (
    SELECT 
        d.D_IdVeicolo,
        d.D_ArtCodice,
        d.D_TipoDepositoR1,
        sl.Data_Lavori,
        ROW_NUMBER() OVER(
            PARTITION BY d.D_IdVeicolo, d.D_ArtCodice 
            ORDER BY sl.Data_Lavori DESC
        ) AS RankUltimo
    FROM Deposito d
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    WHERE d.D_IdSchedaLavoro > 0 
      AND d.D_ArtCodice IS NOT NULL
      AND d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
    
    UNION ALL
    
    -- Eventi per pneumatici posteriori
    SELECT 
        d.D_IdVeicolo,
        d.D_ArtCodicePost AS D_ArtCodice,
        d.D_TipoDepositoR2 AS D_TipoDepositoR1,
        sl.Data_Lavori,
        ROW_NUMBER() OVER(
            PARTITION BY d.D_IdVeicolo, d.D_ArtCodicePost 
            ORDER BY sl.Data_Lavori DESC
        ) AS RankUltimo
    FROM Deposito d
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    WHERE d.D_IdSchedaLavoro > 0 
      AND d.D_ArtCodicePost IS NOT NULL
      AND d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
),

-- Ultima scheda stagionale per ogni veicolo
UltimaSchedaStagionale AS (
    SELECT 
        sl.S_IdVeicolo,
        sl.Data_Lavori AS UltimaDataStagionale,
        ROW_NUMBER() OVER(PARTITION BY sl.S_IdVeicolo ORDER BY sl.Data_Lavori DESC) AS RankUltima
    FROM SchedaLavoro sl
    INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro
    WHERE asl.Art_Codice LIKE '%MS_STAG%'
      AND sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
),

-- Stato finale basato sull'ultimo evento di ogni pneumatico
UltimoStatoPneumatico AS (
    SELECT 
        ap.External_Id__c,
        ap.CodiceArticolo,
        uep.D_TipoDepositoR1,
        uep.Data_Lavori AS UltimaDataEvento,
        uss.UltimaDataStagionale,
        ROW_NUMBER() OVER(PARTITION BY ap.External_Id__c ORDER BY uep.Data_Lavori DESC) AS RankUltimo
    FROM AnagraficaPneumaticiCompleta ap
    LEFT JOIN UltimoEventoPneumatico uep ON uep.D_IdVeicolo = ap.IdVeicolo 
        AND (
            uep.D_ArtCodice = ap.CodiceArticolo 
            OR uep.D_ArtCodice = LEFT(ap.CodiceArticolo, 7)
        )
        AND uep.RankUltimo = 1
    LEFT JOIN UltimaSchedaStagionale uss ON uss.S_IdVeicolo = ap.IdVeicolo 
        AND uss.RankUltima = 1
)

-- RISULTATO: TABELLA PNEUMATICO SALESFORCE
SELECT 
    ap.External_Id__c,
    ap.IdVeicolo AS [Veicolo__r:Veicolo__c:External_ID__c],
    ap.IdArticolo AS [Prodotto__r:Product2:External_Id__c],
    ap.DOT__c,
    ap.Diametro__c,
    ap.Quantita__c,
    ap.Larghezza__c,
    ap.Marca__c,
    ap.Name,
    ap.Spalla__c,
    ap.Stagione__c,
    0 AS Km_percorsi__c,  -- Da calcolare successivamente
    
    -- Stato basato sull'ultimo evento del pneumatico
    CASE 
        WHEN usp.D_TipoDepositoR1 LIKE '%Smaltite%' THEN 'Smaltita'
        WHEN usp.D_TipoDepositoR1 LIKE '%Deposito%' THEN 'Depositata'
        WHEN usp.D_TipoDepositoR1 LIKE '%Porta Via%' THEN 'Porta Via'
        WHEN ap.TipoPneumatico IN ('SOLO_DEPOSITO', 'SOLO_DEPOSITO_POST') THEN 'Depositata'
        ELSE 'Montata'  -- Se non ha eventi di deposito, è montato
    END AS Stato__c
    
FROM AnagraficaPneumaticiCompleta ap
LEFT JOIN UltimoStatoPneumatico usp ON usp.External_Id__c = ap.External_Id__c AND usp.RankUltimo = 1
ORDER BY ap.IdVeicolo, ap.IdArticolo, ap.DOT__c;