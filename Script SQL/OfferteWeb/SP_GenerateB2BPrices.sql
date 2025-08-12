USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[SP_GenerateB2BPrices]    Script Date: 23/06/2025 14:46:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_GenerateB2BPrices] -- 02
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variabile per costo trasporto autocarri (facilmente modificabile)
    DECLARE @CostoTraspAutocarro decimal(4,2) = 13.00
    
    PRINT 'Inizio generazione prezzi B2B con calcolo diretto dalle regole...'
    
    -- Verifico che ci siano articoli con regole B2B assegnate
    DECLARE @ArticoliConRegole int
    SELECT @ArticoliConRegole = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleB2B IS NOT NULL
    
    IF @ArticoliConRegole = 0
    BEGIN
        PRINT 'ERRORE: Nessun articolo ha regole B2B assegnate! Eseguire prima SP_CalculatePriceRanges.'
        RETURN
    END
    
    PRINT 'Trovati ' + CAST(@ArticoliConRegole AS VARCHAR(10)) + ' articoli con regole B2B'
    PRINT 'Costo trasporto autocarri: ' + CAST(@CostoTraspAutocarro AS VARCHAR(10)) + ' €'
    
    -- ========================================
    -- CALCOLO DIRETTO PREZZI B2B
    -- ========================================
    
    -- Calcolo prezzi B2B Standard (Italia) con calcolo diretto
    UPDATE OfferteWeb_Tmp 
    SET 
        P_Std = CASE 
            -- Se RicaricoPercentuale è definito e > 0, uso quello
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                ROUND(Prezzo * RLD.RicaricoPercentuale, 2)
            -- Altrimenti uso il sistema di margini tradizionale
            ELSE 
                ROUND(Prezzo + RLD.Margine, 2)
        END,
        
        -- Calcolo per Bologna con trasporto autocarri
        P_StdBo = CASE 
            -- Per autocarri aggiungo costo trasporto
            WHEN SettoreId = 8 THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro, 2)
                    ELSE 
                        ROUND(Prezzo + RLD.Margine + @CostoTraspAutocarro, 2)
                END
            -- Per altri settori uguale al prezzo standard
            ELSE 
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(Prezzo * RLD.RicaricoPercentuale, 2)
                    ELSE 
                        ROUND(Prezzo + RLD.Margine, 2)
                END
        END,
        
        -- Note dettagliate con valori esatti
        Note_Std = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                CASE 
                    WHEN SettoreId = 8 THEN
                        'B2B[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + ') = ' + 
                        CAST(ROUND((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro, 2) AS varchar(11))
                    ELSE
                        'B2B[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') = ' + 
                        CAST(ROUND(Prezzo * RLD.RicaricoPercentuale, 2) AS varchar(11))
                END
            ELSE
                CASE 
                    WHEN SettoreId = 8 THEN
                        'B2B[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + ') = ' + 
                        CAST(ROUND(Prezzo + RLD.Margine + @CostoTraspAutocarro, 2) AS varchar(11))
                    ELSE
                        'B2B[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') = ' + 
                        CAST(ROUND(Prezzo + RLD.Margine, 2) AS varchar(11))
                END
        END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleB2B
    WHERE OW.ID_RegoleB2B IS NOT NULL
    
    PRINT 'Calcolati prezzi B2B con calcolo diretto dalle regole.'
    
    -- ========================================
    -- CONTROLLI QUALITÀ
    -- ========================================
    
    -- Controllo per prezzi negativi
    UPDATE OfferteWeb_Tmp 
    SET P_Std = NULL,
        P_StdBo = NULL,
        Note_Std = 'ERRORE: Prezzo B2B calcolato negativo'
    WHERE (P_Std <= 0 OR P_StdBo <= 0)
    AND ID_RegoleB2B IS NOT NULL
    
    PRINT 'Applicati controlli qualità B2B.'
    
    -- ========================================
    -- STATISTICHE FINALI
    -- ========================================
    
    DECLARE @TotaleB2B int, @AutocarriConTrasporto int, @PrezzoMedioB2B decimal(10,2)
    DECLARE @ArticoliRicaricoPerc int, @ArticoliMargineTradi int
    
    SELECT @TotaleB2B = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Std IS NOT NULL AND ID_RegoleB2B IS NOT NULL
    
    SELECT @AutocarriConTrasporto = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Std IS NOT NULL AND SettoreId = 8 AND ID_RegoleB2B IS NOT NULL
    
    SELECT @PrezzoMedioB2B = AVG(P_Std) 
    FROM OfferteWeb_Tmp 
    WHERE P_Std IS NOT NULL AND ID_RegoleB2B IS NOT NULL
    
    SELECT @ArticoliRicaricoPerc = COUNT(*) 
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleB2B
    WHERE RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0
    
    SET @ArticoliMargineTradi = @TotaleB2B - @ArticoliRicaricoPerc
    
    PRINT 'STATISTICHE LISTINO B2B:'
    PRINT 'Articoli totali B2B: ' + CAST(@TotaleB2B AS VARCHAR(10))
    PRINT 'Autocarri con trasporto: ' + CAST(@AutocarriConTrasporto AS VARCHAR(10))
    PRINT 'Prezzo medio B2B: ' + CAST(ISNULL(@PrezzoMedioB2B, 0) AS VARCHAR(10))
    PRINT 'Articoli con RicaricoPercentuale: ' + CAST(@ArticoliRicaricoPerc AS VARCHAR(10))
    PRINT 'Articoli con Margine tradizionale: ' + CAST(@ArticoliMargineTradi AS VARCHAR(10))
    
    PRINT 'Generazione prezzi B2B completata!'
    
END

