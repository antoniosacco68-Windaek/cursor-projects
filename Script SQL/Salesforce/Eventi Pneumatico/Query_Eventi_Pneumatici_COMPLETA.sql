-- ==============================================================================
-- QUERY EVENTI PNEUMATICI COMPLETA - ANTERIORI + POSTERIORI
-- Riusa ESATTA logica di anagrafica da "Pneumatico SalesForce.sql"
-- ==============================================================================

WITH AnagraficaPneumaticiCompleta AS (
    -- PNEUMATICI MONTATI (STESSA LOGICA QUERY PNEUMATICI)
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
        'NEWLY_MOUNTED' AS TipoPneumatico
        
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
        'SOLO_DEPOSITO' AS TipoPneumatico
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
        'SOLO_DEPOSITO_POST' AS TipoPneumatico
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

-- EVENTI DI MONTAGGIO: dai dati ArtSchedaLavoro (evita duplicati con DISTINCT)
EventiMontaggio AS (
    SELECT DISTINCT
        ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
        CAST(ap.External_Id__c + '_MONT_' + FORMAT(asl_scheda.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
        'Montaggio' AS Tipo__c,
        asl_scheda.Data_Lavori AS Data_evento__c, 
        asl_scheda.Km AS Km_da_scheda_di_lavoro__c,
        asl_scheda.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
        asl.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
        'Montaggio pneumatico' AS Note__c
    FROM AnagraficaPneumaticiCompleta ap
    INNER JOIN ArtSchedaLavoro asl ON asl.Art_Codice = ap.CodiceArticolo
        AND asl.Art_Fascia IN ('A','B','C','U','R')
    INNER JOIN SchedaLavoro asl_scheda ON asl_scheda.IdSchedaLavoro = asl.Art_IdSchedaLavoro
        AND asl_scheda.S_IdVeicolo = ap.IdVeicolo
        -- Collega il montaggio alla scheda che ha creato questo External_Id
        AND asl_scheda.IdSchedaLavoro = CAST(RIGHT(ap.External_Id__c, CHARINDEX('_', REVERSE(ap.External_Id__c)) - 1) AS INT)
),

-- EVENTI DI SMONTAGGIO: dai depositi (evita duplicati)
EventiSmontaggio AS (
    -- SMONTAGGIO ANTERIORI
    SELECT DISTINCT
        ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
        CAST(ap.External_Id__c + '_SMONT_' + FORMAT(sl.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
        'Smontaggio' AS Tipo__c, 
        sl.Data_Lavori AS Data_evento__c, 
        sl.Km AS Km_da_scheda_di_lavoro__c,
        sl.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
        NULL AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
        CASE 
            WHEN d.D_TipoDepositoR1 LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale (anteriore)'
            WHEN d.D_TipoDepositoR1 LIKE '%finite%' THEN 'Smontaggio per deposito finite (anteriore)'
            WHEN d.D_TipoDepositoR1 LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento (anteriore)'
            WHEN d.D_TipoDepositoR1 LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente (anteriore)'
            ELSE 'Smontaggio per ' + ISNULL(d.D_TipoDepositoR1, 'deposito') + ' (anteriore)'
        END AS Note__c
    FROM AnagraficaPneumaticiCompleta ap
    INNER JOIN Deposito d ON d.D_IdVeicolo = ap.IdVeicolo 
        AND d.D_ArtCodice = ap.CodiceArticolo
        AND d.D_IdSchedaLavoro > 0
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    
    UNION ALL
    
    -- SMONTAGGIO POSTERIORI  
    SELECT DISTINCT
        ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
        CAST(ap.External_Id__c + '_SMONT_' + FORMAT(sl.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
        'Smontaggio' AS Tipo__c, 
        sl.Data_Lavori AS Data_evento__c, 
        sl.Km AS Km_da_scheda_di_lavoro__c,
        sl.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
        NULL AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
        CASE 
            WHEN d.D_TipoDepositoR2 LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale (posteriore)'
            WHEN d.D_TipoDepositoR2 LIKE '%finite%' THEN 'Smontaggio per deposito finite (posteriore)'
            WHEN d.D_TipoDepositoR2 LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento (posteriore)'
            WHEN d.D_TipoDepositoR2 LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente (posteriore)'
            ELSE 'Smontaggio per ' + ISNULL(d.D_TipoDepositoR2, 'deposito') + ' (posteriore)'
        END AS Note__c
    FROM AnagraficaPneumaticiCompleta ap
    INNER JOIN Deposito d ON d.D_IdVeicolo = ap.IdVeicolo 
        AND d.D_ArtCodicePost = ap.CodiceArticolo
        AND d.D_IdSchedaLavoro > 0
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
),

-- EVENTI DI RIMONTAGGIO: quando viene fatto cambio stagionale (@MS_STAG) e il pneumatico è in deposito
EventiRimontaggio AS (
    -- RIMONTAGGIO quando Deposito ha Rimontate = 1
    SELECT DISTINCT
        ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
        CAST(ap.External_Id__c + '_RIMONT_' + FORMAT(d.Data_Rimontate, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
        'Rimontaggio' AS Tipo__c, 
        d.Data_Rimontate AS Data_evento__c, 
        sl_rimontaggio.Km AS Km_da_scheda_di_lavoro__c,
        sl_rimontaggio.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
        NULL AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
        'Rimontaggio da deposito - cambio stagionale' AS Note__c
    FROM AnagraficaPneumaticiCompleta ap
    INNER JOIN Deposito d ON d.D_IdVeicolo = ap.IdVeicolo 
        AND (d.D_ArtCodice = ap.CodiceArticolo OR d.D_ArtCodicePost = ap.CodiceArticolo)
        AND d.Rimontate = 1
        AND d.Data_Rimontate IS NOT NULL
        AND d.D_IdSchedaLavoro > 0
    -- Trova la scheda lavoro del rimontaggio (che contiene @MS_STAG)
    INNER JOIN SchedaLavoro sl_rimontaggio ON sl_rimontaggio.S_IdVeicolo = ap.IdVeicolo
        AND sl_rimontaggio.Data_Lavori >= d.Data_Rimontate
        AND EXISTS (
            SELECT 1 FROM ArtSchedaLavoro asl_ms
            WHERE asl_ms.Art_IdSchedaLavoro = sl_rimontaggio.IdSchedaLavoro
              AND asl_ms.Art_Codice LIKE '%MS_STAG%'
        )
)

-- RISULTATO FINALE: TUTTI GLI EVENTI PNEUMATICI
SELECT * FROM EventiMontaggio
UNION ALL
SELECT * FROM EventiSmontaggio  
UNION ALL
SELECT * FROM EventiRimontaggio

ORDER BY [Pneumatico__r:Pneumatico__c:External_Id__c], Data_evento__c;
