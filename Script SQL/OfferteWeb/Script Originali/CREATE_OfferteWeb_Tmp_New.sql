USE [PiattaformeWeb]
GO

-- =============================================
-- Script per ricreare OfferteWeb_Tmp ottimizzata
-- per il nuovo sistema distribuzione
-- =============================================

-- Drop della tabella esistente se presente
IF EXISTS (SELECT * FROM sysobjects WHERE name='OfferteWeb_Tmp' AND xtype='U')
BEGIN
    DROP TABLE [dbo].[OfferteWeb_Tmp]
    PRINT 'Tabella OfferteWeb_Tmp esistente eliminata.'
END

-- Creazione nuova tabella ottimizzata
CREATE TABLE [dbo].[OfferteWeb_Tmp](
    -- ===== CAMPI BASE (mantenuti dalla vecchia struttura) =====
    [IdOffWeb] [int] IDENTITY(1,1) NOT NULL,
    [IdArtico] [int] NOT NULL,
    [CodiceArticolo] [varchar](40) NULL,
    [CodArtForn] [varchar](40) NULL,
    [CodArtPiatt] [varchar](40) NULL,
    [DescrB2b] [varchar](200) NULL,
    [IdFornitore] [int] NOT NULL,
    [Qta] [int] NOT NULL,
    [Prezzo] [decimal](9, 2) NULL,
    [PrezzoMan] [decimal](9, 2) NULL,
    [Posizione] [int] NULL,
    [PosGlobale] [int] NULL,
    [Settore] [nchar](50) NULL,
    [SettList] [nchar](50) NULL,
    [SettoreId] [int] NULL,
    [Diametro] [int] NULL,
    [Produttore] [nchar](50) NULL,
    [MarcaId] [int] NULL,
    [Stagione] [varchar](50) NULL,
    [Misura] [varchar](10) NULL,
    [Peso] [decimal](9, 2) NULL,
    [DOT_Forn] [nchar](20) NULL,
    [CodMagForn] [varchar](5) NULL,
    [Descr_Piatt] [varchar](250) NULL,
    
    -- ===== CAMPI LISTINO B2B (SEMPLIFICATO - SOLO P_Std) =====
    [P_Std] [decimal](9, 2) NULL,           -- Unico prezzo B2B
    [P_StdBo] [decimal](9, 2) NULL,         -- Prezzo B2B con BO
    [M_Base] [decimal](8, 2) NULL,          -- Margine B2B
    [C_TraspBase] [decimal](8, 2) NULL,     -- Costo trasporto B2B
    [C_TraspBaseBo] [decimal](8, 2) NULL,   -- Costo trasporto B2B con BO
    [Note_Std] [varchar](200) NULL,         -- Note calcolo B2B
    [OrderB2b] [int] NULL,                  -- Ordine B2B
    
    -- ===== CAMPI LISTINO PIATTAFORME =====
    [P_T24_24H] [decimal](9, 2) NULL,       -- Prezzo Piattaforme Italia
    [P_T24_48H] [decimal](9, 2) NULL,       -- Prezzo Piattaforme 48H (se serve)
    [P_T24_72H] [decimal](9, 2) NULL,       -- Prezzo Piattaforme 72H (se serve)
    [P_T24_GER] [decimal](9, 2) NULL,       -- Prezzo Germania
    [P_T24_SPA] [decimal](9, 2) NULL,       -- Prezzo Spagna
    [P_T24_AUS] [decimal](9, 2) NULL,       -- Prezzo Austria
    [P_T24_FRA] [decimal](9, 2) NULL,       -- Prezzo Francia
    [P_T24_BEL] [decimal](9, 2) NULL,       -- Prezzo Belgio
    [P_T24_LUS] [decimal](9, 2) NULL,       -- Prezzo Lussemburgo
    [P_T24_OLA] [decimal](9, 2) NULL,       -- Prezzo Olanda
    [P_T24_POL] [decimal](9, 2) NULL,       -- Prezzo Polonia
    [P_T24_Uk_Danim] [decimal](9, 2) NULL,  -- Prezzo UK/Danimarca
    [M_T24] [decimal](8, 2) NULL,           -- Margine Piattaforme
    [M-T24] [decimal](8, 2) NULL,           -- Margine Minus Piattaforme
    [M+T24] [decimal](8, 2) NULL,           -- Margine Plus Piattaforme
    [C_TraspT24] [decimal](8, 2) NULL,      -- Costo trasporto Piattaforme
    [Provv_PiattT24] [decimal](8, 2) NULL,  -- Provvigione Piattaforme
    [PosT24] [int] NULL,                    -- Posizione Piattaforme
    [Note_T24] [varchar](200) NULL,         -- Note calcolo Piattaforme
    
    -- ===== CAMPI LISTINO COLLEGATI (NUOVI) =====
    [P_Collegati] [decimal](9, 2) NULL,     -- Prezzo Collegati Italia
    [P_Collegati_GER] [decimal](9, 2) NULL, -- Prezzo Collegati Germania
    [P_Collegati_SPA] [decimal](9, 2) NULL, -- Prezzo Collegati Spagna
    [P_Collegati_AUS] [decimal](9, 2) NULL, -- Prezzo Collegati Austria
    [P_Collegati_FRA] [decimal](9, 2) NULL, -- Prezzo Collegati Francia
    [P_Collegati_BEL] [decimal](9, 2) NULL, -- Prezzo Collegati Belgio
    [P_Collegati_LUS] [decimal](9, 2) NULL, -- Prezzo Collegati Lussemburgo
    [P_Collegati_OLA] [decimal](9, 2) NULL, -- Prezzo Collegati Olanda
    [P_Collegati_POL] [decimal](9, 2) NULL, -- Prezzo Collegati Polonia
    [P_Collegati_UK] [decimal](9, 2) NULL,  -- Prezzo Collegati UK/Danimarca
    [M_Collegati] [decimal](8, 2) NULL,     -- Margine Collegati
    [C_TraspCollegati] [decimal](8, 2) NULL,-- Costo trasporto Collegati
    [Note_Collegati] [varchar](200) NULL,   -- Note calcolo Collegati
    
    -- ===== CAMPI COSTI SPEDIZIONE PER PAESE =====
    [C_PesoGerFra] [decimal](8, 2) NULL,    -- Costo peso Germania/Francia
    [C_PesoSpa] [decimal](8, 2) NULL,       -- Costo peso Spagna
    [C_PesoAust] [decimal](8, 2) NULL,      -- Costo peso Austria
    [C_PesoT24] [decimal](8, 2) NULL,       -- Costo peso base T24
    
    -- ===== CAMPI RANKING E POSIZIONAMENTO =====
    [P_Prec_T24] [decimal](8, 2) NULL,      -- Prezzo precedente T24
    [P_1Pos_T24] [decimal](8, 2) NULL,      -- Prezzo 1° posizione T24
    [Diff_T24] [decimal](8, 2) NULL,        -- Differenza T24
    [P_Min_T24] [decimal](8, 2) NULL,       -- Prezzo minimo T24
    [P_Max_T24] [decimal](8, 2) NULL,       -- Prezzo massimo T24
    [P_Ricalc_T24] [decimal](8, 2) NULL,    -- Prezzo ricalcolato T24
    [PosPrec_T24] [varchar](20) NULL,       -- Posizione precedente T24
    [Note_T24_Rank] [varchar](200) NULL,    -- Note ranking T24
    
    -- ===== CAMPI COMUNI E UTILITA =====
    [Differenza] [decimal](9, 2) NULL,      -- Campo differenza generico
    [Eccezzioni] [nchar](50) NULL,          -- Eccezioni
    [Note_Base] [varchar](200) NULL,        -- Note generiche
    
    -- ========================================
    -- NUOVI CAMPI ID REGOLE (NUOVO SISTEMA)
    -- ========================================
    [ID_RegoleB2B] [int] NULL,
    [ID_RegolePiattaforme] [int] NULL,
    [ID_RegoleCollegati] [int] NULL,
    
    CONSTRAINT [PK_OfferteWeb_Tmp] PRIMARY KEY CLUSTERED ([IdOffWeb] ASC)
) ON [PRIMARY]

PRINT 'Nuova tabella OfferteWeb_Tmp creata con struttura ottimizzata!'
PRINT ''
PRINT 'CAMPI ELIMINATI (non più necessari):'
PRINT '- P_Base, P_BaseBo, P_Top, P_TopBo (B2B semplificato a solo P_Std)'
PRINT '- Tutti i campi 07ZR (sistema obsoleto)'
PRINT '- TipoPubPiatt (sostituito da fasce prezzo)'
PRINT '- Campi Marca1-4 (non utilizzati)'
PRINT '- P_GommeAuto, P_Esteri_* (consolidati in sistema paese)'
PRINT '- Campi ridondanti e inutilizzati'
PRINT ''
PRINT 'CAMPI AGGIUNTI:'
PRINT '- P_Collegati_* per nuovo listino Collegati'
PRINT '- M_Collegati, C_TraspCollegati, Note_Collegati'
PRINT '- Struttura ottimizzata per 3 listini: B2B, Piattaforme, Collegati'
PRINT '- ID_RegoleB2B, ID_RegolePiattaforme, ID_RegoleCollegati'

GO 