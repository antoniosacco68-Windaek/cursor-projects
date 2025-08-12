-- ==============================================================================
-- TABELLA EVENTI PNEUMATICO SALESFORCE - ANAGRAFICA PNEUMATICO CORRETTA 04/08/25
-- ==============================================================================


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
            )
        AS External_Id__c,
        'NEWLY_MOUNTED' AS TipoPneumatico
        
    FROM SchedaLavoro sl
    INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro  
    INNER JOIN Ant_Descrittori_WebSmall dw ON asl.Art_Codice = dw.ART_CODICE
    WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
      AND asl.Art_Fascia IN ('A','B','C','U','R')
      
    UNION ALL
    
    -- PNEUMATICI SOLO DEPOSITO
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
            ) AS External_Id__c,
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
      )
),

-- Cronologia per eventi 
CronologiaLineare AS (
    SELECT 
        ascl.Id_Articoli, sl.IdSchedaLavoro, sl.Km, sl.Data_Lavori, ascl.Art_Qta, 
        ascl.Art_Descrizione, v.IdVeicolo, d.Quantita, d.Misura, d.Modello, d.D_TipoDepositoR1,				  
        ISNULL(sl.S_GommeNuoveCliente,'0') AS GommeNuoveCliente, 
        ascl.Art_Codice, ascl.Art_Fascia, d.IdDeposito, d.Note, d.D_ArtCodice,
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
        CASE WHEN cl.Art_Codice LIKE '%MS_STAG%' THEN 1 ELSE 0 END AS ServizioStagionale,
        cl.D_TipoDepositoR1,
        LAG(CASE WHEN cl.D_ArtCodice IS NOT NULL THEN cl.D_ArtCodice ELSE NULL END, 1) 
            OVER(PARTITION BY cl.IdVeicolo ORDER BY cl.Data_Lavori, cl.IdSchedaLavoro) AS UltimoPneumaticoInDeposito
    FROM CronologiaLineare cl
)

-- RISULTATO: TABELLA EVENTI PNEUMATICO SALESFORCE
SELECT 
    ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ap.External_Id__c + '_MONT_' + FORMAT(es.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Rimontaggio' AS Tipo__c, -- Montaggio
    es.Data_Lavori AS Data_evento__c, 
    es.Km AS Km_da_scheda_di_lavoro__c,
    es.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    es.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    'Montaggio pneumatico' AS Note__c
FROM EventiSequenziali es
INNER JOIN AnagraficaPneumaticiCompleta ap ON ap.IdVeicolo = es.IdVeicolo AND ap.CodiceArticolo = es.PneumaticoMontato
WHERE es.PneumaticoMontato IS NOT NULL

UNION ALL

SELECT 
    ap.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    CAST(ap.External_Id__c + '_SMONT_' + FORMAT(es.Data_Lavori, 'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
    'Smontaggio' AS Tipo__c, 
    es.Data_Lavori AS Data_evento__c, 
    es.Km AS Km_da_scheda_di_lavoro__c,
    es.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    es.Id_Articoli AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    CASE 
        WHEN es.D_TipoDepositoR1 LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale'
        WHEN es.D_TipoDepositoR1 LIKE '%finite%' THEN 'Smontaggio per deposito (finite)'
        WHEN es.D_TipoDepositoR1 LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento'
        WHEN es.D_TipoDepositoR1 LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente'
        ELSE 'Smontaggio per ' + ISNULL(es.D_TipoDepositoR1, 'deposito')
    END AS Note__c
FROM EventiSequenziali es
INNER JOIN AnagraficaPneumaticiCompleta ap ON ap.IdVeicolo = es.IdVeicolo AND ap.CodiceArticolo = es.PneumaticoSmontato
WHERE es.PneumaticoSmontato IS NOT NULL

UNION ALL

SELECT 
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

ORDER BY Km_da_scheda_di_lavoro__c, [Pneumatico__r:Pneumatico__c:External_Id__c], Data_evento__c; 