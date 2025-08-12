-- ==============================================================================
-- EVENTI PNEUMATICO CON TABELLA DI APPOGGIO PER TRACCIAMENTO STATI
-- ==============================================================================

-- STEP 1: CREIAMO TABELLA TEMPORANEA PER L'ANAGRAFICA PNEUMATICI
IF OBJECT_ID('tempdb..#AnagraficaPneumatici') IS NOT NULL DROP TABLE #AnagraficaPneumatici;

CREATE TABLE #AnagraficaPneumatici (
    External_Id VARCHAR(255) PRIMARY KEY,
    IdVeicolo INTEGER,
    CodiceArticolo VARCHAR(100),
    IdArticolo INTEGER,
    DOT VARCHAR(10),
    DataPrimoMontaggio DATETIME,
    IdSchedaPrimoMontaggio INTEGER,
    StatoCorrente VARCHAR(20) DEFAULT 'MONTATO', -- MONTATO, DEPOSITATO, SMALTITO, PORTA_VIA
    UltimaDataMovimento DATETIME,
    UltimaSchedaMovimento INTEGER,
    TipoUltimoDeposito VARCHAR(50)
);

-- STEP 2: POPOLIAMO L'ANAGRAFICA CON TUTTI I PNEUMATICI
-- Pneumatici montati
INSERT INTO #AnagraficaPneumatici (External_Id, IdVeicolo, CodiceArticolo, IdArticolo, DOT, DataPrimoMontaggio, IdSchedaPrimoMontaggio)
SELECT 
    CAST(sl.S_IdVeicolo AS VARCHAR(10)) + '_' + 
    CAST(dw.ART_ID AS VARCHAR(10)) + '_' + 
    COALESCE(
        NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT, ''))), ''),
        FORMAT(DATEPART(week, DATEADD(day, -90, sl.Data_Lavori)), '00') + FORMAT(sl.Data_Lavori, 'yy')
    ) + '_' + CAST(sl.IdSchedaLavoro AS VARCHAR(10)) AS External_Id,
    sl.S_IdVeicolo,
    asl.Art_Codice,
    dw.ART_ID,
    COALESCE(
        NULLIF(LTRIM(RTRIM(ISNULL(asl.Art_DOT, ''))), ''),
        FORMAT(DATEPART(week, DATEADD(day, -90, sl.Data_Lavori)), '00') + FORMAT(sl.Data_Lavori, 'yy')
    ),
    sl.Data_Lavori,
    sl.IdSchedaLavoro
FROM SchedaLavoro sl
INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro  
INNER JOIN Ant_Descrittori_WebSmall dw ON asl.Art_Codice = dw.ART_CODICE
WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
  AND asl.Art_Fascia IN ('A','B','C','U','R');

-- Pneumatici solo deposito (anteriori)
INSERT INTO #AnagraficaPneumatici (External_Id, IdVeicolo, CodiceArticolo, IdArticolo, DOT, DataPrimoMontaggio, IdSchedaPrimoMontaggio, StatoCorrente)
SELECT 
    CAST(primo_deposito.D_IdVeicolo AS VARCHAR(10)) + '_' + CAST(dw.ART_ID AS VARCHAR(10)) + '_' + 
    COALESCE(
        NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito.D_DotAnt, ''))), ''),
        FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo.Data_Lavori)), '00') + FORMAT(sl_primo.Data_Lavori, 'yy')
    ) + '_' + CAST(primo_deposito.D_IdSchedaLavoro AS VARCHAR(10)) AS External_Id,
    primo_deposito.D_IdVeicolo,
    primo_deposito.D_ArtCodice,
    dw.ART_ID,
    COALESCE(
        NULLIF(LTRIM(RTRIM(ISNULL(primo_deposito.D_DotAnt, ''))), ''),
        FORMAT(DATEPART(week, DATEADD(day, -90, sl_primo.Data_Lavori)), '00') + FORMAT(sl_primo.Data_Lavori, 'yy')
    ),
    sl_primo.Data_Lavori,
    primo_deposito.D_IdSchedaLavoro,
    'DEPOSITATO'
FROM (
    SELECT d.D_IdVeicolo, d.D_ArtCodice, d.D_DotAnt, d.D_IdSchedaLavoro,
        ROW_NUMBER() OVER(PARTITION BY d.D_IdVeicolo, d.D_ArtCodice ORDER BY sl.Data_Lavori ASC) AS RankDeposito
    FROM Deposito d
    INNER JOIN SchedaLavoro sl ON sl.IdSchedaLavoro = d.D_IdSchedaLavoro
    WHERE d.D_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId) 
      AND d.D_IdSchedaLavoro > 0 
      AND d.D_ArtCodice IS NOT NULL
) primo_deposito
INNER JOIN SchedaLavoro sl_primo ON sl_primo.IdSchedaLavoro = primo_deposito.D_IdSchedaLavoro
INNER JOIN Ant_Descrittori_WebSmall dw ON primo_deposito.D_ArtCodice = dw.ART_CODICE
WHERE primo_deposito.RankDeposito = 1
  AND NOT EXISTS (
      SELECT 1 FROM SchedaLavoro sl_check
      INNER JOIN ArtSchedaLavoro asl_check ON asl_check.Art_IdSchedaLavoro = sl_check.IdSchedaLavoro
      WHERE sl_check.S_IdVeicolo = primo_deposito.D_IdVeicolo AND asl_check.Art_Codice = primo_deposito.D_ArtCodice
        AND asl_check.Art_Fascia IN ('A','B','C','U','R')
        AND sl_check.Data_Lavori < sl_primo.Data_Lavori
  );

