USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[SP_GenerateCollegatiPrices_V2]    Script Date: 23/06/2025 14:46:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_GenerateCollegatiPrices_V2] -- 04
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variabile per costo trasporto autocarri (facilmente modificabile)
    DECLARE @CostoTraspAutocarro decimal(4,2) = 13.00
    
    PRINT 'Inizio generazione prezzi Collegati con calcolo diretto dalle regole...'
    
    -- Verifico che ci siano articoli con regole Collegati assegnate
    DECLARE @ArticoliConRegole int
    SELECT @ArticoliConRegole = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegoleCollegati IS NOT NULL
    
    IF @ArticoliConRegole = 0
    BEGIN
        PRINT 'ERRORE: Nessun articolo ha regole Collegati assegnate! Eseguire prima SP_CalculatePriceRanges.'
        RETURN
    END
    
    PRINT 'Trovati ' + CAST(@ArticoliConRegole AS VARCHAR(10)) + ' articoli con regole Collegati'
    PRINT 'Costo trasporto autocarri: ' + CAST(@CostoTraspAutocarro AS VARCHAR(10)) + ' € (solo Italia)'
    
    -- ========================================
    -- CALCOLO DIRETTO PREZZI COLLEGATI ITALIA
    -- ========================================
    
    -- Calcolo prezzi base Collegati con calcolo diretto (solo 24H e 48H)
    UPDATE OfferteWeb_Tmp 
    SET 
        P_Collegati = CASE 
            -- Per autocarri: prezzo base + costo trasporto fisso (SENZA provvigione)
            WHEN SettoreId = 8 THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro, 2)
                    ELSE 
                        ROUND(Prezzo + RLD.Margine + @CostoTraspAutocarro, 2)
                END
            -- Per altri settori: prezzo base + trasporto dinamico (SENZA provvigione)
            ELSE -- NO TRUCK
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND((Prezzo * RLD.RicaricoPercentuale) + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END, 2)
                    ELSE 
                        ROUND(Prezzo + RLD.Margine + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END, 2)
                END
        END,
        
        -- Note dettagliate con valori esatti
        Note_Collegati = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                CASE 
                    WHEN SettoreId = 8 THEN
                        'Collegati[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                        ') SENZA provvigione = ' + 
                        CAST(ROUND((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro, 2) AS varchar(11))
                    ELSE -- NO TRUCK
                        'Collegati[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                        ') SENZA provvigione = ' + 
                        CAST(ROUND((Prezzo * RLD.RicaricoPercentuale) + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END, 2) AS varchar(11))
                END
            ELSE
                CASE 
                    WHEN SettoreId = 8 THEN
                        'Collegati[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                        ') SENZA provvigione = ' + 
                        CAST(ROUND(Prezzo + RLD.Margine + @CostoTraspAutocarro, 2) AS varchar(11))
                    ELSE -- NO TRUCK
                        'Collegati[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                        ') SENZA provvigione = ' + 
                        CAST(ROUND(Prezzo + RLD.Margine + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END, 2) AS varchar(11))
                END
        END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    LEFT JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN Ant_FornPiattaforma AFP ON AFP.IdForPiatt = OW.IdFornitore
    WHERE OW.ID_RegoleCollegati IS NOT NULL
    AND TipoPubPiatt IN ('24H', '48H') -- Solo 24H e 48H possono vendere ai Collegati
    
    PRINT 'Calcolati prezzi base Collegati con calcolo diretto.'
    
    -- ========================================
    -- PREZZI COLLEGATI EUROPA (solo da 24H e 48H) - CALCOLO DIRETTO
    -- AUTOCARRI ESCLUSI (solo Italia)
    -- ========================================
    
    -- Germania - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_GER = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z27, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z27, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Spagna - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_SPA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z39, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z39, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Austria - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_AUS = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z20, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z20, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Francia - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_FRA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z26, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z26, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Belgio - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_BEL = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z21, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z21, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Lussemburgo - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_LUS = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z31, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z31, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Olanda - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_OLA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z32, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z32, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Polonia - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_POL = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z33, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z33, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- UK - calcolo diretto (NO autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_UK = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z41, 0), 2)
        ELSE 
            ROUND(Prezzo + RLD.Margine + ISNULL(Bcs.Z41, 0), 2)
    END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Azzeramento prezzi peso per articoli voluminosi (solo per settori non autocarri)
    UPDATE OfferteWeb_Tmp
    SET P_Collegati_GER = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                ROUND(Prezzo * RLD.RicaricoPercentuale, 2)
            ELSE 
                ROUND(Prezzo + RLD.Margine, 2)
        END,
        P_Collegati_SPA = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                ROUND(Prezzo * RLD.RicaricoPercentuale, 2)
            ELSE 
                ROUND(Prezzo + RLD.Margine, 2)
        END,
        P_Collegati_AUS = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                ROUND(Prezzo * RLD.RicaricoPercentuale, 2)
            ELSE 
                ROUND(Prezzo + RLD.Margine, 2)
        END
    FROM OfferteWeb_Tmp OW 
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    INNER JOIN I24BO.dbo.ARTICO ON OW.IdArtico = ARTICO.ID
    WHERE ARTICO.VOLUME >= 0.5
    AND TipoPubPiatt IN ('24H', '48H') 
    AND SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND ID_RegoleCollegati IS NOT NULL
    
    -- Azzeramento esplicito prezzi esteri per AUTOCARRI (solo Italia)
    UPDATE OfferteWeb_Tmp 
    SET P_Collegati_GER = NULL, P_Collegati_SPA = NULL, P_Collegati_AUS = NULL, 
        P_Collegati_FRA = NULL, P_Collegati_BEL = NULL, P_Collegati_LUS = NULL,
        P_Collegati_OLA = NULL, P_Collegati_POL = NULL, P_Collegati_UK = NULL
    WHERE SettoreId = 8 -- Autocarri solo Italia
    AND TipoPubPiatt IN ('24H', '48H') 
    AND ID_RegoleCollegati IS NOT NULL
    
    PRINT 'Calcolati prezzi Collegati Europa con calcolo diretto (solo per 24H e 48H, NO autocarri).'
    
    -- ========================================
    -- AZZERAMENTO ESPLICITO PER 72H
    -- ========================================
    
    -- I fornitori 72H non possono vendere ai Collegati
    UPDATE OfferteWeb_Tmp 
    SET P_Collegati = NULL, P_Collegati_GER = NULL, P_Collegati_SPA = NULL, 
        P_Collegati_AUS = NULL, P_Collegati_FRA = NULL, P_Collegati_BEL = NULL,
        P_Collegati_LUS = NULL, P_Collegati_OLA = NULL, P_Collegati_POL = NULL,
        P_Collegati_UK = NULL,
        Note_Collegati = 'TipoPubPiatt ' + TipoPubPiatt + ' non vendibile ai Collegati'
    WHERE TipoPubPiatt IN ('72H', '72H_CST') AND ID_RegoleCollegati IS NOT NULL
    
    PRINT 'Azzerati prezzi Collegati per fornitori 72H.'
    
    -- ========================================
    -- CONTROLLI QUALITÀ
    -- ========================================
    
    -- Controllo per prezzi negativi
    UPDATE OfferteWeb_Tmp 
    SET P_Collegati = NULL, P_Collegati_GER = NULL, P_Collegati_SPA = NULL,
        P_Collegati_AUS = NULL, P_Collegati_FRA = NULL, P_Collegati_BEL = NULL,
        P_Collegati_LUS = NULL, P_Collegati_OLA = NULL, P_Collegati_POL = NULL,
        P_Collegati_UK = NULL,
        Note_Collegati = 'ERRORE: Prezzo Collegati calcolato negativo'
    WHERE (P_Collegati <= 0 OR P_Collegati_GER <= 0)
    AND ID_RegoleCollegati IS NOT NULL
    
    PRINT 'Applicati controlli qualità Collegati.'
    
    -- ========================================
    -- STATISTICHE FINALI
    -- ========================================
    
    DECLARE @TotaleCollegati INT, @Collegati24H INT, @Collegati48H INT, @Esclusi72H INT
    DECLARE @AutocarriItalia INT, @PrezzoMedioCollegati DECIMAL(10,2), @ArticoliRicaricoPerc int, @ArticoliMargineTradi int
    
    SELECT @TotaleCollegati = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Collegati IS NOT NULL AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @Collegati24H = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Collegati IS NOT NULL AND TipoPubPiatt = '24H' AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @Collegati48H = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Collegati IS NOT NULL AND TipoPubPiatt = '48H' AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @Esclusi72H = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE TipoPubPiatt IN ('72H', '72H_CST') AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @AutocarriItalia = COUNT(*) 
    FROM OfferteWeb_Tmp 
    WHERE P_Collegati IS NOT NULL AND SettoreId = 8 AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @PrezzoMedioCollegati = AVG(P_Collegati) 
    FROM OfferteWeb_Tmp 
    WHERE P_Collegati IS NOT NULL AND ID_RegoleCollegati IS NOT NULL
    
    SELECT @ArticoliRicaricoPerc = COUNT(*) 
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegoleCollegati
    WHERE RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0
    AND TipoPubPiatt IN ('24H', '48H')
    
    SET @ArticoliMargineTradi = @TotaleCollegati - @ArticoliRicaricoPerc
    
    PRINT 'STATISTICHE LISTINO COLLEGATI:'
    PRINT 'Articoli totali Collegati: ' + CAST(@TotaleCollegati AS VARCHAR(10))
    PRINT 'Collegati da 24H: ' + CAST(@Collegati24H AS VARCHAR(10))
    PRINT 'Collegati da 48H: ' + CAST(@Collegati48H AS VARCHAR(10))
    PRINT 'Articoli esclusi (72H): ' + CAST(@Esclusi72H AS VARCHAR(10))
    PRINT 'Autocarri solo Italia: ' + CAST(@AutocarriItalia AS VARCHAR(10))
    PRINT 'Prezzo medio Collegati: ' + CAST(ISNULL(@PrezzoMedioCollegati, 0) AS VARCHAR(10))
    PRINT 'Articoli con RicaricoPercentuale: ' + CAST(@ArticoliRicaricoPerc AS VARCHAR(10))
    PRINT 'Articoli con Margine tradizionale: ' + CAST(@ArticoliMargineTradi AS VARCHAR(10))
    
    PRINT 'Generazione prezzi Collegati completata!'
    
END

