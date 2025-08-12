#!/bin/bash

# Script di sincronizzazione automatica per i progetti Cursor
# Questo script monitora i cambiamenti e fa automaticamente commit e push

# Colori per i messaggi
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
LOG_FILE="$REPO_DIR/sync.log"

# Funzione per log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Funzione per sincronizzazione
sync_changes() {
    cd "$REPO_DIR" || exit 1
    
    # Controlla se ci sono modifiche
    if [[ -n $(git status --porcelain) ]]; then
        log_message "${BLUE}🔄 Rilevate modifiche, sincronizzazione in corso...${NC}"
        
        # Aggiungi tutti i file
        git add . 2>/dev/null
        
        # Crea messaggio di commit automatico
        COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S') - Modifiche automatiche"
        
        # Fai il commit
        if git commit -m "$COMMIT_MSG" 2>/dev/null; then
            log_message "${GREEN}✅ Commit creato: $COMMIT_MSG${NC}"
            
            # Push su GitHub
            if git push origin main 2>/dev/null; then
                log_message "${GREEN}✅ Sincronizzazione completata con successo!${NC}"
                echo "${GREEN}🎉 Tutti i cambiamenti sono stati sincronizzati su GitHub!${NC}"
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
}

# Funzione per monitoraggio continuo
monitor_changes() {
    log_message "${BLUE}🚀 Avvio monitoraggio automatico dei cambiamenti...${NC}"
    echo "${GREEN}📁 Monitoraggio attivo per: $REPO_DIR${NC}"
    echo "${YELLOW}💡 Lo script farà automaticamente commit e push di tutte le modifiche${NC}"
    echo "${YELLOW}⏹️  Premi Ctrl+C per fermare il monitoraggio${NC}"
    echo ""
    
    # Loop infinito per monitorare i cambiamenti
    while true; do
        sync_changes
        sleep 30  # Controlla ogni 30 secondi
    done
}

# Funzione per sincronizzazione una tantum
one_time_sync() {
    log_message "${BLUE}🔄 Sincronizzazione una tantum...${NC}"
    sync_changes
    log_message "${GREEN}✅ Sincronizzazione completata${NC}"
}

# Menu principale
show_menu() {
    echo "${BLUE}=== SCRIPT DI SINCRONIZZAZIONE AUTOMATICA ===${NC}"
    echo ""
    echo "1. ${GREEN}Sincronizzazione una tantum${NC}"
    echo "2. ${YELLOW}Monitoraggio continuo (automatico)${NC}"
    echo "3. ${BLUE}Visualizza log${NC}"
    echo "4. ${RED}Esci${NC}"
    echo ""
    read -p "Scegli un'opzione (1-4): " choice
    
    case $choice in
        1)
            one_time_sync
            ;;
        2)
            monitor_changes
            ;;
        3)
            if [[ -f "$LOG_FILE" ]]; then
                echo "${BLUE}=== LOG DELLE SINCRONIZZAZIONI ===${NC}"
                tail -20 "$LOG_FILE"
            else
                echo "${YELLOW}Nessun log trovato${NC}"
            fi
            ;;
        4)
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
