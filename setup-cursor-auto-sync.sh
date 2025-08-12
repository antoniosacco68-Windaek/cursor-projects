#!/bin/bash

# Script per configurare l'avvio automatico della sincronizzazione con Cursor

# Colori per i messaggi
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory del repository
REPO_DIR="/Users/antonio/Documents/Cursor"
CURSOR_APP="/Applications/Cursor.app"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_FILE="$LAUNCH_AGENT_DIR/com.antonio.cursor-sync.plist"

echo "${BLUE}🚀 Configurazione avvio automatico sincronizzazione Cursor${NC}"
echo ""

# Controlla se Cursor è installato
if [[ ! -d "$CURSOR_APP" ]]; then
    echo "${RED}❌ Cursor non trovato in /Applications/Cursor.app${NC}"
    echo "${YELLOW}💡 Assicurati che Cursor sia installato${NC}"
    exit 1
fi

echo "${GREEN}✅ Cursor trovato: $CURSOR_APP${NC}"

# Crea la directory LaunchAgents se non esiste
if [[ ! -d "$LAUNCH_AGENT_DIR" ]]; then
    mkdir -p "$LAUNCH_AGENT_DIR"
    echo "${GREEN}✅ Creata directory: $LAUNCH_AGENT_DIR${NC}"
fi

# Crea il file LaunchAgent
cat > "$LAUNCH_AGENT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.antonio.cursor-sync</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$REPO_DIR/start-auto-sync.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <dict>
        <key>PathState</key>
        <dict>
            <key>$CURSOR_APP</key>
            <true/>
        </dict>
    </dict>
    <key>StandardOutPath</key>
    <string>$REPO_DIR/cursor-sync.log</string>
    <key>StandardErrorPath</key>
    <string>$REPO_DIR/cursor-sync-error.log</string>
</dict>
</plist>
EOF

echo "${GREEN}✅ Creato file LaunchAgent: $LAUNCH_AGENT_FILE${NC}"

# Carica il LaunchAgent
launchctl load "$LAUNCH_AGENT_FILE" 2>/dev/null

if [[ $? -eq 0 ]]; then
    echo "${GREEN}✅ LaunchAgent caricato con successo${NC}"
else
    echo "${YELLOW}⚠️  LaunchAgent già caricato o errore nel caricamento${NC}"
fi

echo ""
echo "${GREEN}🎉 Configurazione completata!${NC}"
echo ""
echo "${BLUE}📋 Cosa succede ora:${NC}"
echo "  ✅ Quando apri Cursor → Sincronizzazione si avvia automaticamente"
echo "  ✅ Quando chiudi Cursor → Sincronizzazione si ferma automaticamente"
echo "  ✅ Ogni modifica → Viene sincronizzata automaticamente ogni 30 secondi"
echo ""
echo "${YELLOW}📁 File di log:${NC}"
echo "  📄 $REPO_DIR/cursor-sync.log"
echo "  📄 $REPO_DIR/cursor-sync-error.log"
echo ""
echo "${BLUE}🔧 Comandi utili:${NC}"
echo "  ${GREEN}./status-auto-sync.sh${NC} - Controlla stato sincronizzazione"
echo "  ${RED}./disable-cursor-auto-sync.sh${NC} - Disabilita avvio automatico"
echo ""
echo "${GREEN}🎯 Ora apri Cursor e la sincronizzazione partirà automaticamente!${NC}"
