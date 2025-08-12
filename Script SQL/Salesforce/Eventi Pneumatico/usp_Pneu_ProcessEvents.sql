USE [I24DB]
GO
ALTER PROCEDURE [dbo].[usp_Pneu_ProcessEvents]
AS
BEGIN
  SET NOCOUNT ON;

  -- 1) Montaggi NUOVI (A/B/C/U/R) -> Evento Montaggio + Stato=Montata
  IF OBJECT_ID('tempdb..#Montaggi') IS NOT NULL DROP TABLE #Montaggi;

    SELECT DISTINCT
      sl.S_IdVeicolo         AS IdVeicolo,
      asl.Art_Codice         AS CodiceArticolo,
      sl.IdSchedaLavoro,
      sl.Data_Lavori         AS DataEvento,
      sl.Km,
      dw.ART_ID              AS IdArticolo,
      External_Id__c = CAST(sl.S_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                       COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT,''))),''),
                                FORMAT(DATEPART(week, DATEADD(day,-90,sl.Data_Lavori)),'00') + FORMAT(sl.Data_Lavori,'yy')) + '_' +
                       CAST(sl.IdSchedaLavoro AS VARCHAR(10))
  INTO #Montaggi
    FROM SchedaLavoro sl
    INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro
    INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = asl.Art_Codice
    WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
    AND asl.Art_Fascia IN ('A','B','C','U','R');

  INSERT INTO dbo.Pneu_Evento (External_Id__c, IdVeicolo, CodiceArticolo, TipoEvento, DataEvento, Km, IdSchedaLavoro, IdDeposito, Note)
  SELECT m.External_Id__c, m.IdVeicolo, m.CodiceArticolo, 'Montaggio', m.DataEvento, m.Km, m.IdSchedaLavoro, NULL, 'Montaggio pneumatico'
  FROM #Montaggi m
  WHERE EXISTS (SELECT 1 FROM dbo.Pneu_Anagrafica pa WHERE pa.External_Id__c = m.External_Id__c)
    AND NOT EXISTS (
      SELECT 1 FROM dbo.Pneu_Evento e
      WHERE e.External_Id__c = m.External_Id__c AND e.TipoEvento='Montaggio' AND e.DataEvento = m.DataEvento
  );

  UPDATE pa
    SET StatoCorrente = 'Montata',
        LastEventoData = m.DataEvento,
        Last_IdSchedaLavoro = m.IdSchedaLavoro,
        ModifiedAtUtc = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #Montaggi m ON m.External_Id__c = pa.External_Id__c;

  -- 2) Smontaggi da Deposito (ANTERIORI+POSTERIORI) FIFO per veicolo+codice
  IF OBJECT_ID('tempdb..#SmAnt')  IS NOT NULL DROP TABLE #SmAnt;
  IF OBJECT_ID('tempdb..#SmPost') IS NOT NULL DROP TABLE #SmPost;

  SELECT
      d.D_IdVeicolo AS IdVeicolo,
      d.D_ArtCodice AS CodiceArticolo,
      d.Data        AS DataEvento,
      sl.Km,
      d.D_IdSchedaLavoro AS IdSchedaLavoro,
      d.IdDeposito  AS IdDeposito,
      d.D_TipoDepositoR1 AS TipoDeposito,
      RN = ROW_NUMBER() OVER (PARTITION BY d.D_IdVeicolo, d.D_ArtCodice ORDER BY d.Data, d.D_IdSchedaLavoro)
  INTO #SmAnt
  FROM Deposito d
  INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
  WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
    AND d.D_ArtCodice IS NOT NULL
    AND d.D_IdSchedaLavoro > 0;

  SELECT
      d.D_IdVeicolo AS IdVeicolo,
      d.D_ArtCodicePost AS CodiceArticolo,
      d.Data        AS DataEvento,
      sl.Km,
      d.D_IdSchedaLavoro AS IdSchedaLavoro,
      d.IdDeposito  AS IdDeposito,
      d.D_TipoDepositoR2 AS TipoDeposito,
      RN = ROW_NUMBER() OVER (PARTITION BY d.D_IdVeicolo, d.D_ArtCodicePost ORDER BY d.Data, d.D_IdSchedaLavoro)
  INTO #SmPost
  FROM Deposito d
  INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
  WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
    AND d.D_ArtCodicePost IS NOT NULL
    AND d.D_IdSchedaLavoro > 0;

  -- Anagrafiche candidate FIFO (solo Montate per gli smontaggi)
  IF OBJECT_ID('tempdb..#AnaAnt')  IS NOT NULL DROP TABLE #AnaAnt;
  IF OBJECT_ID('tempdb..#AnaPost') IS NOT NULL DROP TABLE #AnaPost;

  SELECT
      pa.IdVeicolo, pa.CodiceArticolo, pa.External_Id__c,
      pa.FirstSeenData, pa.LastEventoData, pa.StatoCorrente, pa.Fonte, pa.Fonte_SchedaLavoro,
      RN = ROW_NUMBER() OVER (PARTITION BY pa.IdVeicolo, pa.CodiceArticolo ORDER BY pa.FirstSeenData, pa.External_Id__c)
  INTO #AnaAnt
  FROM dbo.Pneu_Anagrafica pa
  WHERE pa.IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId);

  SELECT
      pa.IdVeicolo, pa.CodiceArticolo, pa.External_Id__c,
      pa.FirstSeenData, pa.LastEventoData, pa.StatoCorrente, pa.Fonte, pa.Fonte_SchedaLavoro,
      RN = ROW_NUMBER() OVER (PARTITION BY pa.IdVeicolo, pa.CodiceArticolo ORDER BY pa.FirstSeenData, pa.External_Id__c)
  INTO #AnaPost
  FROM dbo.Pneu_Anagrafica pa
  WHERE pa.IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId);

  -- Match FIFO Anteriore (usa temp table per riutilizzo in UPDATE)
  IF OBJECT_ID('tempdb..#MatchAnt') IS NOT NULL DROP TABLE #MatchAnt;
  SELECT COALESCE(m1.External_Id__c, m2.External_Id__c) AS External_Id__c, s.*
  INTO #MatchAnt
    FROM #SmAnt s
  OUTER APPLY (
    SELECT TOP 1 a.External_Id__c
    FROM #AnaAnt a
    WHERE a.IdVeicolo = s.IdVeicolo
      AND a.CodiceArticolo = s.CodiceArticolo
      AND a.StatoCorrente = 'Montata'
      AND a.LastEventoData IS NOT NULL AND a.LastEventoData <= s.DataEvento
      AND NOT (a.Fonte = 'SL' AND a.Fonte_SchedaLavoro = s.IdSchedaLavoro)
    ORDER BY a.LastEventoData DESC, a.External_Id__c ASC
  ) m1
  OUTER APPLY (
    SELECT TOP 1 a.External_Id__c
    FROM #AnaAnt a
    WHERE a.IdVeicolo = s.IdVeicolo
      AND a.CodiceArticolo = s.CodiceArticolo
      AND a.FirstSeenData <= s.DataEvento
      AND a.StatoCorrente = 'Depositata'
    ORDER BY a.FirstSeenData ASC, a.External_Id__c ASC
  ) m2
  WHERE COALESCE(m1.External_Id__c, m2.External_Id__c) IS NOT NULL;

  INSERT INTO dbo.Pneu_Evento (External_Id__c, IdVeicolo, CodiceArticolo, TipoEvento, DataEvento, Km, IdSchedaLavoro, IdDeposito, Note)
  SELECT m.External_Id__c, m.IdVeicolo, m.CodiceArticolo, 'Smontaggio', m.DataEvento, m.Km, m.IdSchedaLavoro, m.IdDeposito,
         CASE 
           WHEN m.TipoDeposito LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale'
           WHEN m.TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento'
           WHEN m.TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente'
           WHEN m.TipoDeposito LIKE '%finite%'  THEN 'Smontaggio per deposito (finite)'
           ELSE 'Smontaggio per ' + ISNULL(m.TipoDeposito,'deposito')
         END
  FROM #MatchAnt m
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Pneu_Evento e
    WHERE e.External_Id__c = m.External_Id__c AND e.TipoEvento='Smontaggio' AND e.IdDeposito = m.IdDeposito
  );

  UPDATE pa
     SET StatoCorrente = CASE 
                            WHEN m.TipoDeposito LIKE '%Smaltite%' THEN 'Smaltita'
                            WHEN m.TipoDeposito LIKE '%Porta Via%' AND m.TipoDeposito LIKE '%finite%' THEN 'Portata via cliente finita'
                            WHEN m.TipoDeposito LIKE '%Porta Via%' THEN 'Portata via cliente'
                            WHEN m.TipoDeposito LIKE '%finite%' THEN 'Depositata finita'
                            ELSE 'Depositata'
                         END,
         LastEventoData = m.DataEvento,
         Last_IdSchedaLavoro = m.IdSchedaLavoro,
         Last_IdDeposito     = m.IdDeposito,
         ModifiedAtUtc = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #MatchAnt m ON m.External_Id__c = pa.External_Id__c;

  -- Match FIFO Posteriore (temp table)
  IF OBJECT_ID('tempdb..#MatchPost') IS NOT NULL DROP TABLE #MatchPost;
  SELECT COALESCE(m1.External_Id__c, m2.External_Id__c) AS External_Id__c, s.*
  INTO #MatchPost
    FROM #SmPost s
  OUTER APPLY (
    SELECT TOP 1 a.External_Id__c
    FROM #AnaPost a
    WHERE a.IdVeicolo = s.IdVeicolo
      AND a.CodiceArticolo = s.CodiceArticolo
      AND a.StatoCorrente = 'Montata'
      AND a.LastEventoData IS NOT NULL AND a.LastEventoData <= s.DataEvento
      AND NOT (a.Fonte = 'SL' AND a.Fonte_SchedaLavoro = s.IdSchedaLavoro)
    ORDER BY a.LastEventoData DESC, a.External_Id__c ASC
  ) m1
  OUTER APPLY (
    SELECT TOP 1 a.External_Id__c
    FROM #AnaPost a
    WHERE a.IdVeicolo = s.IdVeicolo
      AND a.CodiceArticolo = s.CodiceArticolo
      AND a.FirstSeenData <= s.DataEvento
      AND a.StatoCorrente = 'Depositata'
    ORDER BY a.FirstSeenData ASC, a.External_Id__c ASC
  ) m2
  WHERE COALESCE(m1.External_Id__c, m2.External_Id__c) IS NOT NULL;

  INSERT INTO dbo.Pneu_Evento (External_Id__c, IdVeicolo, CodiceArticolo, TipoEvento, DataEvento, Km, IdSchedaLavoro, IdDeposito, Note)
  SELECT m.External_Id__c, m.IdVeicolo, m.CodiceArticolo, 'Smontaggio', m.DataEvento, m.Km, m.IdSchedaLavoro, m.IdDeposito,
         CASE 
           WHEN m.TipoDeposito LIKE '%Deposito%' THEN 'Smontaggio per deposito stagionale (posteriore)'
           WHEN m.TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento (posteriore)'
           WHEN m.TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente (posteriore)'
           WHEN m.TipoDeposito LIKE '%finite%'  THEN 'Smontaggio per deposito (finite) (posteriore)'
           ELSE 'Smontaggio per ' + ISNULL(m.TipoDeposito,'deposito') + ' (posteriore)'
         END
  FROM #MatchPost m
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Pneu_Evento e
    WHERE e.External_Id__c = m.External_Id__c AND e.TipoEvento='Smontaggio' AND e.IdDeposito = m.IdDeposito
  );

  UPDATE pa
     SET StatoCorrente = CASE 
                            WHEN m.TipoDeposito LIKE '%Smaltite%' THEN 'Smaltita'
                            WHEN m.TipoDeposito LIKE '%Porta Via%' AND m.TipoDeposito LIKE '%finite%' THEN 'Portata via cliente finita'
                            WHEN m.TipoDeposito LIKE '%Porta Via%' THEN 'Portata via cliente'
                            WHEN m.TipoDeposito LIKE '%finite%' THEN 'Depositata finita'
                            ELSE 'Depositata'
                         END,
         LastEventoData = m.DataEvento,
         Last_IdSchedaLavoro = m.IdSchedaLavoro,
         Last_IdDeposito     = m.IdDeposito,
         ModifiedAtUtc = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #MatchPost m ON m.External_Id__c = pa.External_Id__c;

  -- 2b) Smontaggi diretti per righe DEP smaltite/porta via che nascono da SOLO_DEPOSITO (nessuna gomma montata prima)
  IF OBJECT_ID('tempdb..#SmDiretti') IS NOT NULL DROP TABLE #SmDiretti;
  SELECT
      s.IdVeicolo,
      s.CodiceArticolo,
      s.DataEvento,
      s.Km,
      s.IdSchedaLavoro,
      s.IdDeposito,
      s.TipoDeposito,
      s.External_Id__c
  INTO #SmDiretti
  FROM (
      -- Anteriore
      SELECT d.D_IdVeicolo AS IdVeicolo,
             d.D_ArtCodice AS CodiceArticolo,
             d.Data        AS DataEvento,
             sl.Km,
             d.D_IdSchedaLavoro AS IdSchedaLavoro,
             d.IdDeposito  AS IdDeposito,
             d.D_TipoDepositoR1 AS TipoDeposito,
             External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                               NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') + '_' + CAST(d.D_IdSchedaLavoro AS VARCHAR(10))
      FROM Deposito d
      INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
      INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = d.D_ArtCodice
      WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
        AND d.D_ArtCodice IS NOT NULL
        AND d.D_IdSchedaLavoro > 0
        AND (d.D_TipoDepositoR1 LIKE '%Smaltite%' OR d.D_TipoDepositoR1 LIKE '%Porta Via%')
        AND NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Pneu_Evento e
            WHERE e.External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                                      NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') + '_' + CAST(d.D_IdSchedaLavoro AS VARCHAR(10))
              AND e.TipoEvento = 'Montaggio'
              AND e.IdSchedaLavoro = d.D_IdSchedaLavoro
        )
      UNION ALL
      -- Posteriore
      SELECT d.D_IdVeicolo AS IdVeicolo,
             d.D_ArtCodicePost AS CodiceArticolo,
             d.Data        AS DataEvento,
             sl.Km,
             d.D_IdSchedaLavoro AS IdSchedaLavoro,
             d.IdDeposito  AS IdDeposito,
             d.D_TipoDepositoR2 AS TipoDeposito,
             External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                               NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') + '_' + CAST(d.D_IdSchedaLavoro AS VARCHAR(10))
      FROM Deposito d
      INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
      INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = d.D_ArtCodicePost
      WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
        AND d.D_ArtCodicePost IS NOT NULL
        AND d.D_IdSchedaLavoro > 0
        AND (d.D_TipoDepositoR2 LIKE '%Smaltite%' OR d.D_TipoDepositoR2 LIKE '%Porta Via%')
        AND NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') IS NOT NULL
        AND NOT EXISTS (
            SELECT 1 FROM dbo.Pneu_Evento e
            WHERE e.External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                                      NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') + '_' + CAST(d.D_IdSchedaLavoro AS VARCHAR(10))
              AND e.TipoEvento = 'Montaggio'
              AND e.IdSchedaLavoro = d.D_IdSchedaLavoro
        )
  ) s
  WHERE EXISTS (SELECT 1 FROM dbo.Pneu_Anagrafica pa WHERE pa.External_Id__c = s.External_Id__c);

  INSERT INTO dbo.Pneu_Evento (External_Id__c, IdVeicolo, CodiceArticolo, TipoEvento, DataEvento, Km, IdSchedaLavoro, IdDeposito, Note)
  SELECT s.External_Id__c, s.IdVeicolo, s.CodiceArticolo, 'Smontaggio', s.DataEvento, s.Km, s.IdSchedaLavoro, s.IdDeposito,
         CASE 
            WHEN s.TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio per smaltimento (diretto)'
            WHEN s.TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio porta via cliente (diretto)'
            ELSE 'Smontaggio (diretto)'
         END
  FROM #SmDiretti s
  WHERE NOT EXISTS (
      SELECT 1 FROM dbo.Pneu_Evento e
      WHERE e.External_Id__c = s.External_Id__c AND e.TipoEvento='Smontaggio' AND e.IdDeposito = s.IdDeposito
  );

  UPDATE pa
     SET StatoCorrente = CASE 
                            WHEN s.TipoDeposito LIKE '%Smaltite%' THEN 'Smaltita'
                            WHEN s.TipoDeposito LIKE '%Porta Via%' AND s.TipoDeposito LIKE '%finite%' THEN 'Portata via cliente finita'
                            WHEN s.TipoDeposito LIKE '%Porta Via%' THEN 'Portata via cliente'
                            WHEN s.TipoDeposito LIKE '%finite%' THEN 'Depositata finita'
                            ELSE 'Depositata'
                         END,
         LastEventoData = s.DataEvento,
         Last_IdSchedaLavoro = s.IdSchedaLavoro,
         Last_IdDeposito     = s.IdDeposito,
         ModifiedAtUtc = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #SmDiretti s ON s.External_Id__c = pa.External_Id__c;

  -- 3) Rimontaggio stagionale (@MS_STAG%)
  IF OBJECT_ID('tempdb..#SL_Stag') IS NOT NULL DROP TABLE #SL_Stag;
  SELECT DISTINCT sl.IdSchedaLavoro, sl.S_IdVeicolo AS IdVeicolo, sl.Data_Lavori AS DataEvento, sl.Km
  INTO #SL_Stag
  FROM SchedaLavoro sl
  WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
    AND EXISTS (
      SELECT 1 FROM ArtSchedaLavoro a 
      WHERE a.Art_IdSchedaLavoro = sl.IdSchedaLavoro 
        AND a.Art_Codice LIKE '%MS_STAG%'
    );

  -- Coda di depositi storici (non dipende dallo stato corrente, ma dagli smontaggi registrati)
  IF OBJECT_ID('tempdb..#DepEvents') IS NOT NULL DROP TABLE #DepEvents;
  SELECT External_Id__c, IdVeicolo, CodiceArticolo, DataEvento
  INTO #DepEvents
  FROM (
    SELECT External_Id__c, IdVeicolo, CodiceArticolo, DataEvento, TipoDeposito FROM #MatchAnt
    UNION ALL
    SELECT External_Id__c, IdVeicolo, CodiceArticolo, DataEvento, TipoDeposito FROM #MatchPost
  ) x
  WHERE x.TipoDeposito LIKE '%Deposito%' OR x.TipoDeposito LIKE '%finite%';

  -- Escludi in modo assoluto i pneumatici smaltiti/portati via da qualunque rimontaggio futuro
  IF OBJECT_ID('tempdb..#Smaltiti') IS NOT NULL DROP TABLE #Smaltiti;
  SELECT DISTINCT e.External_Id__c, e.DataEvento AS DataSmaltimento
  INTO #Smaltiti
  FROM dbo.Pneu_Evento e
  OUTER APPLY (
    SELECT TOP 1 Tipo FROM (
      SELECT d.D_TipoDepositoR1 AS Tipo
      FROM Deposito d WHERE d.IdDeposito = e.IdDeposito AND e.CodiceArticolo = d.D_ArtCodice
      UNION ALL
      SELECT d2.D_TipoDepositoR2
      FROM Deposito d2 WHERE d2.IdDeposito = e.IdDeposito AND e.CodiceArticolo = d2.D_ArtCodicePost
    ) t
  ) dep
  WHERE e.TipoEvento = 'Smontaggio'
    AND (
      COALESCE(dep.Tipo,'') LIKE '%Smaltite%'
      OR COALESCE(dep.Tipo,'') LIKE '%Porta Via%'
    );

  -- FIFO per codice: prendi il deposito più vecchio disponibile per ciascun codice
  IF OBJECT_ID('tempdb..#DepFIFO') IS NOT NULL DROP TABLE #DepFIFO;
  SELECT IdVeicolo, CodiceArticolo, External_Id__c, DataEvento,
         ROW_NUMBER() OVER (PARTITION BY IdVeicolo, CodiceArticolo ORDER BY DataEvento ASC, External_Id__c ASC) AS RN
  INTO #DepFIFO
  FROM #DepEvents;

  -- Codici montati nuovi in quella scheda (A/B/C/U/R) da escludere dai rimontaggi
  IF OBJECT_ID('tempdb..#CodesMontatiNuovi') IS NOT NULL DROP TABLE #CodesMontatiNuovi;
  SELECT DISTINCT s.IdSchedaLavoro, s.IdVeicolo, a.Art_Codice AS CodiceArticolo
  INTO #CodesMontatiNuovi
  FROM #SL_Stag s
  INNER JOIN ArtSchedaLavoro a ON a.Art_IdSchedaLavoro = s.IdSchedaLavoro
  WHERE a.Art_Fascia IN ('A','B','C','U','R');

  -- Codici smontati in questa scheda stagionale (solo quelli marcati Deposito/finite)
  IF OBJECT_ID('tempdb..#CodesSmontati') IS NOT NULL DROP TABLE #CodesSmontati;
  SELECT DISTINCT s.IdSchedaLavoro, s.IdVeicolo, s.CodiceArticolo
  INTO #CodesSmontati
  FROM (
    SELECT IdSchedaLavoro, IdVeicolo, CodiceArticolo FROM #SmAnt
    UNION ALL
    SELECT IdSchedaLavoro, IdVeicolo, CodiceArticolo FROM #SmPost
  ) s;

  -- Rimontaggi: prendi dalla coda di Depositata, escludendo i codici smontati nella stessa scheda
  IF OBJECT_ID('tempdb..#Rimont') IS NOT NULL DROP TABLE #Rimont;
    SELECT s.IdVeicolo, d.CodiceArticolo, d.External_Id__c, s.IdSchedaLavoro, s.DataEvento, s.Km
  INTO #Rimont
    FROM #SL_Stag s
    INNER JOIN (
      SELECT IdVeicolo, CodiceArticolo, External_Id__c, DataEvento
      FROM #DepFIFO
      WHERE RN = 1
  ) d ON d.IdVeicolo = s.IdVeicolo
  LEFT JOIN #CodesSmontati cs 
    ON cs.IdSchedaLavoro = s.IdSchedaLavoro 
   AND cs.IdVeicolo = s.IdVeicolo 
   AND cs.CodiceArticolo = d.CodiceArticolo
  LEFT JOIN #CodesMontatiNuovi cm 
    ON cm.IdSchedaLavoro = s.IdSchedaLavoro 
   AND cm.IdVeicolo = s.IdVeicolo 
   AND cm.CodiceArticolo = d.CodiceArticolo
  INNER JOIN dbo.Pneu_Anagrafica pa
    ON pa.External_Id__c = d.External_Id__c
  WHERE cs.CodiceArticolo IS NULL
    AND cm.CodiceArticolo IS NULL
    AND d.DataEvento <= s.DataEvento
     AND pa.StatoCorrente IN ('Depositata','Depositata finita')
    AND NOT EXISTS (
        SELECT 1 FROM #Smaltiti sm 
        WHERE sm.External_Id__c = d.External_Id__c 
          AND sm.DataSmaltimento <= s.DataEvento
    )
    AND EXISTS (
        SELECT 1 FROM dbo.Pneu_Anagrafica pa
        WHERE pa.External_Id__c = d.External_Id__c
          AND pa.FirstSeenData <= s.DataEvento
    );
  INSERT INTO dbo.Pneu_Evento (External_Id__c, IdVeicolo, CodiceArticolo, TipoEvento, DataEvento, Km, IdSchedaLavoro, IdDeposito, Note)
  SELECT r.External_Id__c, r.IdVeicolo, r.CodiceArticolo, 'Rimontaggio', r.DataEvento, r.Km, r.IdSchedaLavoro, NULL,
         'Rimontaggio da deposito (cambio stagionale)'
  FROM #Rimont r
  WHERE NOT EXISTS (
    SELECT 1 FROM dbo.Pneu_Evento e WHERE e.External_Id__c = r.External_Id__c AND e.TipoEvento='Rimontaggio' AND e.IdSchedaLavoro = r.IdSchedaLavoro
  );

  UPDATE pa
     SET StatoCorrente = 'Montata',
         LastEventoData = r.DataEvento,
         Last_IdSchedaLavoro = r.IdSchedaLavoro,
         ModifiedAtUtc = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #Rimont r ON r.External_Id__c = pa.External_Id__c;

  -- 4) Riconciliazione finale: imposta StatoCorrente in base all'ultimo evento per ciascun pneumatico
  IF OBJECT_ID('tempdb..#LastEvt') IS NOT NULL DROP TABLE #LastEvt;
  SELECT External_Id__c,
         StatoCorrente,
         DataEvento,
         IdSchedaLavoro,
         IdDeposito
  INTO #LastEvt
  FROM (
      SELECT e.External_Id__c,
             e.DataEvento,
             e.EventoId,
             e.IdSchedaLavoro,
             e.IdDeposito,
             e.CodiceArticolo,
             StatoCorrente = CASE 
               WHEN e.TipoEvento IN ('Montaggio','Rimontaggio') THEN 'Montata'
               WHEN e.TipoEvento = 'Smontaggio' THEN 
                 CASE 
                   WHEN COALESCE(dep.Tipo,'') LIKE '%Smaltite%' THEN 'Smaltita'
                   WHEN COALESCE(dep.Tipo,'') LIKE '%Porta Via%' AND COALESCE(dep.Tipo,'') LIKE '%finite%' THEN 'Portata via cliente finita'
                   WHEN COALESCE(dep.Tipo,'') LIKE '%Porta Via%' THEN 'Portata via cliente'
                   WHEN COALESCE(dep.Tipo,'') LIKE '%finite%' THEN 'Depositata finita'
                   ELSE 'Depositata'
                 END
               ELSE 'Montata'
             END,
             RN = ROW_NUMBER() OVER (PARTITION BY e.External_Id__c ORDER BY e.DataEvento DESC, e.EventoId DESC)
      FROM dbo.Pneu_Evento e
      OUTER APPLY (
         SELECT TOP 1 Tipo
         FROM (
           SELECT d.D_TipoDepositoR1 AS Tipo
           FROM Deposito d
           WHERE d.IdDeposito = e.IdDeposito AND e.CodiceArticolo = d.D_ArtCodice
           UNION ALL
           SELECT d2.D_TipoDepositoR2
           FROM Deposito d2
           WHERE d2.IdDeposito = e.IdDeposito AND e.CodiceArticolo = d2.D_ArtCodicePost
         ) x
      ) dep
  ) z
  WHERE z.RN = 1;

  UPDATE pa
     SET pa.StatoCorrente     = le.StatoCorrente,
         pa.LastEventoData    = le.DataEvento,
         pa.Last_IdSchedaLavoro = le.IdSchedaLavoro,
         pa.Last_IdDeposito     = le.IdDeposito,
         pa.ModifiedAtUtc     = SYSUTCDATETIME()
  FROM dbo.Pneu_Anagrafica pa
  INNER JOIN #LastEvt le ON le.External_Id__c = pa.External_Id__c;

END
GO