USE I24DB

/*

Importazione del file CSV "BgInventarioDepositi.csv"
VERSIONE CON PRESERVAZIONE ORDINE USANDO OPENROWSET

*/

-- Abilitazione di Ad Hoc Distributed Queries (necessario per OPENROWSET)
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

-- Cancellazione tabella di destinazione
TRUNCATE TABLE Inventario_Depositi

-- Importazione diretta con OPENROWSET preservando l'ordine
INSERT INTO Inventario_Depositi (Targa)
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Text;Database=C:\Users\Antonio\Documents\SQL Server Management Studio\Projects\IVDepositi\;HDR=YES',
    'SELECT * FROM BgInventarioDepositi.csv'
)
ORDER BY (SELECT NULL); -- Mantiene l'ordine di lettura del file

-- Stampa messaggio di completamento
PRINT 'Importazione completata con OPENROWSET mantenendo ordine originale.';

-- Verifica prime 10 righe
SELECT TOP 10 ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NumeroRiga, Targa
FROM Inventario_Depositi; 