-- STEP 3: CREIAMO TABELLA TEMPORANEA PER GLI EVENTI
IF OBJECT_ID('tempdb..#EventiPneumatici') IS NOT NULL DROP TABLE #EventiPneumatici;

CREATE TABLE #EventiPneumatici (
    External_Id_Pneumatico VARCHAR(255),
    External_Id_Evento VARCHAR(255),
    Tipo VARCHAR(20),
    Data_evento DATETIME,
    Km INTEGER,
    IdSchedaLavoro INTEGER,
    IdRigaSchedaLavoro INTEGER,
    Note VARCHAR(500),
    CodiceArticolo VARCHAR(100)
);

-- STEP 4: ELABORAZIONE CRONOLOGICA CON CURSOR
DECLARE @IdVeicolo INTEGER, @DataLavori DATETIME, @IdSchedaLavoro INTEGER, @Km INTEGER;
DECLARE @CodiceArticolo VARCHAR(100), @TipoDeposito VARCHAR(50), @IdRigaArticolo INTEGER, @TipoOperazione VARCHAR(20);
DECLARE @External_Id VARCHAR(255), @StatoCorrente VARCHAR(20);

-- Cursor per scorrere tutte le operazioni cronologicamente
DECLARE operazioni_cursor CURSOR FOR
SELECT 
    sl.S_IdVeicolo, sl.Data_Lavori, sl.IdSchedaLavoro, sl.Km,
    -- MONTAGGI DIRETTI
    asl.Art_Codice, NULL as TipoDeposito, asl.Id_Articoli, 'MONTAGGIO' as TipoOperazione
FROM SchedaLavoro sl
INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro
WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
  AND asl.Art_Fascia IN ('A','B','C','U','R')

UNION ALL

SELECT 
    sl.S_IdVeicolo, sl.Data_Lavori, sl.IdSchedaLavoro, sl.Km,
    -- SMONTAGGI
    d.D_ArtCodice, d.D_TipoDepositoR1, 
    (SELECT MIN(Id_Articoli) FROM ArtSchedaLavoro WHERE Art_IdSchedaLavoro = sl.IdSchedaLavoro),
    'SMONTAGGIO' as TipoOperazione
FROM SchedaLavoro sl
INNER JOIN Deposito d ON d.D_IdSchedaLavoro = sl.IdSchedaLavoro
WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
  AND d.D_ArtCodice IS NOT NULL

UNION ALL

SELECT 
    sl.S_IdVeicolo, sl.Data_Lavori, sl.IdSchedaLavoro, sl.Km,
    -- RIMONTAGGI DA DEPOSITO (Servizi stagionali che rimontano pneumatici)
    d_prev.D_ArtCodice, 'RIMONTAGGIO' as TipoDeposito,
    (SELECT MIN(Id_Articoli) FROM ArtSchedaLavoro WHERE Art_IdSchedaLavoro = sl.IdSchedaLavoro),
    'RIMONTAGGIO' as TipoOperazione
FROM SchedaLavoro sl
INNER JOIN ArtSchedaLavoro asl ON asl.Art_IdSchedaLavoro = sl.IdSchedaLavoro
INNER JOIN Deposito d_prev ON d_prev.D_IdVeicolo = sl.S_IdVeicolo 
    AND d_prev.Rimontate = 1 
    AND d_prev.Note LIKE '%-' + CAST(sl.IdSchedaLavoro AS VARCHAR) + '%'
WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
  AND asl.Art_Codice LIKE '%MS_STAG%'
  AND d_prev.D_ArtCodice IS NOT NULL

ORDER BY S_IdVeicolo, Data_Lavori, IdSchedaLavoro;

