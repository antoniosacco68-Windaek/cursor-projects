-- Script T-SQL per chiamate API Franco Gomme - RICHIESTA DISPONIBILITÀ (INQUIRY)
-- Versione 1.0

-- Configurazione dei parametri di connessione
DECLARE @BaseUrl NVARCHAR(255) = 'https://ws.francogomme.it/wsFrancogommeTest/';
DECLARE @Username NVARCHAR(50) = 'B0logn4Test';
DECLARE @Password NVARCHAR(50) = 'B0logna#2025';
DECLARE @EndPoint NVARCHAR(20) = 'Inquiry';

-- Tabella temporanea per memorizzare i risultati
IF OBJECT_ID('tempdb..#RisultatiInquiry') IS NOT NULL
    DROP TABLE #RisultatiInquiry;

CREATE TABLE #RisultatiInquiry (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    DataChiamata DATETIME DEFAULT GETDATE(),
    EndpointChiamato NVARCHAR(255),
    ParametriInviati NVARCHAR(MAX),
    RispostaJSON NVARCHAR(MAX),
    StatoRisposta INT,
    MessaggioErrore NVARCHAR(MAX)
);

-- Tabella per memorizzare i prodotti da richiedere
IF OBJECT_ID('tempdb..#ProdottiDaRichiedere') IS NOT NULL
    DROP TABLE #ProdottiDaRichiedere;

CREATE TABLE #ProdottiDaRichiedere (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    Marca NVARCHAR(100),
    Modello NVARCHAR(100),
    Misura NVARCHAR(50),
    Quantita INT,
    Codice NVARCHAR(50)
);

-- Inserimento esempi di prodotti da richiedere (sostituire con dati reali)
INSERT INTO #ProdottiDaRichiedere (Marca, Modello, Misura, Quantita, Codice)
VALUES 
    ('MICHELIN', 'PILOT SPORT 4', '225/45R17 91Y', 4, '3528704855223'),
    ('PIRELLI', 'P ZERO', '245/40R18 97Y', 2, '8019227258097');

-- Preparazione del payload JSON per la richiesta di disponibilità
DECLARE @PowerShellCmd NVARCHAR(MAX);
DECLARE @JsonPayload NVARCHAR(MAX);
DECLARE @ProdottiJson NVARCHAR(MAX) = '';

-- Costruzione del JSON per i prodotti
SELECT @ProdottiJson = @ProdottiJson + 
    CASE WHEN @ProdottiJson = '' THEN '' ELSE ',' END +
    '{
        "brand": "' + Marca + '",
        "model": "' + Modello + '",
        "size": "' + Misura + '",
        "quantity": ' + CAST(Quantita AS NVARCHAR(10)) + ',
        "ean": "' + Codice + '"
    }'
FROM #ProdottiDaRichiedere;

-- Costruzione del payload JSON completo
SET @JsonPayload = N'{
    "username": "' + @Username + '",
    "password": "' + @Password + '",
    "requestData": {
        "requestId": "' + CONVERT(NVARCHAR(50), NEWID()) + '",
        "timestamp": "' + CONVERT(NVARCHAR(30), GETDATE(), 127) + '",
        "customer": {
            "id": "CLIENTEID123",
            "name": "Cliente Test SpA",
            "address": "Via Test 123",
            "city": "Bologna",
            "zip": "40100",
            "province": "BO",
            "country": "IT"
        },
        "delivery": {
            "type": "STANDARD",
            "date": "' + CONVERT(NVARCHAR(10), DATEADD(DAY, 3, GETDATE()), 23) + '"
        },
        "products": [' + @ProdottiJson + ']
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
INSERT INTO #RisultatiInquiry (EndpointChiamato, ParametriInviati, RispostaJSON, StatoRisposta, MessaggioErrore)
VALUES (@BaseUrl + @EndPoint, @JsonPayload, @RispostaAPI, @StatoRisposta, @MessaggioErrore);
*/

-- Tabella permanente per memorizzare le disponibilità (creazione se non esiste)
IF OBJECT_ID('dbo.DisponibilitaProdotti') IS NULL
BEGIN
    CREATE TABLE dbo.DisponibilitaProdotti (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        IDRichiesta NVARCHAR(100),
        DataRichiesta DATETIME DEFAULT GETDATE(),
        Marca NVARCHAR(100),
        Modello NVARCHAR(100),
        Misura NVARCHAR(50),
        Codice NVARCHAR(50),
        QuantitaRichiesta INT,
        QuantitaDisponibile INT,
        PrezzoUnitario DECIMAL(10,2),
        DataConsegnaStimata DATE,
        JsonRisposta NVARCHAR(MAX)
    );
END

-- Parsing ed elaborazione della risposta JSON (esempio - decommentare per usare)
/*
-- Estrazione dei dati dalla risposta JSON
WITH ProdottiJson AS (
    SELECT 
        JSON_VALUE(p.value, '$.brand') AS Marca,
        JSON_VALUE(p.value, '$.model') AS Modello,
        JSON_VALUE(p.value, '$.size') AS Misura,
        JSON_VALUE(p.value, '$.ean') AS Codice,
        CAST(JSON_VALUE(p.value, '$.requestedQuantity') AS INT) AS QuantitaRichiesta,
        CAST(JSON_VALUE(p.value, '$.availableQuantity') AS INT) AS QuantitaDisponibile,
        CAST(JSON_VALUE(p.value, '$.price') AS DECIMAL(10,2)) AS PrezzoUnitario,
        CAST(JSON_VALUE(p.value, '$.estimatedDeliveryDate') AS DATE) AS DataConsegnaStimata
    FROM #RisultatiInquiry
    CROSS APPLY OPENJSON(JSON_QUERY(RispostaJSON, '$.responseData.products')) AS p
    WHERE ID = SCOPE_IDENTITY()
)
-- Inserimento dei dati elaborati nella tabella permanente
INSERT INTO dbo.DisponibilitaProdotti (
    IDRichiesta,
    Marca,
    Modello, 
    Misura,
    Codice,
    QuantitaRichiesta,
    QuantitaDisponibile,
    PrezzoUnitario,
    DataConsegnaStimata,
    JsonRisposta
)
SELECT 
    JSON_VALUE(r.RispostaJSON, '$.responseData.requestId'),
    p.Marca,
    p.Modello,
    p.Misura,
    p.Codice,
    p.QuantitaRichiesta,
    p.QuantitaDisponibile,
    p.PrezzoUnitario,
    p.DataConsegnaStimata,
    r.RispostaJSON
FROM ProdottiJson p
CROSS JOIN #RisultatiInquiry r
WHERE r.ID = SCOPE_IDENTITY();
*/

-- Visualizzazione dei risultati della richiesta (debug)
SELECT * FROM #RisultatiInquiry;

-- Note importanti:
-- 1. È necessario abilitare xp_cmdshell per l'esecuzione di PowerShell
-- 2. Adattare i parametri JSON in base alle specifiche esatte dell'API
-- 3. Personalizzare i campi in base ai dati dei prodotti reali
-- 4. Rimuovere i commenti dalle sezioni rilevanti per rendere lo script operativo 