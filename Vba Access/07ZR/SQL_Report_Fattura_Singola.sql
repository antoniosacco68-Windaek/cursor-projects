-- SQL per nuovo report "FatturaAutomatica07ZR_Singola"
-- Questo report caricherà solo UNA fattura specifica

SELECT Clienti.*, I24TestaFatturePerPdf.*, I24RigheFatturePerPdf.*
FROM (I24TestaFatturePerPdf LEFT JOIN Clienti ON I24TestaFatturePerPdf.IDCLIENTE = Clienti.IdClienti) 
     LEFT JOIN I24RigheFatturePerPdf ON I24TestaFatturePerPdf.IdFatture = I24RigheFatturePerPdf.IDFAT
ORDER BY I24RigheFatturePerPdf.Riga; 