USE [PiattaformeWeb]
GO

-- =============================================
-- Author: Sistema Ristrutturato
-- Create date: 2025-01-02
-- Description: Esempio di utilizzo RicaricoPercentuale
-- =============================================

/****** Script di Esempio: RicaricoPercentuale ******/

-- =============================================
-- ESEMPIO: Impostazione RicaricoPercentuale
-- =============================================

-- Esempio 1: Impostare un ricarico del 25% per pneumatici Vettura fascia 60-75€
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = 1.25 -- +25% sul prezzo di acquisto
WHERE NomeListino = 'B2B' 
  AND Settore = 'Vettura' 
  AND CifraIn = 60.01 
  AND CifraOut = 75.00

-- Esempio 2: Impostare un ricarico del 30% per pneumatici Piattaforme fascia 130-160€
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = 1.30 -- +30% sul prezzo di acquisto
WHERE NomeListino = 'Piattaforme' 
  AND Settore = 'Vettura' 
  AND CifraIn = 130.01 
  AND CifraOut = 160.00

-- Esempio 3: Rimuovere il ricarico percentuale (tornare ai margini fissi)
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = NULL -- Torna al sistema margini fissi
WHERE NomeListino = 'B2B' 
  AND Settore = 'Vettura' 
  AND CifraIn = 60.01 
  AND CifraOut = 75.00

-- =============================================
-- QUERY DI CONTROLLO
-- =============================================

-- Visualizza regole con RicaricoPercentuale impostato
SELECT 
    NomeListino,
    Settore,
    CAST(CifraIn AS varchar(10)) + ' - ' + CAST(CifraOut AS varchar(10)) AS FasciaPrezzo,
    Margine AS MargineClassico,
    RicaricoPercentuale,
    CASE 
        WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 
        THEN 'Sistema Percentuale'
        ELSE 'Sistema Margini'
    END AS SistemaInUso
FROM RegoleListiniDistribuzione
WHERE RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0
ORDER BY NomeListino, Settore, CifraIn

-- =============================================
-- ESEMPIO CALCOLO CONFRONTO
-- =============================================

-- Simulazione calcolo prezzi per un pneumatico da 70€
DECLARE @PrezzoAcquisto decimal(10,2) = 70.00
DECLARE @CostoTrasp decimal(10,2) = 4.40
DECLARE @ProvvPiatt decimal(10,4) = 1.013

SELECT 
    'Esempio Calcolo Pneumatico ' + CAST(@PrezzoAcquisto AS varchar(10)) + '€' AS Descrizione,
    NomeListino,
    Settore,
    
    -- Sistema Classico
    @PrezzoAcquisto + Margine + @CostoTrasp AS PrezzoSistemaClassico,
    
    -- Sistema Percentuale (se abilitato)
    CASE 
        WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 
        THEN (@PrezzoAcquisto * RicaricoPercentuale) + @CostoTrasp
        ELSE NULL
    END AS PrezzoSistemaPercentuale,
    
    -- Differenza
    CASE 
        WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 
        THEN ((@PrezzoAcquisto * RicaricoPercentuale) + @CostoTrasp) - (@PrezzoAcquisto + Margine + @CostoTrasp)
        ELSE NULL
    END AS Differenza,
    
    -- Sistema utilizzato
    CASE 
        WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 
        THEN 'Sistema Percentuale (' + CAST(RicaricoPercentuale AS varchar(10)) + ')'
        ELSE 'Sistema Margini (' + CAST(Margine AS varchar(10)) + '€)'
    END AS SistemaAttivo
    
FROM RegoleListiniDistribuzione
WHERE @PrezzoAcquisto BETWEEN CifraIn AND CifraOut
  AND Settore = 'Vettura'
ORDER BY NomeListino

-- =============================================
-- BATCH UPDATE DI ESEMPIO
-- =============================================

/*
-- Esempio: Convertire tutto il listino B2B Vettura a sistema percentuale
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = CASE 
    WHEN CifraOut <= 50 THEN 1.20      -- +20% per pneumatici economici
    WHEN CifraOut <= 100 THEN 1.25     -- +25% per pneumatici medi
    WHEN CifraOut <= 200 THEN 1.30     -- +30% per pneumatici premium
    ELSE 1.35                          -- +35% per pneumatici top
END
WHERE NomeListino = 'B2B' AND Settore = 'Vettura'

-- Esempio: Convertire tutto il listino Piattaforme Autocarro a sistema percentuale
UPDATE RegoleListiniDistribuzione 
SET RicaricoPercentuale = 1.40 -- +40% per tutti gli autocarro
WHERE NomeListino = 'Piattaforme' AND Settore = 'Autocarro'
*/

-- =============================================
-- REPORT COMPARATIVO
-- =============================================

-- Query per analizzare l'impatto del nuovo sistema
SELECT 
    'REPORT SISTEMA RICARICO' AS TipoReport,
    COUNT(*) AS TotaleRegole,
    SUM(CASE WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 THEN 1 ELSE 0 END) AS RegoleConPercentuale,
    SUM(CASE WHEN RicaricoPercentuale IS NULL OR RicaricoPercentuale = 0 THEN 1 ELSE 0 END) AS RegoleConMargini,
    CAST(
        (SUM(CASE WHEN RicaricoPercentuale IS NOT NULL AND RicaricoPercentuale > 0 THEN 1 ELSE 0 END) * 100.0) / COUNT(*)
    AS decimal(5,2)) AS PercentualeConvertite
FROM RegoleListiniDistribuzione

PRINT 'Script di esempio RicaricoPercentuale completato!'
GO 