#!/bin/bash

# Script per fermare la sincronizzazione automatica Cursor

# Colori per i messaggi
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
PID_FILE="$REPO_DIR/auto-sync.pid"

echo "${BLUE}🛑 Fermo sincronizzazione automatica...${NC}"

# Controlla se la sincronizzazione è attiva
if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    
    if ps -p "$PID" > /dev/null 2>&1; then
        # Ferma il processo
        kill "$PID" 2>/dev/null
        
        # Aspetta che il processo si fermi
        sleep 2
        
        # Controlla se è ancora attivo
        if ps -p "$PID" > /dev/null 2>&1; then
            # Forza la terminazione
            kill -9 "$PID" 2>/dev/null
            echo "${YELLOW}⚠️  Processo terminato forzatamente${NC}"
        else
            echo "${GREEN}✅ Sincronizzazione automatica fermata con successo${NC}"
        fi
        
        # Rimuovi il file PID
        rm -f "$PID_FILE"
    else
        echo "${YELLOW}⚠️  Nessun processo di sincronizzazione attivo${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo "${YELLOW}⚠️  Nessun file PID trovato${NC}"
fi

echo "${GREEN}🎯 Sincronizzazione automatica disattivata${NC}"
