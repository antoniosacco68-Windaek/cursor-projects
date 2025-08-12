USE [PiattaformeWeb]
GO
/****** Object:  StoredProcedure [dbo].[SP_GeneratePlatformPrices_V2]    Script Date: 23/06/2025 14:46:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_GeneratePlatformPrices_V2] -- 03
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variabile per costo trasporto autocarri (facilmente modificabile)
    DECLARE @CostoTraspAutocarro decimal(4,2) = 13.00
    
    PRINT 'Inizio generazione prezzi Piattaforme con calcolo diretto dalle regole...'
    
    -- Verifico che ci siano articoli con regole Piattaforme assegnate
    DECLARE @ArticoliConRegole int
    SELECT @ArticoliConRegole = COUNT(*) FROM OfferteWeb_Tmp WHERE ID_RegolePiattaforme IS NOT NULL
    
    IF @ArticoliConRegole = 0
    BEGIN
        PRINT 'ERRORE: Nessun articolo ha regole Piattaforme assegnate! Eseguire prima SP_CalculatePriceRanges.'
        RETURN
    END
    
    PRINT 'Trovati ' + CAST(@ArticoliConRegole AS VARCHAR(10)) + ' articoli con regole Piattaforme'
    PRINT 'Costo trasporto autocarri: ' + CAST(@CostoTraspAutocarro AS VARCHAR(10)) + ' € (solo Italia)'
    
    -- ========================================
    -- CALCOLO DIRETTO PREZZI PIATTAFORME ITALIA
    -- ========================================
    
    -- Calcolo prezzi per TipoPubPiatt = 24H con calcolo diretto
    UPDATE OfferteWeb_Tmp 
    SET 
        P_T24_24H = CASE 
            -- Per autocarri: prezzo base + costo trasporto fisso
            WHEN SettoreId = 8 THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                END
            -- Per altri settori: prezzo base + trasporto dinamico
            ELSE
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                END
        END,
        
        -- Note dettagliate con tutti i valori esatti
        Note_T24 = CASE 
            WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                CASE 
                    WHEN SettoreId = 8 THEN
                        'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                        ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                        ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                    ELSE
                        'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                        ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                        ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                        ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                END
            ELSE
                CASE 
                    WHEN SettoreId = 8 THEN
                        'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                        ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                        ') = ' + CAST(ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                    ELSE
                        'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                        'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                        ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                        ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                        ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                        ') = ' + CAST(ROUND((Prezzo + RLD.Margine + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                END
        END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    LEFT JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN Ant_FornPiattaforma AFP ON AFP.IdForPiatt = OW.IdFornitore
    WHERE OW.ID_RegolePiattaforme IS NOT NULL AND TipoPubPiatt = '24H'
    
    -- Calcolo prezzi per TipoPubPiatt = 48H con calcolo diretto
    UPDATE OfferteWeb_Tmp 
    SET 
        P_T24_48H = CASE 
            -- Per autocarri: prezzo base + costo trasporto fisso
            WHEN SettoreId = 8 THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                END
            -- Per altri settori: prezzo base + trasporto dinamico
            ELSE
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                END
        END,
        
        -- Aggiorno Note_T24 solo se non già popolato da 24H
        Note_T24 = CASE 
            WHEN Note_T24 IS NULL THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        CASE 
                            WHEN SettoreId = 8 THEN
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                                ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                            ELSE
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                                ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                        END
                    ELSE
                        CASE 
                            WHEN SettoreId = 8 THEN
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                                ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                            ELSE
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                                ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND((Prezzo + RLD.Margine + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                        END
                END
            ELSE Note_T24
        END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    LEFT JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN Ant_FornPiattaforma AFP ON AFP.IdForPiatt = OW.IdFornitore
    WHERE OW.ID_RegolePiattaforme IS NOT NULL AND TipoPubPiatt = '48H'
    
    -- Calcolo prezzi per TipoPubPiatt = 72H con calcolo diretto
    UPDATE OfferteWeb_Tmp 
    SET 
        P_T24_72H = CASE 
            -- Per autocarri: prezzo base + costo trasporto fisso
            WHEN SettoreId = 8 THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2)
                END
            -- Per altri settori: prezzo base + trasporto dinamico
            ELSE
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                    ELSE 
                        ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z1, 0)) * RLD.ProvvPiatt, 2)
                END
        END,
        
        -- Aggiorno Note_T24 solo se non già popolato
        Note_T24 = CASE 
            WHEN Note_T24 IS NULL THEN
                CASE 
                    WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
                        CASE 
                            WHEN SettoreId = 8 THEN
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                                ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                            ELSE
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') * RicaricoPerc(' + CAST(RLD.RicaricoPercentuale AS varchar(11)) + 
                                ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND(((Prezzo * RLD.RicaricoPercentuale) + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                        END
                    ELSE
                        CASE 
                            WHEN SettoreId = 8 THEN
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                                ') + Trasporto(' + CAST(@CostoTraspAutocarro AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND((Prezzo + RLD.Margine + @CostoTraspAutocarro) * RLD.ProvvPiatt, 2) AS varchar(11))
                            ELSE
                                'Piatt[ID:' + CAST(RLD.ID AS varchar(5)) + '] ' +
                                'Acquisto(' + CAST(Prezzo AS varchar(11)) + 
                                ') + Margine(' + CAST(RLD.Margine AS varchar(11)) + 
                                ') + Trasporto(' + CAST(CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END AS varchar(11)) + 
                                ') * Provv(' + CAST(RLD.ProvvPiatt AS varchar(11)) + 
                                ') = ' + CAST(ROUND((Prezzo + RLD.Margine + CASE WHEN AFP.SpeseTrasporto = 0 THEN 0 ELSE ISNULL(Bcs.Z1, 0) END) * RLD.ProvvPiatt, 2) AS varchar(11))
                        END
                END
            ELSE Note_T24
        END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    LEFT JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN Ant_FornPiattaforma AFP ON AFP.IdForPiatt = OW.IdFornitore
    WHERE OW.ID_RegolePiattaforme IS NOT NULL AND TipoPubPiatt IN ('72H', '72H_CST')
    
    PRINT 'Calcolati prezzi Piattaforme Italia con calcolo diretto.'
    
    -- ========================================
    -- PREZZI PIATTAFORME EUROPA (solo 24H e 48H) - CALCOLO DIRETTO
    -- AUTOCARRI ESCLUSI (solo Italia)
    -- ========================================
    
    -- Germania (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_GER = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z27, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z27, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN I24BO.dbo.ARTICO ON OW.IdArtico = ARTICO.ID
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    AND (ARTICO.VOLUME IS NULL OR ARTICO.VOLUME < 0.5) -- Escludo articoli voluminosi
    
    -- Spagna (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_SPA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z39, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z39, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN I24BO.dbo.ARTICO ON OW.IdArtico = ARTICO.ID
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    AND (ARTICO.VOLUME IS NULL OR ARTICO.VOLUME < 0.5)
    
    -- Austria (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_AUS = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z20, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z20, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    LEFT JOIN I24BO.dbo.ARTICO ON OW.IdArtico = ARTICO.ID
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    AND (ARTICO.VOLUME IS NULL OR ARTICO.VOLUME < 0.5)
    
    -- Francia (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_FRA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z26, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z26, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- Belgio (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_BEL = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z21, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z21, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- Lussemburgo (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_LUS = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z31, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z31, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- Olanda (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_OLA = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z32, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z32, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- Polonia (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_POL = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z33, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z33, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- UK e Danimarca (solo 24H e 48H) - NO autocarri
    UPDATE OfferteWeb_Tmp 
    SET P_T24_Uk_Danim = CASE 
        WHEN RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0 THEN
            ROUND(((Prezzo * RLD.RicaricoPercentuale) + ISNULL(Bcs.Z41, 0)) * RLD.ProvvPiatt, 2)
        ELSE 
            ROUND((Prezzo + RLD.Margine + ISNULL(Bcs.Z41, 0)) * RLD.ProvvPiatt, 2)
    END
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    INNER JOIN BestCosti_Sped Bcs ON Bcs.Misura = OW.Misura AND Bcs.Settore_Id = OW.SettoreId
    WHERE OW.SettoreId IN (4,6,7,76,37,16,91) -- ESCLUDO SettoreId = 8 (Autocarro)
    AND OW.ID_RegolePiattaforme IS NOT NULL 
    AND TipoPubPiatt IN ('24H', '48H')
    
    -- Azzeramento esplicito prezzi esteri per AUTOCARRI (solo Italia)
    UPDATE OfferteWeb_Tmp 
    SET P_T24_GER = NULL, P_T24_SPA = NULL, P_T24_AUS = NULL,
        P_T24_BEL = NULL, P_T24_LUS = NULL, P_T24_FRA = NULL,
        P_T24_OLA = NULL, P_T24_POL = NULL, P_T24_Uk_Danim = NULL
    WHERE SettoreId = 8 -- Autocarri solo Italia
    AND ID_RegolePiattaforme IS NOT NULL
    
    -- Azzeramento prezzi esteri per TipoPubPiatt = 72H
    UPDATE OfferteWeb_Tmp 
    SET P_T24_GER = NULL, P_T24_SPA = NULL, P_T24_AUS = NULL,
        P_T24_BEL = NULL, P_T24_LUS = NULL, P_T24_FRA = NULL,
        P_T24_OLA = NULL, P_T24_POL = NULL, P_T24_Uk_Danim = NULL
    WHERE TipoPubPiatt IN ('72H', '72H_CST') AND ID_RegolePiattaforme IS NOT NULL
    
    PRINT 'Calcolati prezzi Piattaforme Europa con calcolo diretto (solo per 24H e 48H, NO autocarri).'
    
    -- ========================================
    -- CONTROLLI QUALITÀ
    -- ========================================
    
    -- Controllo per prezzi negativi
    UPDATE OfferteWeb_Tmp 
    SET P_T24_24H = NULL, P_T24_48H = NULL, P_T24_72H = NULL,
        P_T24_GER = NULL, P_T24_SPA = NULL, P_T24_AUS = NULL,
        P_T24_FRA = NULL, P_T24_BEL = NULL, P_T24_LUS = NULL,
        P_T24_OLA = NULL, P_T24_POL = NULL, P_T24_Uk_Danim = NULL,
        Note_T24 = 'ERRORE: Prezzo Piattaforme calcolato negativo'
    WHERE (P_T24_24H <= 0 OR P_T24_48H <= 0 OR P_T24_72H <= 0)
    AND ID_RegolePiattaforme IS NOT NULL
    
    PRINT 'Applicati controlli qualità Piattaforme.'
    
    -- ========================================
    -- STATISTICHE FINALI
    -- ========================================
    
    DECLARE @Articoli24H int, @Articoli48H int, @Articoli72H int
    DECLARE @ArticoliEsteri int, @AutocarriItalia int, @PrezzoMedioT24 decimal(10,2)
    DECLARE @ArticoliRicaricoPerc int, @ArticoliMargineTradi int
    
    SELECT @Articoli24H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
    SELECT @Articoli48H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_48H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
    SELECT @Articoli72H = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_72H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
    SELECT @ArticoliEsteri = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_GER IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
    SELECT @AutocarriItalia = COUNT(*) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL AND SettoreId = 8 AND ID_RegolePiattaforme IS NOT NULL
    SELECT @PrezzoMedioT24 = AVG(P_T24_24H) FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL AND ID_RegolePiattaforme IS NOT NULL
    
    SELECT @ArticoliRicaricoPerc = COUNT(*) 
    FROM OfferteWeb_Tmp OW
    INNER JOIN RegoleListiniDistribuzione RLD ON RLD.ID = OW.ID_RegolePiattaforme
    WHERE RLD.RicaricoPercentuale IS NOT NULL AND RLD.RicaricoPercentuale > 0
    
    SET @ArticoliMargineTradi = @Articoli24H + @Articoli48H + @Articoli72H - @ArticoliRicaricoPerc
    
    PRINT 'STATISTICHE LISTINO PIATTAFORME:'
    PRINT 'Articoli 24H: ' + CAST(@Articoli24H AS VARCHAR(10))
    PRINT 'Articoli 48H: ' + CAST(@Articoli48H AS VARCHAR(10))
    PRINT 'Articoli 72H: ' + CAST(@Articoli72H AS VARCHAR(10))
    PRINT 'Articoli con prezzi esteri: ' + CAST(@ArticoliEsteri AS VARCHAR(10))
    PRINT 'Autocarri solo Italia: ' + CAST(@AutocarriItalia AS VARCHAR(10))
    PRINT 'Prezzo medio 24H: ' + CAST(ISNULL(@PrezzoMedioT24, 0) AS VARCHAR(10))
    PRINT 'Articoli con RicaricoPercentuale: ' + CAST(@ArticoliRicaricoPerc AS VARCHAR(10))
    PRINT 'Articoli con Margine tradizionale: ' + CAST(@ArticoliMargineTradi AS VARCHAR(10))
    
    PRINT 'Generazione prezzi Piattaforme completata!'
    
END

