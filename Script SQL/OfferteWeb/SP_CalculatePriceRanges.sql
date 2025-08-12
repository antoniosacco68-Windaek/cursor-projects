USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[SP_CalculatePriceRanges]    Script Date: 23/06/2025 14:46:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_CalculatePriceRanges] -- 01 
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SettVettura varchar(20) = '(4,6,7,37,76)'
    DECLARE @SettAutocarro varchar(20) = '(8)'
    DECLARE @SettMotoScoot varchar(20) = '(16,91)'
    DECLARE @Sql varchar(2000)
    
    PRINT 'Inizio calcolo fasce di prezzo e assegnazione regole...'
    
    -- Copio i dati da OfferteWeb_1Pass a OfferteWeb_Tmp per il nuovo sistema
    TRUNCATE TABLE OfferteWeb_Tmp
    
    INSERT INTO OfferteWeb_Tmp
		(IdArtico, CodiceArticolo, CodArtForn, CodArtPiatt, DescrB2b, IdFornitore, Qta, Prezzo, PrezzoMan, Posizione, PosGlobale, Settore, SettList, SettoreId, Diametro, Produttore, MarcaId, Stagione, Misura, Peso, DOT_Forn, CodMagForn, Descr_Piatt, P_Std, P_StdBo, M_Base, C_TraspBase, C_TraspBaseBo, Note_Std, OrderB2b, P_T24_24H, P_T24_48H, P_T24_72H, P_T24_GER, P_T24_SPA, P_T24_AUS, P_T24_FRA, P_T24_BEL, P_T24_LUS, P_T24_OLA, P_T24_POL, P_T24_Uk_Danim, M_T24, [M-T24], [M+T24], C_TraspT24, Provv_PiattT24, PosT24, Note_T24, P_Collegati, P_Collegati_GER, P_Collegati_SPA, P_Collegati_AUS, P_Collegati_FRA, P_Collegati_BEL, P_Collegati_LUS, P_Collegati_OLA, P_Collegati_POL, P_Collegati_UK, M_Collegati, C_TraspCollegati, Note_Collegati, C_PesoGerFra, C_PesoSpa, C_PesoAust, C_PesoT24, P_Prec_T24, P_1Pos_T24, Diff_T24, P_Min_T24, P_Max_T24, P_Ricalc_T24, PosPrec_T24, Note_T24_Rank, Differenza, Eccezzioni, Note_Base, TipoPubPiatt, PosEsteri)
    SELECT
	IdArtico, CodiceArticolo, CodArtForn, CodArtPiatt, DescrB2b, IdFornitore, Qta, Prezzo, PrezzoMan, Posizione, PosGlobale, Settore, SettList, SettoreId, Diametro, Produttore, MarcaId, Stagione, Misura, Peso, DOT_Forn, CodMagForn, Descr_Piatt, P_Std, P_StdBo, M_Base, C_TraspBase, C_TraspBaseBo, Note_Std, OrderB2b, P_T24_24H, P_T24_48H, P_T24_72H, P_T24_GER, P_T24_SPA, P_T24_AUS, P_T24_FRA, P_T24_BEL, P_T24_LUS, P_T24_OLA, P_T24_POL, P_T24_Uk_Danim, M_T24, [M-T24], [M+T24], C_TraspT24, Provv_PiattT24, PosT24, Note_T24, NULL, P_Esteri_Ger, P_Esteri_Spa, P_Esteri_Aus, P_T24_FRA, P_T24_BEL, P_T24_LUS, P_T24_OLA, P_T24_POL, P_T24_Uk_Danim, M_T24, NULL	, NULL	, C_PesoGerFra, C_PesoSpa, C_PesoAust, C_PesoT24, P_Prec_T24, P_1Pos_T24, Diff_T24, P_Min_T24, P_Max_T24, P_Ricalc_T24, PosPrec_T24, Note_T24_Rank, Differenza, Eccezzioni, Note_Base, TipoPubPiatt,PosEsteri
	FROM OfferteWeb_1Pass
    
    PRINT 'Copiati ' + CAST(@@ROWCOUNT AS VARCHAR(10)) + ' articoli in OfferteWeb_Tmp'
    
    -- Reset dei campi di calcolo per il nuovo sistema
    UPDATE OfferteWeb_Tmp
    SET 
        -- Campi B2B
        M_Base = NULL, C_TraspBase = NULL, C_TraspBaseBo = NULL,
        P_Std = NULL, P_StdBo = NULL, Note_Std = NULL,
        
        -- Campi Piattaforme 
        M_T24 = NULL, C_TraspT24 = NULL, [M-T24] = NULL, [M+T24] = NULL,
        P_T24_24H = NULL, P_T24_48H = NULL, P_T24_72H = NULL,
        P_T24_GER = NULL, P_T24_SPA = NULL, P_T24_AUS = NULL,
        P_T24_FRA = NULL, P_T24_BEL = NULL, P_T24_LUS = NULL,
        P_T24_OLA = NULL, P_T24_POL = NULL, P_T24_Uk_Danim = NULL,
        Note_T24 = NULL,
        
        -- Campi Collegati
        P_Collegati = NULL, P_Collegati_GER = NULL, P_Collegati_SPA = NULL,
        P_Collegati_AUS = NULL, P_Collegati_FRA = NULL, P_Collegati_BEL = NULL,
        P_Collegati_LUS = NULL, P_Collegati_OLA = NULL, P_Collegati_POL = NULL,
        P_Collegati_UK = NULL, M_Collegati = NULL, C_TraspCollegati = NULL,
        Note_Collegati = NULL,
        
        -- Reset campi di riferimento ID regole (NUOVO SISTEMA)
        ID_RegoleB2B = NULL, ID_RegolePiattaforme = NULL, ID_RegoleCollegati = NULL,
        
        -- Campi comune
        Provv_PiattT24 = NULL, SettList = NULL
    
    PRINT 'Reset campi completato.'
    
    -- ========================================
    -- ASSEGNAZIONE REGOLE LISTINO B2B
    -- ========================================
    
    PRINT 'Assegnazione regole B2B - Settore Vettura...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleB2B = RegoleListiniDistribuzione.ID,
        SettList = ''Vettura''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettVettura + ' 
    AND RegoleListiniDistribuzione.Settore = ''Vettura'' 
    WHERE NomeListino = ''B2B'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole B2B - Settore Autocarro...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleB2B = RegoleListiniDistribuzione.ID,
        SettList = ''Autocarro''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Diametro BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettAutocarro + ' 
    AND RegoleListiniDistribuzione.Settore = ''Autocarro'' 
    WHERE NomeListino = ''B2B'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole B2B - Settore MotoScooter...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleB2B = RegoleListiniDistribuzione.ID,
        SettList = ''MotoScooter''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettMotoScoot + ' 
    AND RegoleListiniDistribuzione.Settore = ''MotoScooter'' 
    WHERE NomeListino = ''B2B'''
    
    EXECUTE (@Sql)
    
    -- ========================================
    -- ASSEGNAZIONE REGOLE LISTINO PIATTAFORME
    -- ========================================
    
    PRINT 'Assegnazione regole Piattaforme - Settore Vettura Estivo...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegolePiattaforme = RegoleListiniDistribuzione.ID,
        SettList = ''Vettura''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettVettura + ' 
    AND RegoleListiniDistribuzione.Settore = ''Vettura''
    WHERE NomeListino = ''Piattaforme'' AND Stagione = ''ESTIVO'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Piattaforme - Settore Vettura Invernale...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegolePiattaforme = RegoleListiniDistribuzione.ID,
        SettList = ''Vettura''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettVettura + ' 
    AND RegoleListiniDistribuzione.Settore = ''Vettura''
    WHERE NomeListino = ''Piattaforme'' AND Stagione = ''INVERNALE'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Piattaforme - Settore Vettura 4 Stagioni...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegolePiattaforme = RegoleListiniDistribuzione.ID,
        SettList = ''Vettura''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettVettura + ' 
    AND RegoleListiniDistribuzione.Settore = ''Vettura''
    WHERE NomeListino = ''Piattaforme'' AND Stagione = ''4 STAGIONI'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Piattaforme - Settore Autocarro...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegolePiattaforme = RegoleListiniDistribuzione.ID,
        SettList = ''Autocarro''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Diametro BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettAutocarro + ' 
    AND RegoleListiniDistribuzione.Settore = ''Autocarro''
    WHERE NomeListino = ''Piattaforme'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Piattaforme - Settore MotoScooter...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegolePiattaforme = RegoleListiniDistribuzione.ID,
        SettList = ''MotoScooter''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettMotoScoot + ' 
    AND RegoleListiniDistribuzione.Settore = ''MotoScooter''
    WHERE NomeListino = ''Piattaforme'''
    
    EXECUTE (@Sql)
    
    -- ========================================
    -- ASSEGNAZIONE REGOLE LISTINO COLLEGATI
    -- ========================================
    
    PRINT 'Assegnazione regole Collegati - Settore Vettura...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleCollegati = RegoleListiniDistribuzione.ID,
        SettList = ''Vettura''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettVettura + ' 
    AND RegoleListiniDistribuzione.Settore = ''Vettura'' 
    WHERE NomeListino = ''Collegati'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Collegati - Settore Autocarro...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleCollegati = RegoleListiniDistribuzione.ID,
        SettList = ''Autocarro''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Diametro BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettAutocarro + ' 
    AND RegoleListiniDistribuzione.Settore = ''Autocarro'' 
    WHERE NomeListino = ''Collegati'''
    
    EXECUTE (@Sql)
    
    PRINT 'Assegnazione regole Collegati - Settore MotoScooter...'
    SET @Sql = 'UPDATE OfferteWeb_Tmp 
    SET ID_RegoleCollegati = RegoleListiniDistribuzione.ID,
        SettList = ''MotoScooter''
    FROM OfferteWeb_Tmp INNER JOIN RegoleListiniDistribuzione 
    ON Prezzo BETWEEN CifraIn AND CifraOut 
    AND OfferteWeb_Tmp.SettoreId IN ' + @SettMotoScoot + ' 
    AND RegoleListiniDistribuzione.Settore = ''MotoScooter'' 
    WHERE NomeListino = ''Collegati'''
    
    EXECUTE (@Sql)
    
    -- ========================================
    -- STATISTICHE ASSEGNAZIONE REGOLE
    -- ========================================
    
    DECLARE @TotaleArticoli int, @ArticoliB2B int, @ArticoliPiattaforme int, @ArticoliCollegati int
    
    SELECT @TotaleArticoli = COUNT(*) FROM OfferteWeb_Tmp
    SELECT @ArticoliB2B = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleB2B IS NOT NULL
    SELECT @ArticoliPiattaforme = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegolePiattaforme IS NOT NULL
    SELECT @ArticoliCollegati = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleCollegati IS NOT NULL
    
    PRINT 'STATISTICHE ASSEGNAZIONE REGOLE:'
    PRINT 'Totale articoli: ' + CAST(@TotaleArticoli AS VARCHAR(10))
    PRINT 'Articoli con regole B2B: ' + CAST(@ArticoliB2B AS VARCHAR(10))
    PRINT 'Articoli con regole Piattaforme: ' + CAST(@ArticoliPiattaforme AS VARCHAR(10))
    PRINT 'Articoli con regole Collegati: ' + CAST(@ArticoliCollegati AS VARCHAR(10))
    
    PRINT 'Calcolo fasce di prezzo e assegnazione regole completato!'
    
END

