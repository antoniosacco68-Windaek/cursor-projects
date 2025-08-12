#!/bin/bash

# Script di sincronizzazione automatica in tempo reale per i progetti Cursor
# Questo script monitora i cambiamenti dei file e fa automaticamente commit e push

# Colori per i messaggi
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
LOG_FILE="$REPO_DIR/sync-realtime.log"
LOCK_FILE="$REPO_DIR/sync.lock"

# Funzione per log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Funzione per sincronizzazione con lock per evitare conflitti
sync_changes() {
    # Controlla se c'è già una sincronizzazione in corso
    if [[ -f "$LOCK_FILE" ]]; then
        log_message "${YELLOW}⚠️  Sincronizzazione già in corso, salto questo ciclo${NC}"
        return
    fi
    
    # Crea lock file
    touch "$LOCK_FILE"
    
    cd "$REPO_DIR" || exit 1
    
    # Controlla se ci sono modifiche
    if [[ -n $(git status --porcelain) ]]; then
        log_message "${BLUE}🔄 Rilevate modifiche, sincronizzazione in corso...${NC}"
        
        # Aggiungi tutti i file
        git add . 2>/dev/null
        
        # Crea messaggio di commit automatico
        COMMIT_MSG="Auto-sync realtime: $(date '+%Y-%m-%d %H:%M:%S') - Modifiche automatiche"
        
        # Fai il commit
        if git commit -m "$COMMIT_MSG" 2>/dev/null; then
            log_message "${GREEN}✅ Commit creato: $COMMIT_MSG${NC}"
            
            # Push su GitHub
            if git push origin main 2>/dev/null; then
                log_message "${GREEN}✅ Sincronizzazione completata con successo!${NC}"
                echo "${GREEN}🎉 Sincronizzazione automatica completata!${NC}"
            else
                log_message "${RED}❌ Errore durante il push su GitHub${NC}"
                echo "${RED}❌ Errore durante la sincronizzazione con GitHub${NC}"
            fi
        else
            log_message "${YELLOW}⚠️  Nessun commit necessario (nessuna modifica significativa)${NC}"
        fi
    else
        log_message "${GREEN}✅ Nessuna modifica rilevata${NC}"
    fi
    
    # Rimuovi lock file
    rm -f "$LOCK_FILE"
}

# Funzione per monitoraggio con fswatch (se disponibile)
monitor_realtime() {
    # Controlla se fswatch è installato
    if ! command -v fswatch &> /dev/null; then
        echo "${RED}❌ fswatch non è installato. Installalo con: brew install fswatch${NC}"
        echo "${YELLOW}💡 Alternativa: usa lo script auto-sync.sh per monitoraggio periodico${NC}"
        return 1
    fi
    
    log_message "${BLUE}🚀 Avvio monitoraggio in tempo reale...${NC}"
    echo "${GREEN}📁 Monitoraggio attivo per: $REPO_DIR${NC}"
    echo "${PURPLE}⚡ Sincronizzazione in tempo reale attivata${NC}"
    echo "${YELLOW}⏹️  Premi Ctrl+C per fermare il monitoraggio${NC}"
    echo ""
    
    # Monitora i cambiamenti in tempo reale
    fswatch -o "$REPO_DIR" | while read f; do
        sync_changes
    done
}

# Funzione per monitoraggio periodico (fallback)
monitor_periodic() {
    log_message "${BLUE}🚀 Avvio monitoraggio periodico...${NC}"
    echo "${GREEN}📁 Monitoraggio attivo per: $REPO_DIR${NC}"
    echo "${YELLOW}⏰ Controllo ogni 10 secondi${NC}"
    echo "${YELLOW}⏹️  Premi Ctrl+C per fermare il monitoraggio${NC}"
    echo ""
    
    while true; do
        sync_changes
        sleep 10
    done
}

# Funzione per sincronizzazione una tantum
one_time_sync() {
    log_message "${BLUE}🔄 Sincronizzazione una tantum...${NC}"
    sync_changes
    log_message "${GREEN}✅ Sincronizzazione completata${NC}"
}

# Funzione per installare fswatch
install_fswatch() {
    echo "${BLUE}📦 Installazione di fswatch...${NC}"
    if command -v brew &> /dev/null; then
        brew install fswatch
        echo "${GREEN}✅ fswatch installato con successo!${NC}"
    else
        echo "${RED}❌ Homebrew non trovato. Installa Homebrew prima:${NC}"
        echo "${YELLOW}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    fi
}

# Menu principale
show_menu() {
    echo "${BLUE}=== SCRIPT DI SINCRONIZZAZIONE AUTOMATICA TEMPO REALE ===${NC}"
    echo ""
    echo "1. ${GREEN}Sincronizzazione una tantum${NC}"
    echo "2. ${PURPLE}Monitoraggio in tempo reale (con fswatch)${NC}"
    echo "3. ${YELLOW}Monitoraggio periodico (ogni 10 secondi)${NC}"
    echo "4. ${BLUE}Installa fswatch${NC}"
    echo "5. ${BLUE}Visualizza log${NC}"
    echo "6. ${RED}Esci${NC}"
    echo ""
    read -p "Scegli un'opzione (1-6): " choice
    
    case $choice in
        1)
            one_time_sync
            ;;
        2)
            monitor_realtime
            ;;
        3)
            monitor_periodic
            ;;
        4)
            install_fswatch
            ;;
        5)
            if [[ -f "$LOG_FILE" ]]; then
                echo "${BLUE}=== LOG DELLE SINCRONIZZAZIONI ===${NC}"
                tail -20 "$LOG_FILE"
            else
                echo "${YELLOW}Nessun log trovato${NC}"
            fi
            ;;
        6)
            echo "${GREEN}Arrivederci!${NC}"
            exit 0
            ;;
        *)
            echo "${RED}Opzione non valida${NC}"
            show_menu
            ;;
    esac
}

# Controlla se siamo nella directory corretta
if [[ ! -d "$REPO_DIR/.git" ]]; then
    echo "${RED}❌ Errore: Directory $REPO_DIR non è un repository Git${NC}"
    exit 1
fi

# Avvia il menu
show_menu
