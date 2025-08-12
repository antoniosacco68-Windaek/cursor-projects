USE [I24DB]
GO
CREATE OR ALTER VIEW dbo.vw_Pneu_Eventi_Export
AS
SELECT 
  e.External_Id__c AS [Pneumatico__r:Pneumatico__c:External_Id__c],
  CAST(e.External_Id__c + '_' +
       CASE e.TipoEvento 
         WHEN 'Montaggio'   THEN 'MONT'
         WHEN 'Smontaggio'  THEN 'SMONT'
         WHEN 'Rimontaggio' THEN 'RIMONT'
         WHEN 'Smaltimento' THEN 'SMALT'
         ELSE 'EVT'
       END + '_' + FORMAT(e.DataEvento,'yyyyMMddHHmmss') AS VARCHAR(255)) AS External_Id__c,
  e.TipoEvento AS Tipo__c,
  e.DataEvento AS Data_evento__c,
  e.Km AS Km_da_scheda_di_lavoro__c,
  e.IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
  COALESCE(
      asl_exact.Id_Articoli,
      asl_stag.Id_Articoli,
      asl_mnuovo.Id_Articoli
  ) AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
  CAST(
    CONVERT(VARCHAR(23), e.CreatedAtUtc, 126) + ' ' + ISNULL(dw.DESCR_DIRECT,'') +
    CASE WHEN e.TipoEvento = 'Smontaggio' AND pa.Fonte = 'DEP' AND pa.FirstSeenData = e.DataEvento THEN ' - Primo Smontaggio' ELSE '' END
  AS NVARCHAR(400)) AS Note__c
FROM dbo.Pneu_Evento e
LEFT JOIN dbo.Pneu_Anagrafica pa
  ON pa.External_Id__c = e.External_Id__c
-- 1) Riga esatta per codice articolo della stessa scheda
LEFT JOIN ArtSchedaLavoro asl_exact
  ON asl_exact.Art_IdSchedaLavoro = e.IdSchedaLavoro
 AND asl_exact.Art_Codice = e.CodiceArticolo
-- 2) Riga servizio stagionale (@MS_STAG) della stessa scheda
LEFT JOIN ArtSchedaLavoro asl_stag
  ON asl_stag.Art_IdSchedaLavoro = e.IdSchedaLavoro
 AND asl_stag.Art_Codice LIKE '%MS_STAG%'
-- 3) Fallback: riga di montaggio nuovo (fasce A/B/C/U/R) della stessa scheda
LEFT JOIN (
  SELECT Art_IdSchedaLavoro, MIN(Id_Articoli) AS Id_Articoli
  FROM ArtSchedaLavoro
  WHERE Art_Fascia IN ('A','B','C','U','R')
  GROUP BY Art_IdSchedaLavoro
) AS asl_mnuovo
  ON asl_mnuovo.Art_IdSchedaLavoro = e.IdSchedaLavoro
LEFT JOIN Ant_Descrittori_WebSmall dw
  ON dw.ART_CODICE = e.CodiceArticolo;
GO

