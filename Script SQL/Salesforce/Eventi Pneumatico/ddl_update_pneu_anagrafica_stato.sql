USE [I24DB]
GO
IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Pneu_Anagrafica_Stato')
BEGIN
  ALTER TABLE dbo.Pneu_Anagrafica DROP CONSTRAINT CK_Pneu_Anagrafica_Stato;
END
GO
ALTER TABLE dbo.Pneu_Anagrafica ADD CONSTRAINT CK_Pneu_Anagrafica_Stato
CHECK (StatoCorrente IN ('Montata','Depositata','Depositata finita','Portata via cliente','Portata via cliente finita','Smaltita'));
GO

