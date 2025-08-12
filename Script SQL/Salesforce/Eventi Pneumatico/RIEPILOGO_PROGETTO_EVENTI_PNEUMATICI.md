# RIEPILOGO PROGETTO EVENTI PNEUMATICI - SALESFORCE

## 🎯 OBIETTIVO FINALE
Generare eventi cronologici corretti per ogni pneumatico del database SQL Server per export a Salesforce.

## 📋 REQUISITI FONDAMENTALI

### 1. ANAGRAFICA PNEUMATICI (Funziona già!)
- **File**: `Pneumatico SalesForce.sql` 
- **Chiave univoca**: `Veicolo + ART_ID + DOT + IdSchedaLavoro`
- **Stati**: Montata, Depositata, Smaltita, Porta Via
- **Include**: Pneumatici montati + phantom (solo deposito)

### 2. EVENTI PNEUMATICI (Da sistemare)
- **Tipi eventi**: Montaggio, Smontaggio, Rimontaggio
- **Cronologia**: Per ogni pneumatico dalla nascita alla morte
- **Collegamenti**: SchedaLavoro → ArtSchedaLavoro → Deposito

## 🚨 PROBLEMI IDENTIFICATI

### Problema principale: Eventi duplicati/mancanti
- **Query originale** (`Query_Eventi_SOLO_ANTERIORI.sql`): Funzionava bene ma mancavano posteriori
- **Query cursor** (`Query_Eventi_Con_Tracciamento_Completo.sql`): Troppo complessa, genera duplicati
- **Query semplificata** (`Query_Eventi_SEMPLICE_CORRETTA.sql`): Troppo restrittiva, manca cronologia

### Casi problematici:
1. **Scheda 481630**: Monta 3 pneumatici (2 ant + 1 post), smaltisce 3 diversi (stesso codice, DOT diverso)
2. **Scheda 505233**: Solo servizio stagionale (@MS_STAG), nessun pneumatico fisico, solo rimontaggio da deposito
3. **Servizi stagionali**: Rimontaggio automatico da deposito tramite campo `Note` con IdSchedaLavoro

## 📊 DATI DI ESEMPIO (Veicolo 171590 - FR953GP)

### Cronologia reale:
```
444666 (17000 km): MONTA 2854022 DOT:3622 + 3253522 DOT:3822
479279 (27000 km): RIMONTA 2854022-PIR-3992900 DOT:3622 (da deposito)  
481630 (27100 km): MONTA 2854022 DOT:0524 + SMALTISCE 2854022 DOT:3622
505233 (36300 km): RIMONTA 2854022-PIR-3992900 DOT:3622 (servizio @MS_STAG)
540304 (48000 km): MONTA nuovi + DEPOSITA 2854022-PIR-3992900 DOT:3622
```

## 🔧 STRATEGIA CONSIGLIATA

### Approccio 1: Sistemare l'originale funzionante
- **Base**: `Query_Eventi_SOLO_ANTERIORI.sql` (funzionava!)
- **Aggiungere**: Gestione pneumatici posteriori 
- **Correggere**: Solo il problema specifico dei duplicati

### Approccio 2: Logica a step
1. **STEP 1**: Solo MONTAGGI diretti (da ArtSchedaLavoro)
2. **STEP 2**: Solo SMONTAGGI diretti (da Deposito)  
3. **STEP 3**: Solo RIMONTAGGI (da servizi stagionali)
4. **STEP 4**: Unire tutto e ordinare cronologicamente

## 📁 FILES UTILI
- ✅ `Pneumatico SalesForce.sql` - Anagrafica corretta che funziona
- ✅ `Query_Eventi_SOLO_ANTERIORI.sql` - Eventi base funzionanti
- ❌ `Query_Eventi_Con_Tracciamento_Completo.sql` - Troppo complesso
- ❌ `Query_Eventi_SEMPLICE_CORRETTA.sql` - Troppo restrittivo

## 🎯 PROSSIMI PASSI SUGGERITI
1. Ripartire da `Query_Eventi_SOLO_ANTERIORI.sql`
2. Aggiungere solo gestione posteriori con UNION ALL
3. Testare su veicolo 171590 per vedere cronologia completa
4. Correggere problemi specifici uno alla volta

## 📝 NOTE TECNICHE
- **DOT**: Se mancante, calcolare dalla data scheda: `FORMAT(DATEPART(week, DATEADD(day, -90, Data_Lavori)), '00') + FORMAT(Data_Lavori, 'yy')`
- **Rimontaggi**: Collegamento via `Deposito.Note LIKE '%-IdSchedaLavoro-%'` e `Rimontate = 1`
- **Servizi stagionali**: `Art_Codice LIKE '%MS_STAG%'`
- **Pneumatici**: `Art_Fascia IN ('A','B','C','U','R')`

---
**OBIETTIVO**: Cronologia completa e corretta per ogni pneumatico, senza duplicati, senza eventi mancanti.
