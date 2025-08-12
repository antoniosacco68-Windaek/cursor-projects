-- SQL per nuovo report "BollaAutomatica07ZR_Singola"
-- Questo report caricherà solo UNA bolla specifica

PARAMETERS [IdBollaParam] Long;

SELECT RicercaBolleWebPortali.*
FROM RicercaBolleWebPortali
WHERE RicercaBolleWebPortali.ID = [IdBollaParam]; 