# ✅ CHECKLIST PER TESTARE L'ORDINAMENTO

## Passi per verificare che l'importazione mantenga l'ordine:

### 1. PRIMA del test
- [ ] Assicurati che la tabella `Inventario_Depositi` esista
- [ ] Se non esiste, creala con: `CREATE TABLE Inventario_Depositi (Targa NVARCHAR(255))`

### 2. ESEGUI l'importazione
- [ ] Esegui lo script `00_importazioneCsv_BgInventarioDepositi.sql`
- [ ] Verifica che non ci siano errori nell'output

### 3. ESEGUI il test di verifica  
- [ ] Esegui lo script `TEST_VerificaOrdine.sql`

### 4. VERIFICA i risultati:

#### ✅ Test 1 - Prime 20 righe
Le prime righe dovrebbero essere:
1. `BG1. FILA 1`
2. `GV128PA-242350`
3. `FX467CC-242354`
4. `GR939YH-247488`
5. `GH577HP-229718`
...

#### ✅ Test 2 - Posizione delle FILA
Dovrebbero apparire in quest'ordine:
1. `BG1. FILA 1` (posizione ~1)
2. `BG1. FILA 2` (posizione ~37)  
3. `BG1. FILA 3` (posizione ~70)
4. `BG1. FILA 4` (posizione ~102)
5. `BG1. FILA 5` (posizione ~140)
6. `BG1. FILA 6` (posizione ~177)

#### ✅ Test 3 - Gomme dopo FILA 1
Dopo `BG1. FILA 1` dovrebbero esserci nell'ordine:
- `GV128PA-242350`
- `FX467CC-242354`
- `GR939YH-247488`
- ecc...

## 🚨 SE IL TEST FALLISCE:
- L'ordine NON è mantenuto
- Le gomme potrebbero essere associate alle scansie sbagliate
- Controlla la sintassi SQL e la versione di SQL Server

## ✅ SE IL TEST PASSA:  
- L'ordine È mantenuto correttamente
- Le gomme saranno associate alle scansie giuste
- Il lettore di codici a barre funzionerà perfettamente! 