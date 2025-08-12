# 🔄 Sincronizzazione Automatica per Progetti Cursor

Questo repository include script per sincronizzare automaticamente tutti i tuoi progetti Cursor con GitHub.

## 📁 File Script

### 1. `auto-sync.sh` - Sincronizzazione Periodica
- **Funzione**: Controlla i cambiamenti ogni 30 secondi
- **Uso**: Perfetto per sincronizzazione automatica base
- **Vantaggi**: Non richiede software aggiuntivo

### 2. `auto-sync-realtime.sh` - Sincronizzazione in Tempo Reale
- **Funzione**: Monitora i cambiamenti in tempo reale
- **Uso**: Sincronizzazione istantanea (richiede fswatch)
- **Vantaggi**: Sincronizzazione immediata

## 🚀 Come Usare

### 🎯 **OPZIONE RACCOMANDATA: Sincronizzazione Automatica in Background**

**Per avviare la sincronizzazione automatica:**
```bash
cd /Users/antonio/Documents/Cursor
./start-auto-sync.sh
```

**Per fermare la sincronizzazione:**
```bash
./stop-auto-sync.sh
```

**Per controllare lo stato:**
```bash
./status-auto-sync.sh
```

### 📋 **OPZIONI AVANZATE:**

#### Opzione 1: Sincronizzazione Periodica (Manuale)
```bash
cd /Users/antonio/Documents/Cursor
./auto-sync.sh
```

#### Opzione 2: Sincronizzazione in Tempo Reale
```bash
cd /Users/antonio/Documents/Cursor
./auto-sync-realtime.sh
```

## 📋 Menu delle Opzioni

### Script Periodico (`auto-sync.sh`)
1. **Sincronizzazione una tantum** - Sincronizza una volta sola
2. **Monitoraggio continuo** - Controlla ogni 30 secondi
3. **Visualizza log** - Mostra la cronologia delle sincronizzazioni
4. **Esci** - Chiudi lo script

### Script Tempo Reale (`auto-sync-realtime.sh`)
1. **Sincronizzazione una tantum** - Sincronizza una volta sola
2. **Monitoraggio in tempo reale** - Sincronizzazione istantanea (richiede fswatch)
3. **Monitoraggio periodico** - Controlla ogni 10 secondi
4. **Installa fswatch** - Installa il software necessario
5. **Visualizza log** - Mostra la cronologia delle sincronizzazioni
6. **Esci** - Chiudi lo script

## ⚡ Funzionalità Automatiche

✅ **Commit automatici** - Ogni modifica viene salvata con timestamp
✅ **Push automatico** - Tutto viene sincronizzato su GitHub
✅ **Log dettagliati** - Cronologia completa delle operazioni
✅ **Gestione errori** - Gestione robusta degli errori di rete
✅ **Lock file** - Evita conflitti durante la sincronizzazione

## 📝 Esempi di Uso

### Scenario 1: Lavoro normale
1. Apri lo script: `./auto-sync.sh`
2. Scegli opzione 2 (Monitoraggio continuo)
3. Lavora sui tuoi progetti normalmente
4. Ogni modifica viene automaticamente sincronizzata!

### Scenario 2: Sincronizzazione istantanea
1. Installa fswatch: `brew install fswatch`
2. Apri lo script: `./auto-sync-realtime.sh`
3. Scegli opzione 2 (Monitoraggio in tempo reale)
4. Le modifiche vengono sincronizzate immediatamente!

## 🔧 Installazione fswatch (per tempo reale)

Se vuoi usare la sincronizzazione in tempo reale:

```bash
# Installa Homebrew (se non l'hai già)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Installa fswatch
brew install fswatch
```

## 📊 File di Log

Gli script creano file di log per monitorare le attività:

- `sync.log` - Log dello script periodico
- `sync-realtime.log` - Log dello script tempo reale

## 🛑 Come Fermare

Per fermare il monitoraggio automatico:
- Premi `Ctrl+C` nel terminale
- Oppure chiudi il terminale

## ⚠️ Note Importanti

1. **Connessione Internet**: Assicurati di avere una connessione stabile
2. **Credenziali GitHub**: Le credenziali devono essere configurate
3. **Permessi**: Gli script devono essere eseguibili (`chmod +x`)
4. **Directory**: Gli script funzionano solo nella directory `/Users/antonio/Documents/Cursor`

## 🎯 Vantaggi

- **Nessun lavoro manuale** - Tutto è automatico
- **Backup sicuro** - Tutti i progetti sono su GitHub
- **Cronologia completa** - Ogni modifica è tracciata
- **Collaborazione** - Altri possono vedere i tuoi progetti
- **Versioning** - Controllo completo delle versioni

## 🔄 Flusso di Lavoro Automatico

1. **Modifichi un file** nel tuo editor
2. **Lo script rileva** il cambiamento automaticamente
3. **Commit automatico** con timestamp
4. **Push automatico** su GitHub
5. **Log dell'operazione** salvato

**Risultato**: I tuoi progetti sono sempre sincronizzati e al sicuro! 🎉
