-- Script T-SQL per chiamate API Franco Gomme
-- Versione 1.0

-- Configurazione dei parametri di connessione
DECLARE @BaseUrl NVARCHAR(255) = 'https://ws.francogomme.it/wsFrancogommeTest/';
DECLARE @Username NVARCHAR(50) = 'B0logn4Test';
DECLARE @Password NVARCHAR(50) = 'B0logna#2025';
DECLARE @TipoChiamata NVARCHAR(20) = 'Inquiry'; -- Alternativa: 'OrderB2'

-- Tabella temporanea per memorizzare i risultati
IF OBJECT_ID('tempdb..#RisultatiAPI') IS NOT NULL
    DROP TABLE #RisultatiAPI;

CREATE TABLE #RisultatiAPI (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    DataChiamata DATETIME DEFAULT GETDATE(),
    EndpointChiamato NVARCHAR(255),
    ParametriInviati NVARCHAR(MAX),
    RispostaJSON NVARCHAR(MAX),
    StatoRisposta INT,
    MessaggioErrore NVARCHAR(MAX)
);

-- Procedura per eseguire la chiamata API tramite CLR o xp_cmdshell con PowerShell
-- Nota: Questa parte richiede l'abilitazione di xp_cmdshell o l'implementazione di assembly CLR

-- Esempio di utilizzo di xp_cmdshell con PowerShell
DECLARE @PowerShellCmd NVARCHAR(MAX);
DECLARE @JsonPayload NVARCHAR(MAX);

-- Preparazione del payload JSON per la richiesta (esempio)
SET @JsonPayload = N'{
    "username": "' + @Username + '",
    "password": "' + @Password + '",
    "requestData": {
        "requestId": "' + CONVERT(NVARCHAR(50), NEWID()) + '",
        "timestamp": "' + CONVERT(NVARCHAR(30), GETDATE(), 127) + '"
        -- Altri parametri specifici in base alla documentazione
    }
}';

-- Costruzione del comando PowerShell
SET @PowerShellCmd = N'powershell.exe -Command "
    $headers = @{''Content-Type'' = ''application/json''}
    $uri = ''' + @BaseUrl + @TipoChiamata + '''
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

-- Esecuzione del comando PowerShell (commentato - necessita di xp_cmdshell abilitato)
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
INSERT INTO #RisultatiAPI (EndpointChiamato, ParametriInviati, RispostaJSON, StatoRisposta, MessaggioErrore)
VALUES (@BaseUrl + @TipoChiamata, @JsonPayload, @RispostaAPI, @StatoRisposta, @MessaggioErrore);
*/

-- Esempio di elaborazione della risposta JSON (utilizzando JSON_VALUE in SQL Server 2016+)
/*
DECLARE @IdOrdine NVARCHAR(50);
DECLARE @StatoOrdine NVARCHAR(50);

SELECT
    @IdOrdine = JSON_VALUE(RispostaJSON, '$.orderId'),
    @StatoOrdine = JSON_VALUE(RispostaJSON, '$.status')
FROM #RisultatiAPI
WHERE ID = SCOPE_IDENTITY();

-- Inserimento dei dati elaborati in una tabella permanente
INSERT INTO OrdiniFornitore (IdOrdine, Fornitore, StatoOrdine, DataInserimento, JsonCompleto)
VALUES (@IdOrdine, 'FrancoGomme', @StatoOrdine, GETDATE(), @RispostaAPI);
*/

-- Visualizzazione dei risultati (debug)
SELECT * FROM #RisultatiAPI;

-- Note importanti:
-- 1. È necessario abilitare xp_cmdshell per l'esecuzione di PowerShell o implementare un assembly CLR
-- 2. Adattare i parametri JSON in base alle specifiche dell'API documentate
-- 3. Aggiungere gestione errori appropriata
-- 4. Modificare il parsing della risposta in base al formato effettivo dei dati
