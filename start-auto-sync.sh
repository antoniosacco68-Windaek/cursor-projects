#!/bin/bash

# Script di avvio automatico per la sincronizzazione Cursor
# Questo script avvia la sincronizzazione automatica in background

# Colori per i messaggi
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
PID_FILE="$REPO_DIR/auto-sync.pid"

echo "${BLUE}🚀 Avvio sincronizzazione automatica per Cursor...${NC}"

# Controlla se la sincronizzazione è già attiva
if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "${YELLOW}⚠️  Sincronizzazione già attiva (PID: $PID)${NC}"
        echo "${GREEN}✅ Tutto pronto per lavorare con Cursor!${NC}"
        exit 0
    else
        # Rimuovi PID file obsoleto
        rm -f "$PID_FILE"
    fi
fi

# Avvia la sincronizzazione in background
cd "$REPO_DIR" || exit 1

# Funzione per sincronizzazione in background
background_sync() {
    while true; do
        # Controlla se ci sono modifiche
        if [[ -n $(git status --porcelain) ]]; then
            echo "${BLUE}🔄 Sincronizzazione automatica in corso...${NC}"
            
            # Aggiungi tutti i file
            git add . > /dev/null 2>&1
            
            # Crea messaggio di commit automatico
            COMMIT_MSG="Auto-sync: $(date '+%Y-%m-%d %H:%M:%S') - Modifiche automatiche"
            
            # Fai il commit
            if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
                echo "${GREEN}✅ Commit automatico: $COMMIT_MSG${NC}"
                
                # Push su GitHub
                if git push origin main > /dev/null 2>&1; then
                    echo "${GREEN}🎉 Sincronizzazione automatica completata!${NC}"
                else
                    echo "${YELLOW}⚠️  Errore push, riproverò al prossimo ciclo${NC}"
                fi
            fi
        fi
        
        # Aspetta 30 secondi
        sleep 30
    done
}

# Avvia la sincronizzazione in background
background_sync &
SYNC_PID=$!

# Salva il PID
echo "$SYNC_PID" > "$PID_FILE"

echo "${GREEN}✅ Sincronizzazione automatica avviata (PID: $SYNC_PID)${NC}"
echo "${GREEN}🎯 Ora puoi lavorare con Cursor normalmente!${NC}"
echo "${YELLOW}💡 Ogni modifica verrà sincronizzata automaticamente ogni 30 secondi${NC}"
echo "${BLUE}📁 Monitoraggio attivo per: $REPO_DIR${NC}"
echo ""
echo "${YELLOW}Per fermare la sincronizzazione: ./stop-auto-sync.sh${NC}"
