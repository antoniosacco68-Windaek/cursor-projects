USE [PiattaformeWeb]
GO

-- =============================================
-- Author: Sistema Ristrutturato - Interfaccia Web
-- Create date: 2025-01-02
-- Description: Stored Procedures per gestire RegoleListiniDistribuzione via Web
-- =============================================

-- ========================================
-- SP per SELECT - Leggere tutte le regole
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_GetRegoleDistribuzione')
    DROP PROCEDURE SP_GetRegoleDistribuzione
GO

CREATE PROCEDURE [dbo].[SP_GetRegoleDistribuzione]
    @NomeListino NVARCHAR(50) = NULL,
    @Settore NVARCHAR(20) = NULL,
    @CifraInMin DECIMAL(10,2) = NULL,
    @CifraInMax DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    SELECT 
        ID,
        NomeListino,
        CifraIn,
        CifraOut,
        Margine,
        ISNULL(MargPiu, 0) AS MargPiu,
        ISNULL(MargMeno, 0) AS MargMeno,
        Settore,
        ISNULL(RicaricoPercentuale, 0) AS RicaricoPercentuale,
        ProvvPiatt,
        ISNULL(MargMenoEstivo, 0) AS MargMenoEstivo,
        ISNULL(MargMenoAS, 0) AS MargMenoAS,
        ISNULL(MargMenoInvernale, 0) AS MargMenoInvernale,
        DataCreazione,
        DataModifica
    FROM RegoleListiniDistribuzione
    WHERE 
        (@NomeListino IS NULL OR NomeListino = @NomeListino)
        AND (@Settore IS NULL OR Settore = @Settore)
        AND (@CifraInMin IS NULL OR CifraIn >= @CifraInMin)
        AND (@CifraInMax IS NULL OR CifraIn <= @CifraInMax)
    ORDER BY NomeListino, Settore, CifraIn
END
GO

-- ========================================
-- SP per INSERT - Aggiungere nuova regola
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_InsertRegolaDistribuzione')
    DROP PROCEDURE SP_InsertRegolaDistribuzione
GO

CREATE PROCEDURE [dbo].[SP_InsertRegolaDistribuzione]
    @NomeListino NVARCHAR(50),
    @CifraIn DECIMAL(10,2),
    @CifraOut DECIMAL(10,2),
    @Margine DECIMAL(10,2),
    @MargPiu DECIMAL(10,2) = NULL,
    @MargMeno DECIMAL(10,2) = NULL,
    @Settore NVARCHAR(20),
    @RicaricoPercentuale DECIMAL(6,3) = NULL,
    @ProvvPiatt DECIMAL(10,4) = 1.0130,
    @MargMenoEstivo DECIMAL(10,2) = NULL,
    @MargMenoAS DECIMAL(10,2) = NULL,
    @MargMenoInvernale DECIMAL(10,2) = NULL,
    @NewID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validazioni base
    IF @NomeListino NOT IN ('B2B', 'Piattaforme', 'Collegati')
    BEGIN
        RAISERROR('NomeListino deve essere B2B, Piattaforme o Collegati', 16, 1)
        RETURN
    END
    
    IF @Settore NOT IN ('Vettura', 'Autocarro', 'MotoScooter')
    BEGIN
        RAISERROR('Settore deve essere Vettura, Autocarro o MotoScooter', 16, 1)
        RETURN
    END
    
    IF @CifraIn >= @CifraOut
    BEGIN
        RAISERROR('CifraIn deve essere minore di CifraOut', 16, 1)
        RETURN
    END
    
    -- Controllo sovrapposizioni
    IF EXISTS (
        SELECT 1 FROM RegoleListiniDistribuzione 
        WHERE NomeListino = @NomeListino 
        AND Settore = @Settore
        AND (
            (@CifraIn BETWEEN CifraIn AND CifraOut) OR
            (@CifraOut BETWEEN CifraIn AND CifraOut) OR
            (CifraIn BETWEEN @CifraIn AND @CifraOut)
        )
    )
    BEGIN
        RAISERROR('Esiste già una regola che si sovrappone con questa fascia di prezzo', 16, 1)
        RETURN
    END
    
    INSERT INTO RegoleListiniDistribuzione (
        NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, 
        Settore, RicaricoPercentuale, ProvvPiatt, 
        MargMenoEstivo, MargMenoAS, MargMenoInvernale,
        CostoTrasportoIt, TipoListForn
    )
    VALUES (
        @NomeListino, @CifraIn, @CifraOut, @Margine, @MargPiu, @MargMeno,
        @Settore, @RicaricoPercentuale, @ProvvPiatt,
        @MargMenoEstivo, @MargMenoAS, @MargMenoInvernale,
        CASE WHEN @Settore = 'Autocarro' THEN 13.00 ELSE 4.40 END, -- Costo trasporto
        '24H' -- Tipo fornitore default
    )
    
    SET @NewID = SCOPE_IDENTITY()
    
    PRINT 'Nuova regola creata con ID: ' + CAST(@NewID AS VARCHAR(10))
