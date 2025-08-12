# Istruzioni per lo Script di Aggiornamento Date PM_

## 📋 Panoramica
Questo script VBA aggiorna automaticamente le date quando modifichi i prezzi manuali (colonne PM_). Funziona dinamicamente con i nomi delle colonne, quindi puoi cambiare l'ordine delle colonne senza problemi.

## 🔧 Caratteristiche principali
- ✅ **Dinamico**: Funziona con i nomi delle colonne, non con posizioni fisse
- ✅ **Automatico**: Si attiva ogni volta che modifichi una cella PM_
- ✅ **Intelligente**: Trova automaticamente le colonne PM_ e le loro corrispondenti PM_..._Data
- ✅ **Flessibile**: Funziona indipendentemente dall'ordine delle colonne

## 🎯 Colonne gestite
Lo script gestisce automaticamente queste coppie di colonne:
- `PM_Std` → `PM_Std_Data`
- `PM_T24` → `PM_T24_Data`
- `PM_B2b` → `PM_B2b_Data`
- `PM_Collegati` → `PM_Collegati_Data`

## 📥 Installazione

### ⚠️ IMPORTANTE: Questo script va nel MODULO DEL FOGLIO, non in un modulo standard!

1. **Aprire Excel** con il file dei prezzi manuali
2. **Premere Alt+F11** per aprire l'editor VBA
3. **Nel Project Explorer** (pannello di sinistra), trovare il nome del foglio di lavoro
   - Esempio: `Foglio1 (Foglio1)` o `Sheet1 (Sheet1)`
4. **Fare doppio clic** sul nome del foglio nel Project Explorer
5. **Copiare e incollare** tutto il codice da `Script_Aggiornamento_Date_PM.vba`
6. **Salvare** il file Excel come "Excel Macro-Enabled Workbook (.xlsm)"

### 🔍 Verifica installazione
Dopo l'installazione, puoi testare se tutto funziona:
1. **Premere Alt+F8** per aprire le macro
2. **Eseguire `TestPMColumns`** per vedere quali colonne sono state trovate
3. **Dovrebbe apparire** un messaggio con l'elenco delle colonne PM_ e le loro date corrispondenti

## 🚀 Utilizzo

### Funzionamento automatico
Una volta installato, lo script funziona automaticamente:
1. **Modifica una cella** in una colonna PM_ (es. PM_Std, PM_T24, etc.)
2. **La data viene gestita automaticamente** nella colonna corrispondente (es. PM_Std_Data):
   - **Valore valido** (es. 25.50, 100, 15.25) → **Aggiorna la data** con la data corrente
   - **Valore 0** → **Cancella la data** (cella vuota)
   - **Cella vuota** → **Cancella la data** (cella vuota)
   - **Stringa vuota** → **Cancella la data** (cella vuota)

### Macro utili
- **`TestPMColumns`**: Mostra quali colonne PM_ sono state trovate
- **`TestComportamentoDate`**: Testa il comportamento con diversi valori (0, vuoto, valore valido)
- **`AbilitaAggiornamentoAutomatico`**: Riabilita l'aggiornamento automatico
- **`DisabilitaAggiornamentoAutomatico`**: Disabilita temporaneamente l'aggiornamento

## 📝 Esempio di funzionamento

### Prima dell'installazione (script fisso):
```vba
' Funziona solo con posizioni fisse
Set KeyCells = Range("AI2:AI170000")  ' Solo colonna AI
Range("AO" & Target.Row).Value = Date ' Solo colonna AO
```

### Dopo l'installazione (script dinamico):
```
Colonne PM_ trovate e le loro corrispondenti colonne data:

✓ PM_STD (Col 35) → PM_STD_DATA (Col 39)
✓ PM_T24 (Col 36) → PM_T24_DATA (Col 40)
✓ PM_B2B (Col 37) → PM_B2B_DATA (Col 41)
✓ PM_COLLEGATI (Col 38) → PM_COLLEGATI_DATA (Col 42)
```

