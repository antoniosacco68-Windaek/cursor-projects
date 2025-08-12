USE [I24DB]
GO
/****** Object:  StoredProcedure [dbo].[usp_Pneu_InitAnagrafica]    Script Date: 08/08/2025 12:17:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER   PROCEDURE [dbo].[usp_Pneu_InitAnagrafica]
AS
BEGIN
  SET NOCOUNT ON;

  IF OBJECT_ID('tempdb..#AnaSrc') IS NOT NULL DROP TABLE #AnaSrc;

   SELECT
      ap.IdVeicolo,
      ap.CodiceArticolo,
      ap.IdArticolo,
      ap.DOT__c,
      ap.External_Id__c,
      ap.Quantita__c,
      ap.TipoPneumatico,
      ap.Fonte_DataLavori,
      ap.Fonte,
      ap.Src_IdSchedaLavoro,
       ap.Src_IdDeposito,
       ap.TipoDeposito
  INTO #AnaSrc
  FROM (
      -- NUOVI MONTATI (SchedaLavoro + ArtSchedaLavoro)
      SELECT 
          sl.S_IdVeicolo AS IdVeicolo,
          asl.Art_Codice  AS CodiceArticolo,
          dw.ART_ID       AS IdArticolo,
          COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT,''))),''),
                   FORMAT(DATEPART(week, DATEADD(day,-90,sl.Data_Lavori)),'00') + FORMAT(sl.Data_Lavori,'yy')) AS DOT__c,
          CAST(sl.S_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
          COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT,''))),''),
                   FORMAT(DATEPART(week, DATEADD(day,-90,sl.Data_Lavori)),'00') + FORMAT(sl.Data_Lavori,'yy')) + '_' +
          CAST(sl.IdSchedaLavoro AS VARCHAR(10)) AS External_Id__c,
          CAST(asl.Art_Qta AS DECIMAL(9,2)) AS Quantita__c,
          'NEWLY_MOUNTED' AS TipoPneumatico,
          sl.Data_Lavori  AS Fonte_DataLavori,
          'SL'            AS Fonte,
          sl.IdSchedaLavoro AS Src_IdSchedaLavoro,
          CAST(NULL AS INT) AS Src_IdDeposito,
          CAST(NULL AS VARCHAR(100)) AS TipoDeposito
      FROM SchedaLavoro sl
      INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro
      INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = asl.Art_Codice
      WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
        AND asl.Art_Fascia IN ('A','B','C','U','R') 

      UNION ALL

      -- SOLO DEPOSITO ANTERIORI (solo il primo deposito per Veicolo+Codice+DOT; evita duplicati se esiste già un'anagrafica)
      SELECT 
          d.D_IdVeicolo,
          d.D_ArtCodice,
          dw.ART_ID,
          DOT__c = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') ,
                            FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy')) ,
          External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
                   COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') ,
                            FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy')) + '_' +
                   CAST(d.D_IdSchedaLavoro AS VARCHAR(10)),
          CAST(1 AS DECIMAL(9,2)) AS Quantita__c,
          'SOLO_DEPOSITO' AS TipoPneumatico,
          d.Data AS Fonte_DataLavori,
          'DEP' AS Fonte,
          d.D_IdSchedaLavoro AS Src_IdSchedaLavoro,
          d.IdDeposito       AS Src_IdDeposito,
          d.D_TipoDepositoR1 AS TipoDeposito
      FROM (
         SELECT d.*, 
                ROW_NUMBER() OVER (
                  PARTITION BY d.D_IdVeicolo, d.D_ArtCodice
                  ORDER BY d.Data, d.D_IdSchedaLavoro
                ) AS RN
         FROM Deposito d
          WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
            AND d.D_IdSchedaLavoro > 0
            AND d.D_ArtCodice IS NOT NULL
            AND (
                 d.D_TipoDepositoR1 LIKE '%Deposito%'
              OR d.D_TipoDepositoR1 LIKE '%finite%'
              OR d.D_TipoDepositoR1 LIKE '%Smaltite%'
              OR d.D_TipoDepositoR1 LIKE '%Porta Via%'
             )
      ) d
      INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
      INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = d.D_ArtCodice
      LEFT JOIN dbo.Pneu_Anagrafica pa
        ON pa.IdVeicolo = d.D_IdVeicolo
       AND pa.CodiceArticolo = d.D_ArtCodice
       AND pa.DOT__c = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotAnt,''))),'') ,
                                 FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy'))
       WHERE d.RN = 1
         AND pa.External_Id__c IS NULL
         AND NOT EXISTS (
             SELECT 1
             FROM SchedaLavoro sl2
             INNER JOIN ArtSchedaLavoro a2 ON a2.Art_IdSchedaLavoro = sl2.IdSchedaLavoro
             WHERE sl2.S_IdVeicolo = d.D_IdVeicolo
               AND a2.Art_Codice = d.D_ArtCodice
               AND a2.Art_Fascia IN ('A','B','C','U','R')
               AND sl2.Data_Lavori <= d.Data
         )

      UNION ALL

      -- SOLO DEPOSITO POSTERIORI (solo il primo deposito per Veicolo+Codice+DOT; evita duplicati se esiste già un'anagrafica)
      SELECT 
          d.D_IdVeicolo,
          d.D_ArtCodicePost,
          dw.ART_ID,
          DOT__c = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') ,
                            FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy')) ,
          External_Id__c = CAST(d.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' +
          COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') ,
                   FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy')) + '_' +
          CAST(d.D_IdSchedaLavoro AS VARCHAR(10)),
          CAST(1 AS DECIMAL(9,2)) AS Quantita__c,
          'SOLO_DEPOSITO_POST' AS TipoPneumatico,
          d.Data AS Fonte_DataLavori,
          'DEP' AS Fonte,
          d.D_IdSchedaLavoro AS Src_IdSchedaLavoro,
          d.IdDeposito       AS Src_IdDeposito,
          d.D_TipoDepositoR2 AS TipoDeposito
      FROM (
         SELECT d.*, 
                ROW_NUMBER() OVER (
                  PARTITION BY d.D_IdVeicolo, d.D_ArtCodicePost
                  ORDER BY d.Data, d.D_IdSchedaLavoro
                ) AS RN
         FROM Deposito d
          WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
            AND d.D_IdSchedaLavoro > 0
            AND d.D_ArtCodicePost IS NOT NULL
            AND (
                 d.D_TipoDepositoR2 LIKE '%Deposito%'
              OR d.D_TipoDepositoR2 LIKE '%finite%'
              OR d.D_TipoDepositoR2 LIKE '%Smaltite%'
              OR d.D_TipoDepositoR2 LIKE '%Porta Via%'
             )
      ) d
      INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
      INNER JOIN Ant_Descrittori_WebSmall dw ON dw.ART_CODICE = d.D_ArtCodicePost
      LEFT JOIN dbo.Pneu_Anagrafica pa
        ON pa.IdVeicolo = d.D_IdVeicolo
       AND pa.CodiceArticolo = d.D_ArtCodicePost
       AND pa.DOT__c = COALESCE(NULLIF(LTRIM(RTRIM(ISNULL(d.D_DotPost,''))),'') ,
                                 FORMAT(DATEPART(week, DATEADD(day,-90,d.Data)),'00') + FORMAT(d.Data,'yy'))
       WHERE d.RN = 1
         AND pa.External_Id__c IS NULL
         AND NOT EXISTS (
             SELECT 1
             FROM SchedaLavoro sl2
             INNER JOIN ArtSchedaLavoro a2 ON a2.Art_IdSchedaLavoro = sl2.IdSchedaLavoro
             WHERE sl2.S_IdVeicolo = d.D_IdVeicolo
               AND a2.Art_Codice = d.D_ArtCodicePost
               AND a2.Art_Fascia IN ('A','B','C','U','R')
               AND sl2.Data_Lavori <= d.Data
         )
  ) ap;

  -- Conserva TUTTE le SL; per i soli DEP tieni il primo per Veicolo+Codice+DOT (per evitare doppi depositi)
  IF OBJECT_ID('tempdb..#AnaSrc_First') IS NOT NULL DROP TABLE #AnaSrc_First;
   SELECT 
         IdVeicolo,
         CodiceArticolo,
         IdArticolo,
         DOT__c,
         External_Id__c,
         Quantita__c,
         TipoPneumatico,
         Fonte_DataLavori,
         Fonte,
         Src_IdSchedaLavoro,
          Src_IdDeposito,
          TipoDeposito
  INTO #AnaSrc_First 
  FROM (
      SELECT 
         ap.IdVeicolo,
         ap.CodiceArticolo,
         ap.IdArticolo,
         ap.DOT__c,
         ap.External_Id__c,
         ap.Quantita__c,
         ap.TipoPneumatico,
         ap.Fonte_DataLavori,
         ap.Fonte,
         ap.Src_IdSchedaLavoro,
         ap.Src_IdDeposito,
         ap.TipoDeposito
      FROM #AnaSrc ap
      WHERE ap.Fonte = 'SL'
      UNION ALL
      SELECT 
         ap.IdVeicolo,
         ap.CodiceArticolo,
         ap.IdArticolo,
         ap.DOT__c,
         ap.External_Id__c,
         ap.Quantita__c,
         ap.TipoPneumatico,
         ap.Fonte_DataLavori,
         ap.Fonte,
         ap.Src_IdSchedaLavoro,
         ap.Src_IdDeposito,
         ap.TipoDeposito
      FROM (
          SELECT ap.*, ROW_NUMBER() OVER (
                    PARTITION BY ap.IdVeicolo, ap.CodiceArticolo, ap.DOT__c
                    ORDER BY ap.Fonte_DataLavori, ap.External_Id__c
                 ) AS RN
          FROM #AnaSrc ap
          WHERE ap.Fonte = 'DEP'
      ) ap
      WHERE ap.RN = 1
  ) x;

  -- Deduplica per External_Id__c per evitare duplicati nel MERGE (stessa chiave con attributi diversi)
  IF OBJECT_ID('tempdb..#AnaSrc_Dedup') IS NOT NULL DROP TABLE #AnaSrc_Dedup;
   SELECT TOP 1000000000
         ap.IdVeicolo,
         ap.CodiceArticolo,
         ap.IdArticolo,
         ap.DOT__c,
         ap.External_Id__c,
         ap.Quantita__c,
         ap.TipoPneumatico,
         ap.Fonte_DataLavori,
         ap.Fonte,
         ap.Src_IdSchedaLavoro,
          ap.Src_IdDeposito,
          ap.TipoDeposito
  INTO #AnaSrc_Dedup
  FROM (
      SELECT ap.*,
             ROW_NUMBER() OVER (
               PARTITION BY ap.External_Id__c
               ORDER BY CASE WHEN ap.TipoPneumatico = 'NEWLY_MOUNTED' THEN 0 ELSE 1 END,
                        ap.Fonte_DataLavori,
                        ap.Src_IdSchedaLavoro,
                        ap.Src_IdDeposito
             ) AS RN
      FROM #AnaSrc_First ap
  ) ap
  WHERE ap.RN = 1;

  ;MERGE dbo.Pneu_Anagrafica AS T
  USING (SELECT * FROM #AnaSrc_Dedup) AS S
     ON T.External_Id__c = S.External_Id__c
  WHEN NOT MATCHED BY TARGET THEN
    INSERT (External_Id__c, IdVeicolo, CodiceArticolo, IdArticolo, DOT__c, Quantita__c,
            FirstSeenData, Fonte, Fonte_SchedaLavoro, Fonte_IdDeposito,
            StatoCorrente, LastEventoData, Last_IdSchedaLavoro, Last_IdDeposito)
    VALUES (S.External_Id__c, S.IdVeicolo, S.CodiceArticolo, S.IdArticolo, S.DOT__c, S.Quantita__c,
            S.Fonte_DataLavori, S.Fonte, S.Src_IdSchedaLavoro, S.Src_IdDeposito,
             CASE WHEN S.Fonte = 'DEP' THEN 
                    CASE 
                      WHEN S.TipoDeposito LIKE '%Smaltite%' THEN 'Smaltita'
                      WHEN S.TipoDeposito LIKE '%Porta Via%' AND S.TipoDeposito LIKE '%finite%' THEN 'Portata via cliente finita'
                      WHEN S.TipoDeposito LIKE '%Porta Via%' THEN 'Portata via cliente'
                      WHEN S.TipoDeposito LIKE '%finite%' THEN 'Depositata finita'
                      ELSE 'Depositata'
                    END
                  ELSE 'Montata' END,
            NULL, NULL, NULL)
  -- nessun WHEN NOT MATCHED BY SOURCE
  ;

END
