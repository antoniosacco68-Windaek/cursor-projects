USE [PiattaformeWeb]
GO

-- =============================================
-- Author: Sistema Ristrutturato
-- Create date: 2025-01-02
-- Description: Confronto tra Nuovo e Vecchio Sistema Distribuzione
--              Per validare i risultati e verificare le differenze
-- =============================================

/****** Object:  StoredProcedure [dbo].[SP_CompareDistributionSystems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_CompareDistributionSystems]
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '================================================================'
    PRINT 'CONFRONTO SISTEMA VECCHIO vs NUOVO - INIZIO'
    PRINT '================================================================'
    
    -- Controlli prerequisiti
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OfferteWeb_1Pass' AND xtype='U')
    BEGIN
        PRINT 'ERRORE: Tabella OfferteWeb_1Pass (sistema vecchio) non trovata!'
        RETURN
    END
    
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OfferteWeb_Tmp' AND xtype='U')
    BEGIN
        PRINT 'ERRORE: Tabella OfferteWeb_Tmp (sistema nuovo) non trovata!'
        RETURN
    END
    
    -- ========================================
    -- CONFRONTO PREZZI B2B
    -- ========================================
    
    PRINT ''
    PRINT '--- CONFRONTO PREZZI B2B ---'
    
    -- Statistiche generali B2B
    DECLARE @VecchioB2B_Count INT, @NuovoB2B_Count INT
    DECLARE @VecchioB2B_Avg DECIMAL(10,2), @NuovoB2B_Avg DECIMAL(10,2)
    
    SELECT @VecchioB2B_Count = COUNT(*), @VecchioB2B_Avg = AVG(P_Base)
    FROM OfferteWeb_1Pass WHERE P_Base IS NOT NULL
    
    SELECT @NuovoB2B_Count = COUNT(*), @NuovoB2B_Avg = AVG(P_Base)
    FROM OfferteWeb_Tmp WHERE P_Base IS NOT NULL
    
    PRINT 'Articoli B2B - Vecchio: ' + CAST(@VecchioB2B_Count AS VARCHAR(10)) + 
          ', Nuovo: ' + CAST(@NuovoB2B_Count AS VARCHAR(10))
    PRINT 'Prezzo medio B2B - Vecchio: ' + CAST(ISNULL(@VecchioB2B_Avg, 0) AS VARCHAR(10)) + 
          ', Nuovo: ' + CAST(ISNULL(@NuovoB2B_Avg, 0) AS VARCHAR(10))
    
    -- Differenze significative B2B
    SELECT 
        'Differenze B2B > 5%' as Tipo,
        COUNT(*) as NumeroArticoli,
        AVG(ABS(new.P_Base - old.P_Base)) as DifferenzaMedia
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    WHERE new.P_Base IS NOT NULL 
    AND old.P_Base IS NOT NULL
    AND ABS(new.P_Base - old.P_Base) / old.P_Base > 0.05
    
    -- ========================================
    -- CONFRONTO PREZZI PIATTAFORME
    -- ========================================
    
    PRINT ''
    PRINT '--- CONFRONTO PREZZI PIATTAFORME ---'
    
    -- Statistiche generali Piattaforme
    DECLARE @VecchioT24_Count INT, @NuovoT24_Count INT
    DECLARE @VecchioT24_Avg DECIMAL(10,2), @NuovoT24_Avg DECIMAL(10,2)
    
    SELECT @VecchioT24_Count = COUNT(*), @VecchioT24_Avg = AVG(P_T24_24H)
    FROM OfferteWeb_1Pass WHERE P_T24_24H IS NOT NULL
    
    SELECT @NuovoT24_Count = COUNT(*), @NuovoT24_Avg = AVG(P_T24_24H)
    FROM OfferteWeb_Tmp WHERE P_T24_24H IS NOT NULL
    
    PRINT 'Articoli Piattaforme - Vecchio: ' + CAST(@VecchioT24_Count AS VARCHAR(10)) + 
          ', Nuovo: ' + CAST(@NuovoT24_Count AS VARCHAR(10))
    PRINT 'Prezzo medio Piattaforme - Vecchio: ' + CAST(ISNULL(@VecchioT24_Avg, 0) AS VARCHAR(10)) + 
          ', Nuovo: ' + CAST(ISNULL(@NuovoT24_Avg, 0) AS VARCHAR(10))
    
    -- Differenze significative Piattaforme
    SELECT 
        'Differenze Piattaforme > 3%' as Tipo,
        COUNT(*) as NumeroArticoli,
        AVG(ABS(new.P_T24_24H - old.P_T24_24H)) as DifferenzaMedia
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    WHERE new.P_T24_24H IS NOT NULL 
    AND old.P_T24_24H IS NOT NULL
    AND ABS(new.P_T24_24H - old.P_T24_24H) / old.P_T24_24H > 0.03
    
    -- ========================================
    -- CONFRONTO DETTAGLIO PER SETTORE
    -- ========================================
    
    PRINT ''
    PRINT '--- CONFRONTO PER SETTORE ---'
    
    SELECT 
        CASE 
            WHEN new.SettoreId IN (4,6,7,37,76) THEN 'Vettura'
            WHEN new.SettoreId = 8 THEN 'Autocarro'
            WHEN new.SettoreId IN (16,91) THEN 'MotoScooter'
            ELSE 'Altro'
        END as Settore,
        COUNT(*) as TotaleArticoli,
        SUM(CASE WHEN ABS(ISNULL(new.P_Base,0) - ISNULL(old.P_Base,0)) > 1 THEN 1 ELSE 0 END) as DifferenzeB2B,
        SUM(CASE WHEN ABS(ISNULL(new.P_T24_24H,0) - ISNULL(old.P_T24_24H,0)) > 1 THEN 1 ELSE 0 END) as DifferenzePiattaforme,
        AVG(ISNULL(new.P_Base,0)) as MediaB2B_Nuovo,
        AVG(ISNULL(old.P_Base,0)) as MediaB2B_Vecchio
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    GROUP BY 
        CASE 
            WHEN new.SettoreId IN (4,6,7,37,76) THEN 'Vettura'
            WHEN new.SettoreId = 8 THEN 'Autocarro'
            WHEN new.SettoreId IN (16,91) THEN 'MotoScooter'
            ELSE 'Altro'
        END
    ORDER BY TotaleArticoli DESC
    
    -- ========================================
    -- CONFRONTO MARGINI
    -- ========================================
    
    PRINT ''
    PRINT '--- CONFRONTO MARGINI ---'
    
    SELECT 
        'Margini B2B' as TipoMargine,
        AVG(ISNULL(old.M_Base,0)) as Vecchio_Medio,
        AVG(ISNULL(new.M_Base,0)) as Nuovo_Medio,
        COUNT(*) as NumeroArticoli
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    WHERE new.M_Base IS NOT NULL OR old.M_Base IS NOT NULL
    
    UNION ALL
    
    SELECT 
        'Margini Piattaforme' as TipoMargine,
        AVG(ISNULL(old.M_T24,0)) as Vecchio_Medio,
        AVG(ISNULL(new.M_T24,0)) as Nuovo_Medio,
        COUNT(*) as NumeroArticoli
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    WHERE new.M_T24 IS NOT NULL OR old.M_T24 IS NOT NULL
    
    -- ========================================
    -- ARTICOLI PROBLEMATICI
    -- ========================================
    
    PRINT ''
    PRINT '--- ARTICOLI CON MAGGIORI DIFFERENZE ---'
    
    -- Top 10 articoli con maggiori differenze B2B
    SELECT TOP 10
        new.IdArtico,
        new.Produttore,
        new.Misura,
        old.P_Base as Vecchio_B2B,
        new.P_Base as Nuovo_B2B,
        ABS(new.P_Base - old.P_Base) as Differenza,
        CASE 
            WHEN old.P_Base > 0 THEN ABS(new.P_Base - old.P_Base) / old.P_Base * 100
            ELSE 0
        END as Differenza_Perc
    FROM OfferteWeb_Tmp new
    INNER JOIN OfferteWeb_1Pass old ON new.IdOffWeb = old.IdOffWeb
    WHERE new.P_Base IS NOT NULL 
    AND old.P_Base IS NOT NULL
    AND ABS(new.P_Base - old.P_Base) > 2
    ORDER BY ABS(new.P_Base - old.P_Base) DESC
    
    -- ========================================
    -- CONTROLLI INTEGRITÀ
    -- ========================================
    
    PRINT ''
    PRINT '--- CONTROLLI INTEGRITÀ ---'
    
    -- Articoli persi nel nuovo sistema
    DECLARE @ArticoliPersi INT
    SELECT @ArticoliPersi = COUNT(*)
    FROM OfferteWeb_1Pass old
    LEFT JOIN OfferteWeb_Tmp new ON old.IdOffWeb = new.IdOffWeb
    WHERE new.IdOffWeb IS NULL
    
    PRINT 'Articoli persi nel nuovo sistema: ' + CAST(@ArticoliPersi AS VARCHAR(10))
    
    -- Articoli senza prezzi nel nuovo sistema
    DECLARE @ArticoliSenzaPrezzi INT
    SELECT @ArticoliSenzaPrezzi = COUNT(*)
    FROM OfferteWeb_Tmp 
    WHERE P_Base IS NULL AND P_T24_24H IS NULL
    
    PRINT 'Articoli senza prezzi nel nuovo sistema: ' + CAST(@ArticoliSenzaPrezzi AS VARCHAR(10))
    
    -- ========================================
    -- RACCOMANDAZIONI
    -- ========================================
    
    PRINT ''
    PRINT '--- RACCOMANDAZIONI ---'
    
    IF @ArticoliPersi > 0
        PRINT 'ATTENZIONE: Alcuni articoli sono stati persi nella migrazione!'
        
    IF @ArticoliSenzaPrezzi > (@VecchioB2B_Count + @VecchioT24_Count) * 0.05
        PRINT 'ATTENZIONE: Troppi articoli senza prezzi nel nuovo sistema!'
    
    IF ABS(@NuovoB2B_Avg - @VecchioB2B_Avg) / @VecchioB2B_Avg > 0.1
        PRINT 'ATTENZIONE: Differenza significativa nei prezzi medi B2B!'
        
    IF ABS(@NuovoT24_Avg - @VecchioT24_Avg) / @VecchioT24_Avg > 0.1
        PRINT 'ATTENZIONE: Differenza significativa nei prezzi medi Piattaforme!'
    
    PRINT ''
    PRINT '================================================================'
    PRINT 'CONFRONTO SISTEMA VECCHIO vs NUOVO - COMPLETATO'
    PRINT '================================================================'
    
END

GO 