### Esempi pratici di gestione date:

| **Azione in PM_Std** | **Risultato in PM_Std_Data** | **Spiegazione** |
|----------------------|------------------------------|------------------|
| Inserisci `25.50` | `15/01/2024` | Data corrente |
| Inserisci `0` | `(vuota)` | Data cancellata |
| Cancelli contenuto | `(vuota)` | Data cancellata |
| Inserisci `100` | `15/01/2024` | Data corrente |
| Inserisci `-5.25` | `15/01/2024` | Data corrente |

## 🔄 Vantaggi dello script dinamico

### ✅ Vantaggi
- **Flessibilità**: Puoi cambiare l'ordine delle colonne
- **Manutenibilità**: Aggiungi nuove colonne PM_ senza modificare il codice
- **Robustezza**: Funziona anche se inserisci/elimini colonne
- **Scalabilità**: Gestisce automaticamente tutte le colonne PM_

### ❌ Limitazioni del vecchio script
- Posizioni fisse (AI, AO)
- Una sola colonna PM_
- Si rompe se cambi l'ordine delle colonne

## 🛠️ Personalizzazioni

### Cambiare la riga delle intestazioni
Se le intestazioni non sono nella riga 1, modifica questa riga:
```vba
headerRow = 1 ' Cambia questo numero
```

### Aggiungere nuove colonne PM_
Lo script funziona automaticamente con qualsiasi colonna che:
- Inizia con "PM_"
- Ha una colonna corrispondente che finisce con "_DATA"

Esempio:
- `PM_Nuovo` → `PM_Nuovo_Data`
- `PM_Speciale` → `PM_Speciale_Data`

## ⚠️ Risoluzione problemi

### Lo script non funziona
1. **Verifica che sia nel modulo del foglio** (non in un modulo standard)
2. **Controlla che le macro siano abilitate**
3. **Esegui `TestPMColumns`** per vedere se trova le colonne
4. **Verifica che `Application.EnableEvents = True`**

### Le colonne non vengono trovate
1. **Controlla i nomi delle colonne** nell'intestazione
2. **Assicurati che inizino con "PM_"**
3. **Verifica che esistano le colonne "_DATA" corrispondenti**

### Testare la cancellazione automatica
1. **Esegui `TestComportamentoDate`** per verificare il comportamento
2. **Inserisci un valore valido** in una colonna PM_ → La data dovrebbe aggiornarsi
3. **Inserisci 0** → La data dovrebbe cancellarsi
4. **Cancella il contenuto** (premi Canc) → La data dovrebbe cancellarsi

### Disabilitare temporaneamente
Se vuoi disabilitare l'aggiornamento automatico:
```vba
Application.EnableEvents = False  ' Disabilita
Application.EnableEvents = True   ' Riabilita
```

## 🔧 Codice di esempio per test

```vba
' Testa il funzionamento completo
Sub TestManuale()
    ' Test 1: Inserisci un valore valido
    Range("PM_Std").Cells(2, 1).Value = 100
    ' La data in PM_Std_Data dovrebbe aggiornarsi automaticamente
    
    ' Test 2: Inserisci 0 per cancellare la data
    Range("PM_Std").Cells(2, 1).Value = 0
    ' La data in PM_Std_Data dovrebbe cancellarsi
    
    ' Test 3: Svuota la cella
    Range("PM_Std").Cells(2, 1).Value = ""
    ' La data in PM_Std_Data dovrebbe rimanere vuota
End Sub

' Testa automaticamente tutti i comportamenti
Sub TestAutomatico()
    Call TestComportamentoDate
End Sub
```

## 📞 Supporto
Se hai problemi:
1. Verifica che il codice sia nel modulo del foglio corretto
2. Controlla che i nomi delle colonne siano corretti
3. Esegui `TestPMColumns` per diagnosticare
4. Assicurati che le macro siano abilitate

---
*Script dinamico per l'aggiornamento automatico delle date PM_* 