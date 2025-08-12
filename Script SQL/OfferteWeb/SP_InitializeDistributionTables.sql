USE [PiattaformeWeb]
GO

-- =============================================
-- Author: Sistema Ristrutturato
-- Create date: 2025-01-02
-- Description: Inizializzazione Tabelle Nuovo Sistema Distribuzione
-- =============================================

/****** Object:  StoredProcedure [dbo].[SP_InitializeDistributionTables] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_InitializeDistributionTables]
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Controllo se le tabelle esistono già
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='RegoleListiniDistribuzione' AND xtype='U')
    BEGIN
        PRINT 'Creazione tabella RegoleListiniDistribuzione...'
        
        CREATE TABLE [dbo].[RegoleListiniDistribuzione](
            [ID] [int] IDENTITY(1,1) NOT NULL,
            [NomeListino] [nvarchar](50) NOT NULL,
            [CifraIn] [decimal](10, 2) NOT NULL,
            [CifraOut] [decimal](10, 2) NOT NULL,
            [Margine] [decimal](10, 2) NOT NULL,
            [MargPiu] [decimal](10, 2) NULL,
            [MargMeno] [decimal](10, 2) NULL,
            [Settore] [nvarchar](20) NOT NULL,
            [CostoTrasportoIt] [decimal](10, 2) NOT NULL,
            [ProvvPiatt] [decimal](10, 4) NOT NULL,
            [TipoListForn] [nvarchar](10) NOT NULL,
            [MargMenoEstivo] [decimal](10, 2) NULL,
            [MargMenoAS] [decimal](10, 2) NULL,
            [MargMenoInvernale] [decimal](10, 2) NULL,
            [RicaricoPercentuale] [decimal](6, 3) NULL, -- Percentuale di ricarico (es: 1.25 = +25%)
            [DataCreazione] [datetime] NOT NULL DEFAULT GETDATE(),
            [DataModifica] [datetime] NOT NULL DEFAULT GETDATE(),
            CONSTRAINT [PK_RegoleListiniDistribuzione] PRIMARY KEY CLUSTERED ([ID] ASC)
        )
        
        PRINT 'Tabella RegoleListiniDistribuzione creata con successo.'
    END
    ELSE
    BEGIN
        PRINT 'Tabella RegoleListiniDistribuzione già esistente.'
    END
    
    -- Controllo se la tabella OfferteWeb_Tmp esiste già
    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='OfferteWeb_Tmp' AND xtype='U')
    BEGIN
        PRINT 'Creazione tabella OfferteWeb_Tmp come copia di OfferteWeb_1Pass...'
        
        -- Creo la tabella con la stessa struttura di OfferteWeb_1Pass
        SELECT TOP 0 * 
        INTO OfferteWeb_Tmp 
        FROM OfferteWeb_1Pass
        
        PRINT 'Tabella OfferteWeb_Tmp creata con successo.'
    END
    ELSE
    BEGIN
        PRINT 'Tabella OfferteWeb_Tmp già esistente.'
    END
    
    -- Popolamento iniziale RegoleListiniDistribuzione con dati di base
    IF NOT EXISTS (SELECT * FROM RegoleListiniDistribuzione)
    BEGIN
        PRINT 'Popolamento iniziale RegoleListiniDistribuzione...'
        
        -- Inserisco i dati REALI dal CSV RegoleListiniPiatt per TYRE24 24H
        -- Convertiti nei 3 nuovi listini: B2B, Piattaforme, Collegati
        
        -- ===== LISTINO PIATTAFORME - SETTORE VETTURA (dati originali TYRE24 24H) =====
        INSERT INTO RegoleListiniDistribuzione (NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore, CostoTrasportoIt, ProvvPiatt, TipoListForn, RicaricoPercentuale)
        VALUES 
        ('Piattaforme', 0.00, 30.00, 5.50, 0.00, 2.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 30.01, 40.00, 6.50, 0.00, 2.50, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 40.01, 50.00, 8.50, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 50.01, 60.00, 9.00, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 60.01, 75.00, 12.50, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 75.01, 90.00, 14.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 90.01, 110.00, 16.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 110.01, 130.00, 18.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 130.01, 160.00, 23.00, 0.00, 7.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 160.01, 190.00, 29.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 190.01, 230.00, 33.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 230.01, 270.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 270.01, 300.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 300.01, 9999.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        
        -- ===== LISTINO PIATTAFORME - SETTORE AUTOCARRO (dati originali TYRE24 24H) =====
        ('Piattaforme', 0.00, 223.00, 25.00, 0.00, 0.00, 'Autocarro', 13.00, 1.30, '24H', NULL),
        ('Piattaforme', 224.00, 260.00, 35.00, 0.00, 0.00, 'Autocarro', 13.00, 1.30, '24H', NULL),
        
        -- ===== LISTINO PIATTAFORME - SETTORE MOTOSCOOTER (dati originali TYRE24 24H) =====
        ('Piattaforme', 0.00, 30.00, 7.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 30.01, 40.00, 8.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 40.01, 50.00, 8.50, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 50.01, 60.00, 10.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 60.01, 75.00, 11.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 75.01, 90.00, 13.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 90.01, 110.00, 15.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 110.01, 130.00, 17.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 130.01, 160.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 160.01, 190.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 190.01, 230.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 230.01, 270.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 270.01, 300.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Piattaforme', 300.01, 9999.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        
        -- ===== LISTINO B2B - STESSE FASCE DI PIATTAFORME (per ora) =====
        INSERT INTO RegoleListiniDistribuzione (NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore, CostoTrasportoIt, ProvvPiatt, TipoListForn, RicaricoPercentuale)
        VALUES 
        -- B2B Vettura (stesse fasce, margini uguali per ora - modificabili in futuro)
        ('B2B', 0.00, 30.00, 5.50, 0.00, 2.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 30.01, 40.00, 6.50, 0.00, 2.50, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 40.01, 50.00, 8.50, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 50.01, 60.00, 9.00, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 60.01, 75.00, 12.50, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 75.01, 90.00, 14.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 90.01, 110.00, 16.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 110.01, 130.00, 18.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 130.01, 160.00, 23.00, 0.00, 7.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 160.01, 190.00, 29.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 190.01, 230.00, 33.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 230.01, 270.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 270.01, 300.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('B2B', 300.01, 9999.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        
        -- B2B Autocarro
        ('B2B', 0.00, 223.00, 25.00, 0.00, 0.00, 'Autocarro', 13.00, 1.013, '24H', NULL),
        ('B2B', 224.00, 260.00, 35.00, 0.00, 0.00, 'Autocarro', 13.00, 1.013, '24H', NULL),
        
        -- B2B MotoScooter
        ('B2B', 0.00, 30.00, 7.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 30.01, 40.00, 8.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 40.01, 50.00, 8.50, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 50.01, 60.00, 10.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 60.01, 75.00, 11.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 75.01, 90.00, 13.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 90.01, 110.00, 15.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 110.01, 130.00, 17.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 130.01, 160.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 160.01, 190.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 190.01, 230.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 230.01, 270.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 270.01, 300.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('B2B', 300.01, 9999.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        
        -- ===== LISTINO COLLEGATI - STESSE FASCE DI PIATTAFORME (per ora) =====
        INSERT INTO RegoleListiniDistribuzione (NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, Settore, CostoTrasportoIt, ProvvPiatt, TipoListForn, RicaricoPercentuale)
        VALUES 
        -- Collegati Vettura (stesse fasce di Piattaforme)
        ('Collegati', 0.00, 30.00, 5.50, 0.00, 2.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 30.01, 40.00, 6.50, 0.00, 2.50, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 40.01, 50.00, 8.50, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 50.01, 60.00, 9.00, 0.00, 3.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 60.01, 75.00, 12.50, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 75.01, 90.00, 14.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 90.01, 110.00, 16.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 110.01, 130.00, 18.00, 0.00, 5.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 130.01, 160.00, 23.00, 0.00, 7.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 160.01, 190.00, 29.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 190.01, 230.00, 33.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 230.01, 270.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 270.01, 300.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        ('Collegati', 300.01, 9999.00, 35.00, 0.00, 10.00, 'Vettura', 4.40, 1.013, '24H', NULL),
        
        -- Collegati Autocarro
        ('Collegati', 0.00, 223.00, 25.00, 0.00, 0.00, 'Autocarro', 13.00, 1.013, '24H', NULL),
        ('Collegati', 224.00, 260.00, 35.00, 0.00, 0.00, 'Autocarro', 13.00, 1.013, '24H', NULL),
        
        -- Collegati MotoScooter
        ('Collegati', 0.00, 30.00, 7.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 30.01, 40.00, 8.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 40.01, 50.00, 8.50, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 50.01, 60.00, 10.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 60.01, 75.00, 11.00, 0.00, 3.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 75.01, 90.00, 13.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 90.01, 110.00, 15.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 110.01, 130.00, 17.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 130.01, 160.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 160.01, 190.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 190.01, 230.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 230.01, 270.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 270.01, 300.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL),
        ('Collegati', 300.01, 9999.00, 21.00, 0.00, 4.00, 'MotoScooter', 4.40, 1.013, '24H', NULL)
        
        PRINT 'Popolamento iniziale RegoleListiniDistribuzione completato.'
    END
    ELSE
    BEGIN
        PRINT 'RegoleListiniDistribuzione già popolata.'
    END
    
    PRINT 'Inizializzazione tabelle completata con successo!'
    
END

GO