-- Script T-SQL per chiamate API Franco Gomme - ORDINI (ORDER B2)
-- Versione 1.0

-- Configurazione dei parametri di connessione
DECLARE @BaseUrl NVARCHAR(255) = 'https://ws.francogomme.it/wsFrancogommeTest/';
DECLARE @Username NVARCHAR(50) = 'B0logn4Test';
DECLARE @Password NVARCHAR(50) = 'B0logna#2025';
DECLARE @EndPoint NVARCHAR(20) = 'OrderB2';

-- Tabella temporanea per memorizzare i risultati
IF OBJECT_ID('tempdb..#RisultatiOrdini') IS NOT NULL
    DROP TABLE #RisultatiOrdini;

CREATE TABLE #RisultatiOrdini (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    DataChiamata DATETIME DEFAULT GETDATE(),
    EndpointChiamato NVARCHAR(255),
    ParametriInviati NVARCHAR(MAX),
    RispostaJSON NVARCHAR(MAX),
    StatoRisposta INT,
    MessaggioErrore NVARCHAR(MAX)
);

-- Tabella temporanea per i prodotti da ordinare
IF OBJECT_ID('tempdb..#ProdottiDaOrdinare') IS NOT NULL
    DROP TABLE #ProdottiDaOrdinare;

CREATE TABLE #ProdottiDaOrdinare (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Marca NVARCHAR(100),
    Modello NVARCHAR(100),
    Misura NVARCHAR(50),
    Quantita INT,
    PrezzoUnitario DECIMAL(10,2),
    Codice NVARCHAR(50)
);

-- Inserimento esempi di prodotti da ordinare (sostituire con dati reali)
INSERT INTO #ProdottiDaOrdinare (Marca, Modello, Misura, Quantita, PrezzoUnitario, Codice)
VALUES 
    ('MICHELIN', 'PILOT SPORT 4', '225/45R17 91Y', 4, 120.50, '3528704855223'),
    ('PIRELLI', 'P ZERO', '245/40R18 97Y', 2, 145.75, '8019227258097');

-- Preparazione del payload JSON per l'ordine
DECLARE @PowerShellCmd NVARCHAR(MAX);
DECLARE @JsonPayload NVARCHAR(MAX);
DECLARE @ProdottiJson NVARCHAR(MAX) = '';
DECLARE @NumeroOrdine NVARCHAR(50) = 'ORD-' + CAST(CAST(NEWID() AS VARBINARY(4)) AS VARCHAR(30));
DECLARE @DataConsegna DATE = DATEADD(DAY, 5, GETDATE());

-- Costruzione del JSON per i prodotti dell'ordine
SELECT @ProdottiJson = @ProdottiJson + 
    CASE WHEN @ProdottiJson = '' THEN '' ELSE ',' END +
    '{
        "brand": "' + Marca + '",
        "model": "' + Modello + '",
        "size": "' + Misura + '",
        "quantity": ' + CAST(Quantita AS NVARCHAR(10)) + ',
        "price": ' + CAST(PrezzoUnitario AS NVARCHAR(20)) + ',
        "ean": "' + Codice + '"
    }'
FROM #ProdottiDaOrdinare;

-- Costruzione del payload JSON completo per l'ordine
SET @JsonPayload = N'{
    "username": "' + @Username + '",
    "password": "' + @Password + '",
    "orderData": {
        "orderId": "' + @NumeroOrdine + '",
        "orderDate": "' + CONVERT(NVARCHAR(10), GETDATE(), 23) + '",
        "timestamp": "' + CONVERT(NVARCHAR(30), GETDATE(), 127) + '",
        "customer": {
            "id": "CLIENTEID123",
            "name": "Cliente Test SpA",
            "vatNumber": "IT01234567890",
            "address": "Via Test 123",
            "city": "Bologna",
            "zip": "40100",
            "province": "BO",
            "country": "IT",
            "email": "ordini@clientetest.it",
            "phone": "+39051123456"
        },
        "shipping": {
            "name": "Sede Cliente Test",
            "address": "Via Consegna 456",
            "city": "Bologna",
            "zip": "40100",
            "province": "BO",
            "country": "IT",
            "contactPerson": "Mario Rossi",
            "phone": "+39051654321",
            "notes": "Consegnare dalle 8 alle 12"
        },
        "delivery": {
            "type": "STANDARD",
            "requestedDate": "' + CONVERT(NVARCHAR(10), @DataConsegna, 23) + '"
        },
        "payment": {
            "method": "BANK_TRANSFER",
            "terms": "30 DAYS"
        },
        "products": [' + @ProdottiJson + '],
        "notes": "Note di test per l''ordine"
    }
}';

-- Costruzione del comando PowerShell
SET @PowerShellCmd = N'powershell.exe -Command "
    $headers = @{''Content-Type'' = ''application/json''}
    $uri = ''' + @BaseUrl + @EndPoint + '''
    $body = ''' + REPLACE(@JsonPayload, '''', '''''') + '''
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body
        Write-Output ''STATO:200''
        Write-Output $response | ConvertTo-Json -Depth 10
    } catch {
        Write-Output (''STATO:'' + $_.Exception.Response.StatusCode.value__)
        Write-Output $_.Exception.Message
    }
"';