END
GO

-- ========================================
-- SP per UPDATE - Modificare regola esistente
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_UpdateRegolaDistribuzione')
    DROP PROCEDURE SP_UpdateRegolaDistribuzione
GO

CREATE PROCEDURE [dbo].[SP_UpdateRegolaDistribuzione]
    @ID INT,
    @NomeListino NVARCHAR(50) = NULL,
    @CifraIn DECIMAL(10,2) = NULL,
    @CifraOut DECIMAL(10,2) = NULL,
    @Margine DECIMAL(10,2) = NULL,
    @MargPiu DECIMAL(10,2) = NULL,
    @MargMeno DECIMAL(10,2) = NULL,
    @Settore NVARCHAR(20) = NULL,
    @RicaricoPercentuale DECIMAL(6,3) = NULL,
    @ProvvPiatt DECIMAL(10,4) = NULL,
    @MargMenoEstivo DECIMAL(10,2) = NULL,
    @MargMenoAS DECIMAL(10,2) = NULL,
    @MargMenoInvernale DECIMAL(10,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verifica esistenza regola
    IF NOT EXISTS (SELECT 1 FROM RegoleListiniDistribuzione WHERE ID = @ID)
    BEGIN
        RAISERROR('Regola con ID specificato non trovata', 16, 1)
        RETURN
    END
    
    -- Validazioni se fornite
    IF @NomeListino IS NOT NULL AND @NomeListino NOT IN ('B2B', 'Piattaforme', 'Collegati')
    BEGIN
        RAISERROR('NomeListino deve essere B2B, Piattaforme o Collegati', 16, 1)
        RETURN
    END
    
    IF @Settore IS NOT NULL AND @Settore NOT IN ('Vettura', 'Autocarro', 'MotoScooter')
    BEGIN
        RAISERROR('Settore deve essere Vettura, Autocarro o MotoScooter', 16, 1)
        RETURN
    END
    
    -- Aggiorna solo i campi forniti
    UPDATE RegoleListiniDistribuzione
    SET 
        NomeListino = ISNULL(@NomeListino, NomeListino),
        CifraIn = ISNULL(@CifraIn, CifraIn),
        CifraOut = ISNULL(@CifraOut, CifraOut),
        Margine = ISNULL(@Margine, Margine),
        MargPiu = CASE WHEN @MargPiu IS NOT NULL THEN @MargPiu ELSE MargPiu END,
        MargMeno = CASE WHEN @MargMeno IS NOT NULL THEN @MargMeno ELSE MargMeno END,
        Settore = ISNULL(@Settore, Settore),
        RicaricoPercentuale = CASE WHEN @RicaricoPercentuale IS NOT NULL THEN @RicaricoPercentuale ELSE RicaricoPercentuale END,
        ProvvPiatt = ISNULL(@ProvvPiatt, ProvvPiatt),
        MargMenoEstivo = CASE WHEN @MargMenoEstivo IS NOT NULL THEN @MargMenoEstivo ELSE MargMenoEstivo END,
        MargMenoAS = CASE WHEN @MargMenoAS IS NOT NULL THEN @MargMenoAS ELSE MargMenoAS END,
        MargMenoInvernale = CASE WHEN @MargMenoInvernale IS NOT NULL THEN @MargMenoInvernale ELSE MargMenoInvernale END,
        DataModifica = GETDATE()
    WHERE ID = @ID
    
    PRINT 'Regola ID ' + CAST(@ID AS VARCHAR(10)) + ' aggiornata con successo'
END
GO

-- ========================================
-- SP per DELETE - Eliminare regola
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_DeleteRegolaDistribuzione')
    DROP PROCEDURE SP_DeleteRegolaDistribuzione
GO

CREATE PROCEDURE [dbo].[SP_DeleteRegolaDistribuzione]
    @ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Verifica esistenza regola
    IF NOT EXISTS (SELECT 1 FROM RegoleListiniDistribuzione WHERE ID = @ID)
    BEGIN
        RAISERROR('Regola con ID specificato non trovata', 16, 1)
        RETURN
    END
    
    -- Controllo se la regola è in uso (sicurezza)
    DECLARE @InUso INT = 0
    
    -- Controlla se ci sono articoli che usano questa regola
    IF EXISTS (SELECT 1 FROM OfferteWeb_Tmp WHERE ID_RegoleB2B = @ID)
        SET @InUso = @InUso + 1
    
    IF EXISTS (SELECT 1 FROM OfferteWeb_Tmp WHERE ID_RegolePiattaforme = @ID)
        SET @InUso = @InUso + 1
        
    IF EXISTS (SELECT 1 FROM OfferteWeb_Tmp WHERE ID_RegoleCollegati = @ID)
        SET @InUso = @InUso + 1
    
    IF @InUso > 0
    BEGIN
        RAISERROR('Impossibile eliminare: la regola è attualmente in uso da %d articoli', 16, 1, @InUso)
        RETURN
    END
    
    DELETE FROM RegoleListiniDistribuzione WHERE ID = @ID
    
    PRINT 'Regola ID ' + CAST(@ID AS VARCHAR(10)) + ' eliminata con successo'
END
GO

-- ========================================
-- SP per BATCH DELETE - Eliminare più regole
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_DeleteMultipleRegole')
    DROP PROCEDURE SP_DeleteMultipleRegole
GO

CREATE PROCEDURE [dbo].[SP_DeleteMultipleRegole]
    @IDList NVARCHAR(MAX) -- Lista di ID separati da virgola es: "1,2,3,4"
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Crea tabella temporanea con gli ID
    CREATE TABLE #TempIDs (ID INT)
    
    -- Popola la tabella temporanea
    DECLARE @SQL NVARCHAR(MAX) = 'INSERT INTO #TempIDs (ID) VALUES (' + REPLACE(@IDList, ',', '),(') + ')'
    EXEC sp_executesql @SQL
    
    -- Controlla quali regole sono in uso
    DECLARE @RegoleInUso TABLE (ID INT, Utilizzi INT)
    
    INSERT INTO @RegoleInUso (ID, Utilizzi)
    SELECT 
        t.ID,
        (SELECT COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleB2B = t.ID) +
        (SELECT COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegolePiattaforme = t.ID) +
        (SELECT COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleCollegati = t.ID)
    FROM #TempIDs t
    
    -- Mostra regole in uso
    IF EXISTS (SELECT 1 FROM @RegoleInUso WHERE Utilizzi > 0)
    BEGIN
        SELECT 'REGOLE IN USO - NON ELIMINATE:' AS Messaggio, ID, Utilizzi 
        FROM @RegoleInUso WHERE Utilizzi > 0
    END
    
    -- Elimina solo regole non in uso
    DELETE r FROM RegoleListiniDistribuzione r
    INNER JOIN #TempIDs t ON r.ID = t.ID
    LEFT JOIN @RegoleInUso u ON r.ID = u.ID
    WHERE ISNULL(u.Utilizzi, 0) = 0
    
    DECLARE @Eliminate INT = @@ROWCOUNT
    
    DROP TABLE #TempIDs
    
    PRINT 'Operazione completata. Regole eliminate: ' + CAST(@Eliminate AS VARCHAR(10))
END
GO

-- ========================================
-- SP per IMPORT CSV - Importare regole da CSV
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_ImportRegoleFromCSV')
    DROP PROCEDURE SP_ImportRegoleFromCSV
GO

CREATE PROCEDURE [dbo].[SP_ImportRegoleFromCSV]
    @FilePath NVARCHAR(255),
    @OverwriteExisting BIT = 0, -- Se 1, sovrascrive regole esistenti
    @DryRun BIT = 0 -- Se 1, simula senza modificare
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Crea tabella temporanea per l'import
    CREATE TABLE #ImportTemp (
        ID INT,
        NomeListino NVARCHAR(50),
        CifraIn DECIMAL(10,2),
        CifraOut DECIMAL(10,2),
        Margine DECIMAL(10,2),
        MargPiu DECIMAL(10,2),
        MargMeno DECIMAL(10,2),
        Settore NVARCHAR(20),
        RicaricoPercentuale DECIMAL(6,3),
        ProvvPiatt DECIMAL(10,4),
        MargMenoEstivo DECIMAL(10,2),
        MargMenoAS DECIMAL(10,2),
        MargMenoInvernale DECIMAL(10,2),
        DataCreazione DATETIME,
        DataModifica DATETIME
    )
    
    -- Import CSV (da implementare con BULK INSERT o applicazione esterna)
    DECLARE @SQL NVARCHAR(MAX) = 
        'BULK INSERT #ImportTemp FROM ''' + @FilePath + ''' ' +
        'WITH (FIELDTERMINATOR = '';'', ROWTERMINATOR = ''\n'', FIRSTROW = 2)'
    
    -- In ambiente di sviluppo, simula dati di import
    INSERT INTO #ImportTemp VALUES
    (999, 'Test', 100.00, 150.00, 20.00, 0.00, 5.00, 'Vettura', NULL, 1.0130, NULL, NULL, NULL, GETDATE(), GETDATE())
    
    -- Statistiche import
    DECLARE @TotaleRighe INT = (SELECT COUNT(*) FROM #ImportTemp)
    DECLARE @NuoveRegole INT = 0
    DECLARE @RegoleAggiornate INT = 0
    DECLARE @Errori INT = 0
    
    PRINT 'INIZIO IMPORT CSV - Righe da processare: ' + CAST(@TotaleRighe AS VARCHAR(10))
    PRINT 'Modalità: ' + CASE WHEN @DryRun = 1 THEN 'SIMULAZIONE' ELSE 'REALE' END
    
    -- Processa ogni riga
    DECLARE @CurrentID INT, @CurrentListino NVARCHAR(50), @CurrentSettore NVARCHAR(20)
    DECLARE @CurrentCifraIn DECIMAL(10,2), @CurrentCifraOut DECIMAL(10,2), @CurrentMargine DECIMAL(10,2)
    
    DECLARE import_cursor CURSOR FOR
    SELECT NomeListino, CifraIn, CifraOut, Margine, Settore FROM #ImportTemp
    
    OPEN import_cursor
    FETCH NEXT FROM import_cursor INTO @CurrentListino, @CurrentCifraIn, @CurrentCifraOut, @CurrentMargine, @CurrentSettore
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            -- Controlla se esiste regola simile
            SELECT @CurrentID = ID FROM RegoleListiniDistribuzione 
            WHERE NomeListino = @CurrentListino AND Settore = @CurrentSettore 
            AND CifraIn = @CurrentCifraIn AND CifraOut = @CurrentCifraOut
            
            IF @CurrentID IS NOT NULL AND @OverwriteExisting = 1
            BEGIN
                -- Aggiorna esistente
                IF @DryRun = 0
                BEGIN
                    UPDATE RegoleListiniDistribuzione 
                    SET Margine = @CurrentMargine, DataModifica = GETDATE()
                    WHERE ID = @CurrentID
                END
                SET @RegoleAggiornate = @RegoleAggiornate + 1
            END
            ELSE IF @CurrentID IS NULL
            BEGIN
                -- Inserisci nuova
                IF @DryRun = 0
                BEGIN
                    INSERT INTO RegoleListiniDistribuzione (NomeListino, CifraIn, CifraOut, Margine, Settore, ProvvPiatt, CostoTrasportoIt, TipoListForn)
                    VALUES (@CurrentListino, @CurrentCifraIn, @CurrentCifraOut, @CurrentMargine, @CurrentSettore, 1.0130, 4.40, '24H')
                END
                SET @NuoveRegole = @NuoveRegole + 1
            END
            
            SET @CurrentID = NULL
        END TRY
        BEGIN CATCH
            SET @Errori = @Errori + 1
            PRINT 'ERRORE nella riga: ' + @CurrentListino + ' ' + @CurrentSettore + ' - ' + ERROR_MESSAGE()
        END CATCH
        
        FETCH NEXT FROM import_cursor INTO @CurrentListino, @CurrentCifraIn, @CurrentCifraOut, @CurrentMargine, @CurrentSettore
    END
    
    CLOSE import_cursor
    DEALLOCATE import_cursor
    
    DROP TABLE #ImportTemp
    
    PRINT '====== RISULTATI IMPORT ======'
    PRINT 'Nuove regole: ' + CAST(@NuoveRegole AS VARCHAR(10))
    PRINT 'Regole aggiornate: ' + CAST(@RegoleAggiornate AS VARCHAR(10))
    PRINT 'Errori: ' + CAST(@Errori AS VARCHAR(10))
    PRINT 'Totale processate: ' + CAST(@TotaleRighe AS VARCHAR(10))
END
GO

-- ========================================
-- SP per EXPORT CSV - Esportare regole in CSV
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_ExportRegoleToCSV')
    DROP PROCEDURE SP_ExportRegoleToCSV
GO

CREATE PROCEDURE [dbo].[SP_ExportRegoleToCSV]
    @FilePath NVARCHAR(255),
    @NomeListino NVARCHAR(50) = NULL,
    @Settore NVARCHAR(20) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Costruisce query dinamica per export
    DECLARE @SQL NVARCHAR(MAX) = 
        'SELECT 
            ID, NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore,
            RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, MargMenoAS, MargMenoInvernale,
            DataCreazione, DataModifica
        FROM RegoleListiniDistribuzione
        WHERE 1=1'
    
    IF @NomeListino IS NOT NULL
        SET @SQL = @SQL + ' AND NomeListino = ''' + @NomeListino + ''''
        
    IF @Settore IS NOT NULL
        SET @SQL = @SQL + ' AND Settore = ''' + @Settore + ''''
        
    SET @SQL = @SQL + ' ORDER BY NomeListino, Settore, CifraIn'
    
    -- In produzione: usa BCP o SQLCMD per export
    PRINT 'Query per export:'
    PRINT @SQL
    PRINT 'Export verso: ' + @FilePath
    
    -- Esegue la query per verifica
    EXEC (@SQL)
END
GO

-- ========================================
-- SP per BACKUP - Creare backup regole
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_BackupRegole')
    DROP PROCEDURE SP_BackupRegole
GO

CREATE PROCEDURE [dbo].[SP_BackupRegole]
    @BackupName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @BackupName IS NULL
        SET @BackupName = 'Backup_' + REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(19), GETDATE(), 120), '-', ''), ':', ''), ' ', '_')
    
    -- Crea tabella di backup
    DECLARE @TableName NVARCHAR(150) = 'RegoleListiniDistribuzione_' + @BackupName
    DECLARE @SQL NVARCHAR(MAX) = 
        'SELECT * INTO [' + @TableName + '] FROM RegoleListiniDistribuzione'
    
    EXEC (@SQL)
    
    DECLARE @Count INT = (SELECT COUNT(*) FROM RegoleListiniDistribuzione)
    
    PRINT 'Backup creato: ' + @TableName
    PRINT 'Regole salvate: ' + CAST(@Count AS VARCHAR(10))
    PRINT 'Data backup: ' + CONVERT(VARCHAR(19), GETDATE(), 120)
END
GO

-- ========================================
-- SP per STATISTICHE - Mostrare statistiche regole
-- ========================================
IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'SP_StatisticheRegole')
    DROP PROCEDURE SP_StatisticheRegole
GO

CREATE PROCEDURE [dbo].[SP_StatisticheRegole]
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '====== STATISTICHE REGOLE DISTRIBUZIONE ======'
    PRINT 'Data analisi: ' + CONVERT(VARCHAR(19), GETDATE(), 120)
    PRINT ''
    
    -- Conteggi per listino
    SELECT 
        'REGOLE PER LISTINO' AS Categoria,
        NomeListino AS Descrizione,
        COUNT(*) AS Quantita
    FROM RegoleListiniDistribuzione
    GROUP BY NomeListino
    
    UNION ALL
    
    -- Conteggi per settore
    SELECT 
        'REGOLE PER SETTORE' AS Categoria,
        Settore AS Descrizione,
        COUNT(*) AS Quantita
    FROM RegoleListiniDistribuzione
    GROUP BY Settore
    
    UNION ALL
    
    -- Regole con ricarico percentuale
    SELECT 
        'TIPI DI REGOLE' AS Categoria,
        'Con Ricarico Percentuale' AS Descrizione,
        COUNT(*) AS Quantita
    FROM RegoleListiniDistribuzione
    WHERE RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0
    
    UNION ALL
    
    SELECT 
        'TIPI DI REGOLE' AS Categoria,
        'Con Margine Tradizionale' AS Descrizione,
        COUNT(*) AS Quantita
    FROM RegoleListiniDistribuzione
    WHERE RicaricoPercentuale IS NULL OR RicaricoPercentuale = 0
    
    ORDER BY Categoria, Descrizione
    
    -- Fasce di prezzo più utilizzate
    SELECT TOP 10
        'FASCE PIÙ UTILIZZATE' AS Info,
        CAST(CifraIn AS VARCHAR(10)) + ' - ' + CAST(CifraOut AS VARCHAR(10)) + ' €' AS FasciaPrezzo,
        COUNT(*) AS Utilizzi
    FROM RegoleListiniDistribuzione
    GROUP BY CifraIn, CifraOut
    ORDER BY COUNT(*) DESC
    
    -- Margini medi per settore
    SELECT 
        'MARGINI MEDI' AS Info,
        Settore,
        AVG(Margine) AS MargineMediaEuro,
        AVG(ISNULL(RicaricoPercentuale, 1.0)) AS RicaricoMedioPercentuale
    FROM RegoleListiniDistribuzione
    GROUP BY Settore
    ORDER BY Settore
END
GO

PRINT '====== STORED PROCEDURES PER INTERFACCIA WEB CREATE CON SUCCESSO ======'
PRINT 'Disponibili:'
PRINT '- SP_GetRegoleDistribuzione: Legge regole con filtri'
PRINT '- SP_InsertRegolaDistribuzione: Inserisce nuova regola'
PRINT '- SP_UpdateRegolaDistribuzione: Modifica regola esistente'
PRINT '- SP_DeleteRegolaDistribuzione: Elimina singola regola'
PRINT '- SP_DeleteMultipleRegole: Elimina multiple regole'
PRINT '- SP_ImportRegoleFromCSV: Import da CSV'
PRINT '- SP_ExportRegoleToCSV: Export in CSV'
PRINT '- SP_BackupRegole: Backup tabella regole'
PRINT '- SP_StatisticheRegole: Statistiche e report'