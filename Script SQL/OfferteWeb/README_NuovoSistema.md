# 🚀 NUOVO SISTEMA DISTRIBUZIONE LISTINI

## 📖 Panoramica

Questo documento descrive il **nuovo sistema ristrutturato** per la gestione dei listini prezzi, progettato per sostituire la vecchia architettura con un approccio più pulito, modulare e manutenibile.

## 🎯 Obiettivi della Ristrutturazione

### ✅ Problemi Risolti
- **Unificazione regole**: Una sola tabella `RegoleListiniDistribuzione` invece di due separate
- **Eliminazione TipoPubPiatt**: Logica basata solo su fasce di prezzo
- **Logiche indipendenti**: Ogni listino con la propria logica di calcolo
- **No più sovrascrizioni B2B**: Fine delle sovrascrizioni con `P_PiattSenzaTrasp`
- **Sistema parallelo**: Sviluppo senza impattare la produzione

### 🔧 Nuova Architettura
- **3 Listini unificati**: `B2B`, `Piattaforme`, `Collegati`
- **Fasce di prezzo**: Basate su riferimento `Tyre24_24H`
- **Tabelle dedicate**: `RegoleListiniDistribuzione` e `OfferteWeb_Tmp`

## 📂 Struttura File

### 🛠️ Script Principali
1. **`SP_InitializeDistributionTables.sql`** - Inizializzazione tabelle
2. **`SP_CalculatePriceRanges.sql`** - Calcolo fasce prezzi e margini
3. **`SP_GenerateB2BPrices.sql`** - Generazione prezzi B2B
4. **`SP_GeneratePlatformPrices.sql`** - Generazione prezzi Piattaforme
5. **`SP_NewDistributionSystem.sql`** - Script orchestratore principale
6. **`SP_CompareDistributionSystems.sql`** - Confronto vecchio vs nuovo

### 📊 Tabelle Nuove
- **`RegoleListiniDistribuzione`** - Regole unificate per tutti i listini
- **`OfferteWeb_Tmp`** - Tabella di test (copia di `OfferteWeb_1Pass`)

## 🚀 Come Utilizzare il Nuovo Sistema

### 1️⃣ Prima Esecuzione (Setup)
```sql
-- Esegui una sola volta per creare le tabelle
EXEC SP_InitializeDistributionTables
```

### 2️⃣ Esecuzione Completa
```sql
-- Esegui questo per elaborare tutti i listini
EXEC SP_NewDistributionSystem
```

### 3️⃣ Confronto con Sistema Vecchio
```sql
-- Per verificare le differenze
EXEC SP_CompareDistributionSystems
```

## 🔍 Logica del Nuovo Sistema

### 📈 Fasce di Prezzo
Il sistema utilizza fasce di prezzo **invece** di `TipoPubPiatt`:

| Settore | Campo Riferimento | Fasce |
|---------|------------------|-------|
| Vettura | `Prezzo` | 0-50, 50-100, 100-200, 200+ |
| Autocarro | `Diametro` | 13-16, 16-20, 20-22.5, 22.5+ |
| MotoScooter | `Prezzo` | 0-50, 50-100, 100-200, 200+ |

### 💰 Calcolo Prezzi

#### **Listino B2B**
```
Prezzo_B2B = Prezzo_Acquisto + Margine_Fascia_Prezzo
```

#### **Listino Piattaforme**
```
Prezzo_Piattaforme = (Prezzo_Acquisto + Margine + Costo_Trasporto) × Provvigione_Piattaforma
```

#### **Listino Collegati**
```
Prezzo_Collegati = Prezzo_Piattaforme ÷ Provvigione_Piattaforma
```

### 🌍 Gestione Mercati Esteri
- **Costi spedizione**: Mantenuti per paese (Germania, Spagna, Austria, ecc.)
- **PFU Francia**: Rimosso (valore = 0)
- **Commissioni**: Uniformi in percentuale per tutti i settori

## ⚙️ Configurazione

### 🎛️ Parametri Principali
- **Provvigione Piattaforma**: `1.013` (1.3%)
- **Fasce Prezzo**: Configurabili in `RegoleListiniDistribuzione`
- **Margini Stagionali**: Estivo, Invernale, 4 Stagioni

### 📝 Personalizzazione Regole
Per modificare margini o fasce:
```sql
UPDATE RegoleListiniDistribuzione 
SET Margine = [nuovo_valore]
WHERE NomeListino = '[B2B|Piattaforme|Collegati]' 
AND Settore = '[Vettura|Autocarro|MotoScooter]'
AND CifraIn = [fascia_inizio]
```

## 🔄 Migrazione Graduale

### 🚧 Fase di Test (Attuale)
- Sistema vecchio continua a girare ogni ora
- Nuovo sistema lavora su `OfferteWeb_Tmp`
- Confronti e verifiche continue

### 🎯 Fase di Switch
1. **Validazione completa** risultati nuovo sistema
2. **Backup** sistema vecchio
3. **Sostituzione** chiamata da `SP_NewDistributionSystem`
4. **Aggiornamento** `OfferteWeb` finale

### 🔙 Piano di Rollback
In caso di problemi:
1. **Stop** esecuzione nuovo sistema
2. **Ripristino** vecchi script
3. **Analisi** problematiche
4. **Correzione** e nuovo test

## 📊 Monitoraggio e Controlli

### 🔍 Controlli Automatici
- **Prezzi negativi**: Automaticamente esclusi
- **Articoli mancanti**: Segnalazione in log
- **Differenze significative**: Report di confronto
- **Statistiche**: Riepilogo articoli processati

### 📈 Report Disponibili
- **Confronto listini**: Vecchio vs Nuovo
- **Statistiche per settore**: Distribuzione prezzi
- **Articoli problematici**: Top differenze
- **Performance**: Tempi di elaborazione

## 🛡️ Sicurezza e Stabilità

### ✅ Vantaggi del Nuovo Sistema
- **Isolamento**: Non tocca il sistema in produzione
- **Modulare**: Ogni componente indipendente
- **Tracciabile**: Log dettagliati per ogni fase
- **Verificabile**: Confronti automatici con sistema vecchio
- **Rollback**: Possibilità di tornare indietro facilmente

### ⚠️ Attenzioni
- **Prima esecuzione**: Verificare sempre con `SP_CompareDistributionSystems`
- **Regole custom**: Backup delle regole prima di modifiche
- **Performance**: Monitorare tempi di esecuzione
- **Spazio disco**: `OfferteWeb_Tmp` occupa spazio aggiuntivo

## 🎓 Per Sviluppatori

### 🧩 Struttura Modulare
Ogni stored procedure è indipendente e può essere:
- **Testata singolarmente**
- **Modificata senza impatti**
- **Estesa con nuove funzionalità**

### 🔧 Estensioni Future
- **Nuovi listini**: Aggiungere semplicemente nuove procedure
- **Nuove logiche**: Modificare solo le procedure interessate
- **Nuovi mercati**: Aggiungere campi e logiche in `SP_GeneratePlatformPrices`

## 📞 Supporto

Per problemi o domande:
1. **Controllare i log** delle stored procedure
2. **Eseguire** `SP_CompareDistributionSystems`
3. **Verificare** i dati in `RegoleListiniDistribuzione`
4. **Contattare** il team di sviluppo

---

*Documento creato: 2025-01-02*
*Sistema progettato per sostituire la logica legacy mantenendo piena compatibilità* 