#!/bin/bash

# Script per controllare lo stato della sincronizzazione automatica Cursor

# Colori per i messaggi
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
PID_FILE="$REPO_DIR/auto-sync.pid"

echo "${BLUE}📊 Stato sincronizzazione automatica Cursor${NC}"
echo ""

# Controlla se la sincronizzazione è attiva
if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "${GREEN}✅ Sincronizzazione automatica: ATTIVA${NC}"
        echo "${BLUE}📋 PID del processo: $PID${NC}"
        
        # Mostra informazioni sul processo
        PROCESS_INFO=$(ps -p "$PID" -o pid,ppid,etime,pcpu,pmem,command --no-headers 2>/dev/null)
        if [[ -n "$PROCESS_INFO" ]]; then
            echo "${BLUE}📈 Informazioni processo:${NC}"
            echo "$PROCESS_INFO"
        fi
        
        # Controlla lo stato del repository
        cd "$REPO_DIR" 2>/dev/null
        if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            echo "${YELLOW}⚠️  Modifiche in attesa di sincronizzazione${NC}"
        else
            echo "${GREEN}✅ Repository sincronizzato${NC}"
        fi
        
    else
        echo "${RED}❌ Sincronizzazione automatica: INATTIVA${NC}"
        echo "${YELLOW}⚠️  File PID trovato ma processo non attivo${NC}"
        rm -f "$PID_FILE"
    fi
else
    echo "${RED}❌ Sincronizzazione automatica: INATTIVA${NC}"
    echo "${YELLOW}💡 Per avviare: ./start-auto-sync.sh${NC}"
fi

echo ""
echo "${BLUE}📁 Directory monitorata: $REPO_DIR${NC}"
echo "${BLUE}🔄 Controllo ogni: 30 secondi${NC}"
echo ""
echo "${YELLOW}Comandi utili:${NC}"
echo "  ${GREEN}./start-auto-sync.sh${NC}  - Avvia sincronizzazione"
echo "  ${RED}./stop-auto-sync.sh${NC}   - Ferma sincronizzazione"
echo "  ${BLUE}./status-auto-sync.sh${NC} - Questo script"
