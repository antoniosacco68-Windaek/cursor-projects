USE I24DB

/*
SCRIPT DI TEST PER VERIFICARE CHE L'ORDINE VENGA MANTENUTO
Esegui questo script DOPO aver eseguito l'importazione per verificare che funzioni
*/

-- Test 1: Verifica che le prime righe siano nell'ordine corretto
PRINT '=== TEST 1: Verifica ordine prime 20 righe ==='
SELECT TOP 20 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NumeroRiga,
    Targa
FROM Inventario_Depositi

-- Test 2: Cerca le "FILA" per verificare che siano nella sequenza corretta
PRINT '=== TEST 2: Verifica posizione delle FILA ==='
SELECT 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as PosizioneNellaTabella,
    Targa
FROM Inventario_Depositi 
WHERE Targa LIKE '%FILA%'
ORDER BY ROW_NUMBER() OVER (ORDER BY (SELECT NULL))

-- Test 3: Verifica che dopo ogni FILA ci siano le gomme corrispondenti
PRINT '=== TEST 3: Verifica che dopo BG1. FILA 1 ci siano le gomme giuste ==='
WITH RigheNumerate AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NumeroRiga,
        Targa
    FROM Inventario_Depositi
),
PosizioneFila1 AS (
    SELECT NumeroRiga as PosFila1
    FROM RigheNumerate 
    WHERE Targa = 'BG1. FILA 1'
)
SELECT TOP 10
    r.NumeroRiga,
    r.Targa,
    'Dovrebbe essere dopo FILA 1' as Verifica
FROM RigheNumerate r, PosizioneFila1 p
WHERE r.NumeroRiga > p.PosFila1 
    AND r.NumeroRiga <= p.PosFila1 + 10
ORDER BY r.NumeroRiga

-- Test 4: Confronto con l'ordine atteso dal CSV (prime 10 righe)
PRINT '=== TEST 4: Le prime 10 righe dovrebbero essere: ==='
PRINT 'BG1. FILA 1'
PRINT 'GV128PA-242350'
PRINT 'FX467CC-242354'
PRINT 'GR939YH-247488'
PRINT 'GH577HP-229718'
PRINT 'GV266RL-247490'
PRINT 'FR020FV-229682'
PRINT 'GV775ZC-245574'
PRINT 'GN346XT-245545'
PRINT 'GT661XZ-245170'

PRINT '=== Risultato effettivo: ==='
SELECT TOP 10 
    ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) as NumeroRiga,
    Targa
FROM Inventario_Depositi 