OPEN operazioni_cursor;
FETCH NEXT FROM operazioni_cursor INTO @IdVeicolo, @DataLavori, @IdSchedaLavoro, @Km, @CodiceArticolo, @TipoDeposito, @IdRigaArticolo, @TipoOperazione;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Cerchiamo il pneumatico nell'anagrafica
    SELECT @External_Id = External_Id, @StatoCorrente = StatoCorrente
    FROM #AnagraficaPneumatici 
    WHERE IdVeicolo = @IdVeicolo AND CodiceArticolo = @CodiceArticolo;
    
    -- Se pneumatico NON è smaltito, elaboriamo l'evento
    IF @StatoCorrente != 'SMALTITO'
    BEGIN
        -- GESTIONE MONTAGGIO
        IF @TipoDeposito IS NULL -- È un montaggio
        BEGIN
            INSERT INTO #EventiPneumatici VALUES (
                @External_Id,
                @External_Id + '_MONT_' + FORMAT(@DataLavori, 'yyyyMMddHHmmss'),
                'Montaggio',
                @DataLavori,
                @Km,
                @IdSchedaLavoro,
                @IdRigaArticolo,
                'Montaggio pneumatico ANTERIORE',
                @CodiceArticolo
            );
            
            -- Aggiorniamo stato
            UPDATE #AnagraficaPneumatici 
            SET StatoCorrente = 'MONTATO', UltimaDataMovimento = @DataLavori, UltimaSchedaMovimento = @IdSchedaLavoro
            WHERE External_Id = @External_Id;
        END
        
        -- GESTIONE SMONTAGGIO
        ELSE IF @TipoDeposito != 'RIMONTAGGIO' -- È uno smontaggio
        BEGIN
            INSERT INTO #EventiPneumatici VALUES (
                @External_Id,
                @External_Id + '_SMONT_' + FORMAT(@DataLavori, 'yyyyMMddHHmmss'),
                'Smontaggio',
                @DataLavori,
                @Km,
                @IdSchedaLavoro,
                @IdRigaArticolo,
                CASE 
                    WHEN @TipoDeposito LIKE '%Deposito%' THEN 'Smontaggio ANTERIORE per deposito stagionale'
                    WHEN @TipoDeposito LIKE '%finite%' THEN 'Smontaggio ANTERIORE per deposito (finite)'
                    WHEN @TipoDeposito LIKE '%Smaltite%' THEN 'Smontaggio ANTERIORE per smaltimento'
                    WHEN @TipoDeposito LIKE '%Porta Via%' THEN 'Smontaggio ANTERIORE porta via cliente'
                    ELSE 'Smontaggio ANTERIORE per ' + ISNULL(@TipoDeposito, 'deposito')
                END,
                @CodiceArticolo
            );
            
            -- Aggiorniamo stato secondo il tipo deposito
            UPDATE #AnagraficaPneumatici 
            SET StatoCorrente = CASE 
                    WHEN @TipoDeposito LIKE '%Smaltite%' THEN 'SMALTITO'
                    WHEN @TipoDeposito LIKE '%Porta Via%' THEN 'PORTA_VIA'  
                    ELSE 'DEPOSITATO'
                END,
                UltimaDataMovimento = @DataLavori, 
                UltimaSchedaMovimento = @IdSchedaLavoro,
                TipoUltimoDeposito = @TipoDeposito
            WHERE External_Id = @External_Id;
        END
        
        -- GESTIONE RIMONTAGGIO
        ELSE -- È un rimontaggio da deposito
        BEGIN
            INSERT INTO #EventiPneumatici VALUES (
                @External_Id,
                @External_Id + '_RIMONT_' + FORMAT(@DataLavori, 'yyyyMMddHHmmss'),
                'Rimontaggio',
                @DataLavori,
                @Km,
                @IdSchedaLavoro,
                @IdRigaArticolo,
                'Rimontaggio ANTERIORE da deposito (cambio stagionale)',
                @CodiceArticolo
            );
            
            -- Aggiorniamo stato
            UPDATE #AnagraficaPneumatici 
            SET StatoCorrente = 'MONTATO', UltimaDataMovimento = @DataLavori, UltimaSchedaMovimento = @IdSchedaLavoro
            WHERE External_Id = @External_Id;
        END
    END
    
    FETCH NEXT FROM operazioni_cursor INTO @IdVeicolo, @DataLavori, @IdSchedaLavoro, @Km, @CodiceArticolo, @TipoDeposito, @IdRigaArticolo, @TipoOperazione;
END

CLOSE operazioni_cursor;
DEALLOCATE operazioni_cursor;

-- STEP 5: RISULTATO FINALE
SELECT 
    External_Id_Pneumatico AS [Pneumatico__r:Pneumatico__c:External_Id__c],
    External_Id_Evento AS External_Id__c,
    Tipo AS Tipo__c,
    Data_evento AS Data_evento__c,
    Km AS Km_da_scheda_di_lavoro__c,
    IdSchedaLavoro AS [Scheda_di_lavoro__r:Commessa__c:External_ID__c],
    IdRigaSchedaLavoro AS [Riga_scheda_di_lavoro__r:ArticoliSchedaLavoro__c:External_ID__c],
    Note AS Note__c,
    CodiceArticolo
FROM #EventiPneumatici
ORDER BY Km, External_Id_Pneumatico, Data_evento;

-- STEP 6: PULIZIA
DROP TABLE #AnagraficaPneumatici;
DROP TABLE #EventiPneumatici;
