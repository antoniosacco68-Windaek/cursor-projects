# Istruzioni per l'Esportazione Excel e Importazione SQL Server

## 📋 Panoramica
Questi script permettono di esportare i dati dal foglio Excel in formato XML e importarli in SQL Server 2017.

## 🔧 File inclusi
- **Script_Esportazione_Excel.vba** - Script VBA per Excel
- **Script_Importazione_TSQL.sql** - Script T-SQL per SQL Server 2017
- **ISTRUZIONI_UTILIZZO.md** - Questo file

## 📊 PARTE 1: Esportazione da Excel

### Prerequisiti
- Microsoft Excel con supporto per macro VBA
- I dati devono essere nel foglio attivo di Excel
- Prima riga deve contenere le intestazioni delle colonne

### Installazione dello Script VBA

1. **Aprire Excel** con il file contenente i dati
2. **Premere Alt+F11** per aprire l'editor VBA
3. **Inserire un nuovo modulo**:
   - Clic destro nel Project Explorer
   - Selezionare "Insert" → "Module"
4. **Copiare e incollare** tutto il codice da `Script_Esportazione_Excel.vba`
5. **Salvare** il file Excel come "Excel Macro-Enabled Workbook (.xlsm)"

### Esecuzione dell'Esportazione

1. **Aprire il foglio** con i dati da esportare
2. **Premere Alt+F8** per aprire la finestra delle macro
3. **Selezionare `EsportaXML`** o `EsportaRapido`
4. **Cliccare "Esegui"**

### Risultato
- Viene creata automaticamente la cartella `C:\Antonio\PrezziDistribuzione\`
- Il file XML viene salvato come `PrezziManuali.xml`
- Appare un messaggio di conferma

## 🗃️ PARTE 2: Importazione in SQL Server

### Prerequisiti
- SQL Server 2017 o versioni successive
- Permessi per creare tabelle e stored procedure
- Accesso al file XML generato

### Installazione dello Script T-SQL

1. **Aprire SQL Server Management Studio (SSMS)**
2. **Connettersi** al database dove importare i dati
3. **Aprire una nuova query**
4. **Copiare e incollare** tutto il codice da `Script_Importazione_TSQL.sql`
5. **Eseguire lo script** (F5 o Ctrl+E)

### Esecuzione dell'Importazione

Dopo aver eseguito lo script di setup, per importare i dati:

```sql
-- Importazione con percorso predefinito
EXEC [dbo].[SP_ImportaPrezziManualiXML]

-- Oppure specificare un percorso diverso
EXEC [dbo].[SP_ImportaPrezziManualiXML] 'C:\MioPercorso\PrezziManuali.xml'
```

### Verifica dei Dati

```sql
-- Contare i record importati
SELECT COUNT(*) as TotaleRecord FROM [dbo].[PrezziManuali]

-- Visualizzare i primi 10 record
SELECT TOP 10 * FROM [dbo].[PrezziManuali] ORDER BY IdDiArtico

-- Verificare per marca
SELECT MARCA, COUNT(*) as Quantita 
FROM [dbo].[PrezziManuali] 
GROUP BY MARCA 
ORDER BY Quantita DESC
```

## 🔄 Processo Completo

### Flusso di Lavoro Tipico
1. **Preparare i dati in Excel** (intestazioni nella prima riga)
2. **Eseguire la macro VBA** per creare l'XML
3. **Verificare** che il file XML sia stato creato
4. **Eseguire la stored procedure** per importare i dati
5. **Verificare** l'importazione con le query di controllo

### Automazione (Opzionale)
È possibile automatizzare il processo creando:
- Un'attività pianificata per l'esportazione Excel
- Un job di SQL Server Agent per l'importazione

## 📝 Struttura della Tabella

La tabella `PrezziManuali` include tutte le colonne del CSV originale:

- **IdDiArtico** (int) - Identificativo articolo
- **ART_CODICE** (varchar) - Codice articolo
- **classificatore3** (int) - Classificatore
- **Descrizione** (varchar) - Descrizione articolo
- **MARCA** (varchar) - Marca del pneumatico
- **ART_STAGIONE** (varchar) - Stagione (ESTIVO, INVERNALE, 4 STAGIONI)
- **RUNFLAT** (varchar) - Indica se è runflat (SI/NO)
- **PREZZO_LISTINO** (decimal) - Prezzo di listino
- **COSTO_ULTIMO** (decimal) - Ultimo costo
- **DataImportazione** (datetime) - Data/ora importazione (aggiunta automaticamente)
- ... e molte altre colonne

## ⚠️ Avvertenze e Limitazioni

### Permessi Richiesti
- **Excel**: Permessi per creare file nella cartella C:\Antonio\
- **SQL Server**: Permessi per BULK INSERT e creazione oggetti

### Gestione Errori
- Lo script VBA gestisce automaticamente i caratteri speciali XML
- Lo script T-SQL usa `TRY_CAST` per gestire conversioni di tipo
- In caso di errore, controllare i log di SQL Server

### Performance
- Per grandi volumi di dati (>100.000 record), considerare:
  - Aumentare il timeout della connessione
  - Eseguire l'importazione in orari di basso carico
  - Monitorare l'utilizzo della memoria

## 🔧 Personalizzazioni Possibili

### Modifiche al VBA
- Cambiare il percorso di destinazione modificando `filePath`
- Aggiungere filtri per esportare solo certe righe
- Personalizzare la struttura XML

### Modifiche al T-SQL
- Aggiungere colonne calcolate
- Modificare i tipi di dati
- Aggiungere vincoli di integrità
- Creare trigger per audit

## 📞 Supporto
In caso di problemi:
1. Verificare i permessi sui file e database
2. Controllare che i percorsi siano corretti
3. Verificare la sintassi XML generata
4. Consultare i log di errore di SQL Server

---
*Script creati per l'esportazione e importazione dei dati PrezziManuali* 