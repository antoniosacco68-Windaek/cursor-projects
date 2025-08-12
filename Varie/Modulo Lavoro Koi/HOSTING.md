# Istruzioni per hosting

# Come Aprire il Foglio Presenze sul Telefono

## Opzione 1: Netlify (Gratis e Veloce)

1. Vai su https://netlify.com
2. Clicca "Sign up" e registrati con email/Google
3. Clicca "Add new site" → "Deploy manually"
4. Trascina il file `index.html` nella finestra
5. Netlify ti darà un URL tipo: `https://nomecasuale.netlify.app`
6. Apri questo URL sul telefono con Safari/Chrome!

## Opzione 2: GitHub Pages

1. Vai su https://github.com
2. Crea un nuovo repository pubblico
3. Carica il file `index.html`
4. Vai su Settings → Pages
5. Seleziona "Deploy from a branch" → "main"
6. L'URL sarà: `https://tuonome.github.io/nomerepository`

## Opzione 3: Server Locale (Per casa/ufficio)

Se sei sulla stessa rete WiFi del computer:

1. Apri terminale e vai nella cartella del progetto
2. Esegui: `python3 -m http.server 8000`
3. Trova l'IP del Mac: Sistema → Rete
4. Sul telefono vai su: `http://IP-DEL-MAC:8000`

## Opzione 4: File Sharing

1. Carica `index.html` su Google Drive/iCloud
2. Condividi il link
3. Aprilo dal telefono e seleziona "Apri con Safari"

---

**CONSIGLIO**: Usa Netlify (Opzione 1) - è la più semplice!
