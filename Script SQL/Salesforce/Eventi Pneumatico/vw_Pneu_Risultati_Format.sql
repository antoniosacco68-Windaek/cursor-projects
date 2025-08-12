USE [I24DB]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER VIEW dbo.vw_Pneu_Risultati_Format
AS
SELECT 
  e.IdSchedaLavoro,
  sl.Data_Lavori        AS [Data Lavori],
  sl.Km,
  e.CodiceArticolo,
  pa.DOT__c             AS DOT,
  e.TipoEvento,
  e.External_Id__c      AS [External_Id__c Pneumatico],
  e.IdDeposito          AS [IdDeposito di Questa Scheda Lavoro],
  e.Note,
  pa.StatoCorrente      AS [Stato attuale anagrafica]
FROM dbo.Pneu_Evento e
LEFT JOIN dbo.Pneu_Anagrafica pa
  ON pa.External_Id__c = e.External_Id__c
LEFT JOIN dbo.SchedaLavoro sl
  ON sl.IdSchedaLavoro = e.IdSchedaLavoro;
GO

