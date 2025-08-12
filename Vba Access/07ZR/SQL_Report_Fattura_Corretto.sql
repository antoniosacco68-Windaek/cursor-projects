-- SQL CORRETTO per il report "FatturaAutomatica07ZR_Singola"
-- RIMUOVI la riga PARAMETERS e la condizione fissa nel WHERE

SELECT Clienti.*, I24TestaFatturePerPdf.*, I24RigheFatturePerPdf.*
FROM (I24TestaFatturePerPdf LEFT JOIN Clienti ON I24TestaFatturePerPdf.IDCLIENTE = Clienti.IdClienti) 
     LEFT JOIN I24RigheFatturePerPdf ON I24TestaFatturePerPdf.IdFatture = I24RigheFatturePerPdf.IDFAT
ORDER BY I24RigheFatturePerPdf.Riga; 