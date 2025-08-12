#!/bin/bash

# Script per disabilitare l'avvio automatico della sincronizzazione con Cursor

# Colori per i messaggi
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.antonio.cursor-sync.plist"

echo "${BLUE}🛑 Disabilitazione avvio automatico sincronizzazione Cursor${NC}"
echo ""

# Controlla se il LaunchAgent esiste
if [[ -f "$LAUNCH_AGENT_FILE" ]]; then
    echo "${GREEN}✅ LaunchAgent trovato: $LAUNCH_AGENT_FILE${NC}"
    
    # Scarica il LaunchAgent
    launchctl unload "$LAUNCH_AGENT_FILE" 2>/dev/null
    
    if [[ $? -eq 0 ]]; then
        echo "${GREEN}✅ LaunchAgent scaricato con successo${NC}"
    else
        echo "${YELLOW}⚠️  LaunchAgent già scaricato o errore nello scaricamento${NC}"
    fi
    
    # Rimuovi il file LaunchAgent
    rm -f "$LAUNCH_AGENT_FILE"
    echo "${GREEN}✅ File LaunchAgent rimosso${NC}"
    
else
    echo "${YELLOW}⚠️  Nessun LaunchAgent trovato${NC}"
fi

# Ferma anche la sincronizzazione se è attiva
if [[ -f "$REPO_DIR/auto-sync.pid" ]]; then
    echo "${YELLOW}🔄 Fermo sincronizzazione attiva...${NC}"
    ./stop-auto-sync.sh
fi

echo ""
echo "${GREEN}🎉 Avvio automatico disabilitato!${NC}"
echo ""
echo "${BLUE}📋 Cosa succede ora:${NC}"
echo "  ❌ Apertura Cursor → NON avvia più la sincronizzazione automaticamente"
echo "  💡 Per sincronizzare → Devi lanciare manualmente ./start-auto-sync.sh"
echo ""
echo "${YELLOW}💡 Per riabilitare l'avvio automatico:${NC}"
echo "  ${GREEN}./setup-cursor-auto-sync.sh${NC}"
