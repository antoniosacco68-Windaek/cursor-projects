-- ESEMPIO: COME LEGGERE E PROCESSARE IL JSON OTTENUTO DA POWERSHELL
-- Questo script legge il file JSON creato da ApiCaller.ps1

DECLARE @OutputFile NVARCHAR(500) = 'C:\temp\api_response.json';
DECLARE @JSON NVARCHAR(MAX);

-- === VERIFICA SE IL FILE ESISTE ===
DECLARE @FileExists TABLE (line NVARCHAR(4000));
DECLARE @Cmd NVARCHAR(1000) = 'if exist "' + @OutputFile + '" echo EXISTS else echo NOT_FOUND';
INSERT INTO @FileExists EXEC xp_cmdshell @Cmd;

IF EXISTS (SELECT * FROM @FileExists WHERE line = 'NOT_FOUND')
BEGIN
    PRINT 'ERRORE: File JSON non trovato: ' + @OutputFile;
    PRINT 'Esegui prima lo script Test Artico.sql per creare il file.';
    RETURN;
END

-- === LEGGI IL FILE JSON COMPLETO ===
SELECT @JSON = BulkColumn 
FROM OPENROWSET(BULK 'C:\temp\api_response.json', SINGLE_CLOB) as j;

PRINT 'File JSON letto con successo!';
PRINT 'Lunghezza: ' + CAST(LEN(@JSON) AS NVARCHAR) + ' caratteri';

-- === ANALISI STRUTTURA JSON ===
PRINT '';
PRINT '=== ANALISI STRUTTURA JSON ===';

-- Verifica se ha struttura paginata
IF CHARINDEX('"data":', @JSON) > 0 AND CHARINDEX('"paging":', @JSON) > 0
BEGIN
    PRINT 'Struttura: Risposta paginata con data e paging';
    
    -- Estrai info paginazione
    SELECT 
        JSON_VALUE(@JSON, '$.paging.pageno') as PaginaCorrente,
        JSON_VALUE(@JSON, '$.paging.pagesize') as ElementiPerPagina,
        JSON_VALUE(@JSON, '$.paging.pagecount') as TotalePagine,
        JSON_VALUE(@JSON, '$.paging.totalrecordcount') as TotaleRecord,
        JSON_VALUE(@JSON, '$.paging.moreresults') as AltriRisultati;
    
    -- === ESTRAI TUTTI GLI ARTICOLI ===
    PRINT '';
    PRINT '=== ARTICOLI ESTRATTI ===';
    
    SELECT 
        JSON_VALUE(value, '$.id') as ID,
        JSON_VALUE(value, '$.codice') as Codice,
        JSON_VALUE(value, '$.descr') as Descrizione,
        JSON_VALUE(value, '$.descr1') as DescrizioneEstesa,
        CAST(JSON_VALUE(value, '$.volume') as DECIMAL(10,4)) as Volume,
        CAST(JSON_VALUE(value, '$.netto') as DECIMAL(10,3)) as PrezzoNetto,
        CAST(JSON_VALUE(value, '$.lordo') as DECIMAL(10,2)) as PrezzoLordo,
        JSON_VALUE(value, '$.idmarche') as IDMarca,
        JSON_VALUE(value, '$.staart') as StatoArticolo
    FROM OPENJSON(@JSON, '$.data');
    
END
ELSE IF CHARINDEX('"id":', @JSON) > 0
BEGIN
    PRINT 'Struttura: Singolo articolo';
    
    -- Estrai dati singolo articolo
    SELECT 
        JSON_VALUE(@JSON, '$.id') as ID,
        JSON_VALUE(@JSON, '$.codice') as Codice,
        JSON_VALUE(@JSON, '$.descr') as Descrizione,
        JSON_VALUE(@JSON, '$.descr1') as DescrizioneEstesa,
        CAST(JSON_VALUE(@JSON, '$.volume') as DECIMAL(10,4)) as Volume,
        CAST(JSON_VALUE(@JSON, '$.netto') as DECIMAL(10,3)) as PrezzoNetto,
        CAST(JSON_VALUE(@JSON, '$.lordo') as DECIMAL(10,2)) as PrezzoLordo;
        
END
ELSE
BEGIN
    PRINT 'Struttura: Formato non riconosciuto';
    PRINT 'Prime 500 caratteri:';
    PRINT LEFT(@JSON, 500);
END

-- === ESEMPIO: INSERIMENTO IN TABELLA ===
PRINT '';
PRINT '=== ESEMPIO: CREAZIONE E POPOLAMENTO TABELLA ===';

-- Crea tabella temporanea (solo esempio)
IF OBJECT_ID('tempdb..#Articoli') IS NOT NULL DROP TABLE #Articoli;

CREATE TABLE #Articoli (
    ID INT,
    Codice NVARCHAR(100),
    Descrizione NVARCHAR(200),
    DescrizioneEstesa NVARCHAR(500),
    Volume DECIMAL(10,4),
    PrezzoNetto DECIMAL(10,3),
    PrezzoLordo DECIMAL(10,2),
    IDMarca INT,
    StatoArticolo NVARCHAR(10),
    DataImport DATETIME DEFAULT GETDATE()
);

-- Inserisci dati dalla risposta JSON
IF CHARINDEX('"data":', @JSON) > 0
BEGIN
    INSERT INTO #Articoli (ID, Codice, Descrizione, DescrizioneEstesa, Volume, PrezzoNetto, PrezzoLordo, IDMarca, StatoArticolo)
    SELECT 
        CAST(JSON_VALUE(value, '$.id') as INT),
        JSON_VALUE(value, '$.codice'),
        JSON_VALUE(value, '$.descr'),
        JSON_VALUE(value, '$.descr1'),
        CAST(JSON_VALUE(value, '$.volume') as DECIMAL(10,4)),
        CAST(JSON_VALUE(value, '$.netto') as DECIMAL(10,3)),
        CAST(JSON_VALUE(value, '$.lordo') as DECIMAL(10,2)),
        CAST(JSON_VALUE(value, '$.idmarche') as INT),
        JSON_VALUE(value, '$.staart')
    FROM OPENJSON(@JSON, '$.data');
    
    SELECT COUNT(*) as ArticoliInseriti FROM #Articoli;
    SELECT TOP 3 * FROM #Articoli ORDER BY ID;
    
END

-- === ESEMPI DI QUERY AVANZATE ===
PRINT '';
PRINT '=== ESEMPI QUERY AVANZATE ===';

-- Raggruppa per marca
PRINT 'Articoli per marca:';
SELECT IDMarca, COUNT(*) as NumeroArticoli, AVG(PrezzoNetto) as PrezzoMedio
FROM #Articoli 
WHERE IDMarca IS NOT NULL
GROUP BY IDMarca
ORDER BY NumeroArticoli DESC;

-- === CLEANUP ===
DROP TABLE #Articoli;

PRINT '';
PRINT '=== SCRIPT COMPLETATO ===';
PRINT 'Il JSON è stato letto e processato con successo!'; 