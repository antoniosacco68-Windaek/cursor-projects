# STRATEGIA DI INTEGRAZIONE DEL NUOVO SISTEMA

## Situazione Attuale

Hai ragione, mi sono concentrato troppo sulla ristrutturazione finale senza considerare che ci sono **molti passaggi fondamentali** che devono rimanere invariati nella sequenza. 

Il nuovo sistema dei 3 listini non può sostituire tutto, ma deve **integrarsi** in punti specifici della catena esistente.

## Sequenza Completa Attuale (19 passi)

```
1.  AA0_ImpCSV_AzzeraTBL                     ➜ MANTIENI (azzera tabelle)
2.  Importazioni Stock (vari fornitori)      ➜ MANTIENI (dati base)
3.  AD9_CreaPrezziRicambi                    ➜ MANTIENI (ricambi)
4.  AC1_Ceck_Pulizia_CreazioneArticoli       ➜ MANTIENI (controlli)
5.  OWA1_CreaOffwerteWeb                     ➜ MANTIENI (crea OfferteWeb_1Pass)
6.  OWA2_CancellaArticoliDaOffwerteWeb       ➜ MANTIENI (cancellazioni)
7.  AggiornoArticoliB2b                      ➜ MANTIENI (articoli B2B)
8.  AggiornoUtentiB2b                        ➜ MANTIENI (utenti B2B)
9.  OWB1_CreazionePrezziB2b                  ➜ SOSTITUISCI (nuovo B2B)
10. OWB2_CreazionePrezziPiattaforme          ➜ SOSTITUISCI (nuovo Piattaforme)
11. OWB4_CreazionePrezzi_Piatt_B2b           ➜ ELIMINA (logica vecchia)
12. OWB3_CreazionePrezziManuali              ➜ INTEGRA (mantieni manuali)
13. OWC1_CreazioneRanking                    ➜ MODIFICA (nuove logiche)
14. OWC3_Mod_OfferteWeb_T24                  ➜ MANTIENI (modifiche T24)
15. OWE1_EliminoFornitoriDaPubb              ➜ MANTIENI (eliminazioni)
16. OWE2_CreoListinoEsteroEdAltri           ➜ SOSTITUISCI (nuovo sistema)
17. OWD1_InserimentoListiniB2b               ➜ MANTIENI (inserimenti)
18. AggiornoArticoliOfferteWeb               ➜ MANTIENI (aggiornamenti)
19. PreparaFileRankingT24_DE                 ➜ MANTIENI (file Germania)
```

## Strategia di Integrazione

### FASE 1: Preparazione (Passi 1-8) - NESSUNA MODIFICA
Tutti questi passi rimangono **identici** perché:
- Creano la base dati (OfferteWeb_1Pass)
- Gestiscono importazioni e controlli
- Preparano articoli e utenti B2B

### FASE 2: Prezzi (Passi 9-12) - SOSTITUZIONE PARZIALE

**SOSTITUIRE:**
- `OWB1_CreazionePrezziB2b` ➜ con `SP_GenerateB2BPrices`
- `OWB2_CreazionePrezziPiattaforme` ➜ con `SP_GeneratePlatformPrices`

**ELIMINARE:**
- `OWB4_CreazionePrezzi_Piatt_B2b` (logica di sovrascrittura che non vogliamo più)

**INTEGRARE:**
- `OWB3_CreazionePrezziManuali` ➜ aggiungere chiamata a `SP_ApplyManualPrices` alla fine

### FASE 3: Ranking (Passo 13) - MODIFICA

**MODIFICARE:**
- `OWC1_CreazioneRanking` ➜ integrare nuove logiche senza TipoPubPiatt

### FASE 4: Finalizzazione (Passi 14-19) - SOSTITUZIONE PARZIALE

**SOSTITUIRE:**
- `OWE2_CreoListinoEsteroEdAltri` ➜ con nuova logica 3 listini + prezzi Collegati

**MANTENERE:**
- Tutti gli altri passi rimangono identici

## Proposta Implementazione

### Opzione A: Modifiche Graduali (CONSIGLIATA)

1. **Prima fase**: Modificare solo `OWB1` e `OWB2` con nuove logiche
2. **Seconda fase**: Integrare `OWB3` e modificare `OWC1`
3. **Terza fase**: Sostituire `OWE2` con nuova logica esteri
4. **Test parallelo**: Usare OfferteWeb_Tmp per confronti

### Opzione B: Sistema Ibrido

1. Creare `SP_NewDistributionSystem_Hybrid` che:
   - Si inserisce DOPO il passo 8 (AggiornoUtentiB2b)
   - Calcola i 3 listini nelle nuove colonne
   - Lascia le vecchie colonne per compatibilità
   - Permette confronto diretto

### Opzione C: Sostituzione Completa

1. Sostituire i passi 9, 10, 12, 13, 16 in un'unica operazione
2. Rischio più alto ma transizione netta

## Script di Transizione Proposti

### 1. Nuovo OWB1_CreazionePrezziB2b_V2.sql
```sql
-- Sostituisce il vecchio OWB1 con nuove logiche B2B
EXEC SP_CalculatePriceRanges @TargetTable = 'OfferteWeb_1Pass'
EXEC SP_GenerateB2BPrices @TargetTable = 'OfferteWeb_1Pass'
```

### 2. Nuovo OWB2_CreazionePrezziPiattaforme_V2.sql
```sql
-- Sostituisce il vecchio OWB2 con nuove logiche Piattaforme
EXEC SP_GeneratePlatformPrices @TargetTable = 'OfferteWeb_1Pass'
EXEC SP_GenerateCollegatiPrices @TargetTable = 'OfferteWeb_1Pass'
```

### 3. Modifica OWB3_CreazionePrezziManuali.sql
```sql
-- Alla fine dello script esistente, aggiungere:
EXEC SP_ApplyManualPrices @TargetTable = 'OfferteWeb_1Pass'
```

### 4. Nuovo OWE2_CreoListinoEsteroEdAltri_V2.sql
```sql
-- Nuova logica per esteri senza sovrascritture B2B
EXEC SP_CalculateForeignPrices @TargetTable = 'OfferteWeb_1Pass'
-- Mantieni solo logiche specifiche per mercati esteri
```

## Vantaggi di questa Strategia

✅ **Rischio Minimizzato**: Modifiche graduali testabili
✅ **Compatibilità**: Sistema esistente continua a funzionare
✅ **Rollback Semplice**: Ogni fase può essere annullata
✅ **Testing Parallelo**: OfferteWeb_Tmp per confronti
✅ **Logiche Preservate**: Mantiene importazioni, controlli, manuali

## Domande per Te

1. **Preferisci l'approccio graduale (Opzione A)?**
2. **Quale passo vuoi modificare per primo?** (Suggerisco OWB1)
3. **Vuoi che creiamo OfferteWeb_Tmp per test paralleli?**
4. **Ci sono logiche specifiche in OWB3 che devo preservare?**

## Prossimi Passi Proposti

1. Analizziamo insieme `OWB1_CreazionePrezziB2b.sql` in dettaglio
2. Creiamo `OWB1_CreazionePrezziB2b_V2.sql` con nuove logiche
3. Testiamo la sostituzione su un subset di dati
4. Procediamo con gli altri script uno alla volta

**La chiave è integrare il nuovo sistema DENTRO la sequenza esistente, non sostituirla completamente.** 