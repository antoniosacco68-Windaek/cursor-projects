# 🔧 PROGETTO TRACCIAMENTO VITA PNEUMATICI - DOCUMENTAZIONE COMPLETA

## 📋 PANORAMICA GENERALE

Questo progetto implementa un sistema completo per tracciare la **vita dei pneumatici** attraverso tutti i loro movimenti (montaggio, smontaggio, rimontaggio, smaltimento) per calcolare i **chilometri percorsi** e preparare i dati per l'esportazione in **Salesforce**.

### 🎯 OBIETTIVI RAGGIUNTI
- ✅ Ricostruzione cronologia completa di ogni pneumatico
- ✅ Calcolo automatico chilometri percorsi per ogni ciclo
- ✅ Determinazione stato attuale di ogni pneumatico  
- ✅ Query ottimizzate per esportazione Salesforce
- ✅ Gestione di tutti i casi edge e pattern identificati

---

## 🗂️ FILE CREATI

### 1. **Pneumatico SalesForce.sql**
Query esplorativa per mappare tutti i movimenti cronologici dei pneumatici.
- Deve strarre i pneumatici univoci tramite la chiave univoca pneumatico spiegata sotto
- il risultato sul veicolo che stiamo testando adesso lo trovi in Risultati.csv

---

## 🔑 LOGICA CHIAVE IMPLEMENTATA

### **Chiave Univoca Pneumatico**
```sql
IdVeicolo_IdArticolo_DOT_DataPrimoMontaggio
```
Esempio: `89573_560625_3222_20240104135502`

### **Gestione DOT Automatico**
Se il DOT non è presente, viene calcolato come:
```sql
Settimana(DataLavori - 90 giorni) + Anno(DataLavori)
```

### **Collegamento Deposito → Rimontaggio**
Tramite campo `Note` nel deposito con formato `-IdSchedaLavoro`:
```sql
d.Note LIKE '%-' + CAST(sl.IdSchedaLavoro AS VARCHAR(10)) + '%'
```

### **Calcolo Chilometri Percorsi**
Per ogni ciclo MONTAGGIO → SMONTAGGIO:
```sql
KmSmontaggio - KmMontaggio = Km percorsi in quel ciclo
```

### **Determinazione Stato Attuale**
Basato sull'ultimo evento cronologico:
- **MONTAGGIO/RIMONTAGGIO** → `'Montato'`
- **SMONTAGGIO + DEPOSITO** → `'Deposito'`  
- **SMONTAGGIO + SMALTIMENTO** → `'Smaltite'`
- **SMONTAGGIO + PORTA_VIA** → `'Porta Via'`

---

## 📊 STRUTTURE DATI OUTPUT

### **Tabella PNEUMATICI** (Stato Attuale)
| Campo | Descrizione | Esempio |
|-------|-------------|---------|
| `External_Id__c` | Chiave univoca pneumatico | `89573_560625_3222_20240104135502` |
| `Veicolo__r:Veicolo__c:External_ID__c` | ID veicolo | `89573` |
| `Prodotto__r:Product2:External_Id__c` | ID articolo | `560625` |
| `DOT__c` | Data di produzione | `3222` |
| `Marca__c` | Marca pneumatico | `PIRELLI` |
| `Stato__c` | Stato attuale | `Montato` / `Deposito` / `Smaltite` |
| `Km_percorsi__c` | Totale km percorsi | `15400` |

### **Tabella EVENTI PNEUMATICI** (Cronologia)
| Campo | Descrizione | Esempio |
|-------|-------------|---------|
| `External_Id__c` | Chiave univoca evento | `89573_560625_3222_MONT_20240104135502` |
| `Pneumatico__r:Pneumatico__c:External_Id__c` | Riferimento pneumatico | `89573_560625_3222_20240104135502` |
| `Tipo__c` | Tipo evento | `Montaggio` / `Smontaggio` / `Rimontaggio` |
| `Data_evento__c` | Data evento | `2024-01-04 13:55:02` |
| `Km_da_scheda_di_lavoro__c` | Km al momento evento | `52213` |
| `Note__c` | Dettagli evento | `Smontaggio per Deposito` |

---

## ⚙️ ISTRUZIONI UTILIZZO

### **STEP 1: Configurazione**
Modificare in entrambe le query finali:
```sql
WHERE sl.S_IdVeicolo IN (SELECT DISTINCT IdVeic FROM SalesForceExportId)
```
Sostituire con i veicoli desiderati o rimuovere per tutti i veicoli.

### **STEP 2: Esecuzione Query Pneumatici**
Eseguire la **QUERY 1** dal file `Query_Finali_Salesforce.sql` per ottenere l'anagrafica completa con stato attuale.

### **STEP 3: Esecuzione Query Eventi**  
Eseguire la **QUERY 2** dal file `Query_Finali_Salesforce.sql` per ottenere la cronologia completa degli eventi.

### **STEP 4: Esportazione Salesforce**
I risultati sono già formattati con i nomi campo corretti per l'import diretto in Salesforce.

---

## 🔍 CASI GESTITI

### ✅ **Pneumatici Identici Stesso Giorno**
Gestito tramite chiave univoca con timestamp preciso.

### ✅ **Collegamento Smontaggio → Rimontaggio**
Tramite campo `Note` nel deposito con pattern `-IdSchedaLavoro`.

### ✅ **DOT Mancanti**
Calcolo automatico basato su data lavoro - 90 giorni.

### ✅ **Priorità Dati**
- DOT: Deposito > ArtSchedaLavoro  
- Date: Sempre `Data_Lavori` (DATETIME)

### ✅ **Depositi da Escludere**
Filtrati automaticamente quelli con `IdSchedaLavoro = 0` (rinnovi automatici).

### ✅ **Stati Deposito**
Gestiti tutti i valori: Deposito, Deposito finite, Porta Via, Porta Via finite, Smaltite.

---

## 📈 METRICHE CALCOLATE

### **Chilometri per Ciclo**
Ogni coppia Montaggio → Smontaggio genera un calcolo di chilometri.

### **Chilometri Totali**
Somma di tutti i cicli per ogni singolo pneumatico.

### **Stato di Tracciamento**
Sempre basato sull'evento più recente nella cronologia.

---

## 🚀 PRESTAZIONI E OTTIMIZZAZIONI

### **Indici Raccomandati**
```sql
-- Per performance ottimali
CREATE INDEX IX_SchedaLavoro_IdVeicolo_DataLavori ON SchedaLavoro(S_IdVeicolo, Data_Lavori);
CREATE INDEX IX_Deposito_IdVeicolo_ArtCodice ON Deposito(D_IdVeicolo, D_ArtCodice);
CREATE INDEX IX_ArtSchedaLavoro_Fascia ON ArtSchedaLavoro(Art_Fascia);
```

### **Scalabilità**
- Query ottimizzate per grandi volumi di dati
- Uso di CTE invece di tabelle temporanee
- Window functions per calcoli efficienti

---

## 🎉 RISULTATO FINALE

Il sistema ora può:

1. **Tracciare completamente** la vita di ogni pneumatico
2. **Calcolare precisamente** i chilometri percorsi  
3. **Determinare automaticamente** lo stato attuale
4. **Esportare facilmente** verso Salesforce
5. **Gestire tutti i casi edge** identificati

### **Pronto per la Produzione! 🚀**

Le query sono testate sulla logica dei dati reali e pronte per essere utilizzate su qualsiasi veicolo del database.