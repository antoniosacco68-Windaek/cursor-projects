# 📋 Modulo Presenze Digitale LavoroPiù - Novembre 2024

Un'applicazione web che replica fedelmente il foglio presenze ufficiale di LavoroPiù, ottimizzata per la compilazione su dispositivi mobili.

## ✨ Caratteristiche

- **📱 Fedele all'originale**: Layout identico al foglio presenze cartaceo LavoroPiù
- **💾 Salvataggio automatico**: I dati vengono salvati automaticamente mentre digiti
- **📊 Calcoli automatici**: Totali ore ordinarie e complessivi calcolati in tempo reale
- **🖨️ Stampa perfetta**: Risultato identico al modulo cartaceo per la consegna
- **📂 Backup e ripristino**: Salva e carica i tuoi dati in formato JSON
- **⚡ Funzioni smart**: Auto-completamento turni e suggerimenti rapidi

## 🎯 Formato del Modulo

Il modulo replica esattamente la struttura LavoroPiù con:
- Header aziendale con logo e riferimenti
- Campi per dipendente e azienda utilizzatrice
- Tabella con 30 giorni di novembre 2024
- Colonne per: Data, Ordinarie, Turni (x2), Straordinari (x2), Note
- Sezione firme e timbri
- Footer con contatti agenzia

## 🚀 Come usare

### 📱 Apertura sul telefono
1. Apri il file `index.html` nel browser del tuo smartphone
2. Aggiungi ai preferiti per accesso rapido
3. Compila direttamente durante le pause lavorative

### ✍️ Compilazione
1. **Dati intestazione**: Inserisci nome dipendente e azienda utilizzatrice
2. **Per ogni giorno**:
   - **Ordinarie**: Usa il selettore orario (es: 08:00)
   - **Turni**: Formato "08:00-17:00" (calcola automaticamente le ore)
   - **Straordinari**: Formato "02:30" per ore e minuti
   - **Note**: Malattia, ferie, permessi, ecc.

### 🎯 Suggerimenti Smart

**Turni rapidi**: Tieni premuto sui campi turno per suggerimenti:
- Mattina: 08:00-17:00
- Pomeriggio: 14:00-22:00  
- Notte: 22:00-06:00

**Auto-formattazione**: Digita "0800" e diventa automaticamente "08:00"

## 📊 Calcoli Automatici

- **Ore Ordinarie**: Somma delle ore inserite nel campo "Ordinarie"
- **Turni**: Calcola automaticamente dalla differenza orario (sottrae 1h pausa se >6h)
- **Totale Complessivo**: Somma di ordinarie, turni e straordinari
- **Aggiornamento Live**: I totali si aggiornano mentre digiti

## 💾 Funzioni Disponibili

### 💾 Salva
- Salvataggio automatico nel browser
- Download file di backup JSON con nome personalizzato

### 🖨️ Stampa
- Layout ottimizzato per stampa A4
- Nasconde automaticamente i pulsanti di controllo
- Risultato identico al modulo cartaceo

### 📂 Carica
- Ripristina dati da file JSON precedentemente salvato
- Mantiene tutta la formattazione e i calcoli

### 🔄 Reset
- Cancella tutti i dati e ricomincia da capo
- Richiede conferma per evitare perdite accidentali

## 📱 Installazione come App

Per un accesso ancora più rapido:
1. Apri `index.html` nel browser mobile
2. Menu browser → "Aggiungi alla schermata home"
3. Avrai l'icona dell'app sul desktop!

## 🔧 Funzionalità Speciali

### Gestione Weekend
- I weekend (sabato/domenica) sono evidenziati in rosso
- Stessa funzionalità degli altri giorni

### Formato Turni Intelligente
- Riconosce format "HH:MM-HH:MM" 
- Calcola automaticamente pausa pranzo
- Gestisce turni notturni che attraversano la mezzanotte

### Backup Automatico
- Ogni modifica viene salvata automaticamente
- Ricaricando la pagina ritrovi tutto come l'hai lasciato
- Nome file include dipendente e mese per organizzazione

## 📄 Conformità Aziendale

Il modulo è **100% conforme** al format LavoroPiù originale:
- ✅ Layout identico
- ✅ Stessi campi e colonne  
- ✅ Header e footer aziendali
- ✅ Spazi per firme e timbri
- ✅ Riferimenti normativi
- ✅ Contatti agenzia

## 💡 Suggerimenti per l'Uso

### Routine Quotidiana
1. Apri l'app al mattino
2. Inserisci l'orario di entrata
3. A fine giornata completa con uscita
4. Aggiungi note se necessario

### Fine Mese
1. Controlla i totali
2. Stampa il modulo
3. Firma e consegna all'azienda
4. Salva backup per archivio personale

## 🆘 Risoluzione Problemi

**Calcoli sbagliati nei turni**: Verifica il formato "08:00-17:00"

**Dati persi**: Controlla di non aver cancellato i dati del browser

**Stampa non corretta**: Usa browser aggiornato, preferibilmente Chrome

**Non funziona su telefono**: Verifica connessione e aggiorna browser

## 📞 Supporto

Per problemi specifici o personalizzazioni:
- Controlla che tutti i campi siano nel formato corretto
- I turni devono essere in formato "HH:MM-HH:MM"
- Gli straordinari in formato "HH:MM"

---

💼 **Pronto per semplificare la gestione delle tue presenze LavoroPiù!**

*Modulo conforme alle specifiche aziendali - Versione digitale ufficiale non ufficiale* 😉 