-- Variabili per catturare l'output di PowerShell
DECLARE @Output TABLE (Output NVARCHAR(MAX));
DECLARE @RispostaAPI NVARCHAR(MAX) = '';
DECLARE @StatoRisposta INT = 0;
DECLARE @MessaggioErrore NVARCHAR(MAX) = '';

-- Esecuzione del comando PowerShell (decommentare per usare)
/*
INSERT INTO @Output
EXEC xp_cmdshell @PowerShellCmd;

-- Elaborazione dell'output di PowerShell
DECLARE @Riga NVARCHAR(MAX);
DECLARE OutputCursor CURSOR FOR SELECT Output FROM @Output WHERE Output IS NOT NULL;
OPEN OutputCursor;
FETCH NEXT FROM OutputCursor INTO @Riga;

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @Riga LIKE 'STATO:%'
    BEGIN
        SET @StatoRisposta = CAST(REPLACE(@Riga, 'STATO:', '') AS INT);
    END
    ELSE
    BEGIN
        IF @StatoRisposta = 200
            SET @RispostaAPI = @RispostaAPI + @Riga;
        ELSE
            SET @MessaggioErrore = @MessaggioErrore + @Riga;
    END
    
    FETCH NEXT FROM OutputCursor INTO @Riga;
END

CLOSE OutputCursor;
DEALLOCATE OutputCursor;

-- Memorizzazione dei risultati
INSERT INTO #RisultatiOrdini (EndpointChiamato, ParametriInviati, RispostaJSON, StatoRisposta, MessaggioErrore)
VALUES (@BaseUrl + @EndPoint, @JsonPayload, @RispostaAPI, @StatoRisposta, @MessaggioErrore);
*/

-- Tabella permanente per memorizzare gli ordini (creazione se non esiste)
IF OBJECT_ID('dbo.OrdiniInviati') IS NULL
BEGIN
    CREATE TABLE dbo.OrdiniInviati (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        NumeroOrdine NVARCHAR(100),
        DataOrdine DATETIME DEFAULT GETDATE(),
        StatoOrdine NVARCHAR(50),
        RiferimentoFornitore NVARCHAR(100),
        DataConsegnaPrevista DATE,
        ImportoTotale DECIMAL(10,2),
        JsonRisposta NVARCHAR(MAX)
    );
END

-- Tabella permanente per memorizzare i dettagli degli ordini (creazione se non esiste)
IF OBJECT_ID('dbo.DettagliOrdiniInviati') IS NULL
BEGIN
    CREATE TABLE dbo.DettagliOrdiniInviati (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        IDOrdine INT,
        Marca NVARCHAR(100),
        Modello NVARCHAR(100),
        Misura NVARCHAR(50),
        Codice NVARCHAR(50),
        Quantita INT,
        PrezzoUnitario DECIMAL(10,2),
        StatoArticolo NVARCHAR(50),
        CONSTRAINT FK_DettagliOrdiniInviati_OrdiniInviati FOREIGN KEY (IDOrdine) REFERENCES dbo.OrdiniInviati(ID)
    );
END

-- Parsing ed elaborazione della risposta JSON (esempio - decommentare per usare)
/*
-- Estrazione dei dati dell'ordine dalla risposta
DECLARE @IDOrdineInserito INT;
DECLARE @ImportoTotale DECIMAL(10,2) = 0;

-- Calcolo dell'importo totale
SELECT @ImportoTotale = SUM(Quantita * PrezzoUnitario)
FROM #ProdottiDaOrdinare;

-- Inserimento dell'ordine
INSERT INTO dbo.OrdiniInviati (
    NumeroOrdine,
    StatoOrdine,
    RiferimentoFornitore,
    DataConsegnaPrevista,
    ImportoTotale,
    JsonRisposta
)
SELECT 
    @NumeroOrdine,
    JSON_VALUE(RispostaJSON, '$.orderResponse.status'),
    JSON_VALUE(RispostaJSON, '$.orderResponse.supplierReference'),
    @DataConsegna,
    @ImportoTotale,
    RispostaJSON
FROM #RisultatiOrdini
WHERE ID = SCOPE_IDENTITY();

SET @IDOrdineInserito = SCOPE_IDENTITY();

-- Inserimento dei dettagli dell'ordine
INSERT INTO dbo.DettagliOrdiniInviati (
    IDOrdine,
    Marca,
    Modello,
    Misura,
    Codice,
    Quantita,
    PrezzoUnitario,
    StatoArticolo
)
SELECT 
    @IDOrdineInserito,
    p.Marca,
    p.Modello,
    p.Misura,
    p.Codice,
    p.Quantita,
    p.PrezzoUnitario,
    'ORDINATO' -- Stato iniziale dopo l'invio dell'ordine
FROM #ProdottiDaOrdinare p;
*/

-- Visualizzazione dei risultati dell'ordine (debug)
SELECT * FROM #RisultatiOrdini;

-- Note importanti:
-- 1. È necessario abilitare xp_cmdshell per l'esecuzione di PowerShell
-- 2. Adattare i parametri JSON in base alle specifiche esatte dell'API
-- 3. Personalizzare i campi cliente, spedizione e prodotti in base ai dati reali
-- 4. Rimuovere i commenti dalle sezioni rilevanti per rendere lo script operativo 