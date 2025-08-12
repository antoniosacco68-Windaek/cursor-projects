// File: pneumatici-filtro.js
// Questo script gestisce il filtro a cascata per i pneumatici

document.addEventListener('DOMContentLoaded', function() {
    // La variabile tireDataString viene fornita dal file tire-data.js incluso prima di questo

    // Converte i dati degli pneumatici in un oggetto strutturato
    function inizializzaDati() {
        const tireData = tireDataString.trim().split('\n').map(line => line.trim()).filter(line => line.length > 0);
        const tiresObj = {};
        
        tireData.forEach(tireStr => {
            const [larghezza, sezione, diametro, carico, velocita] = tireStr.split('-');
            
            // Struttura gerarchica per i pneumatici
            if (!tiresObj[larghezza]) tiresObj[larghezza] = {};
            if (!tiresObj[larghezza][sezione]) tiresObj[larghezza][sezione] = {};
            if (!tiresObj[larghezza][sezione][diametro]) tiresObj[larghezza][sezione][diametro] = {};
            if (!tiresObj[larghezza][sezione][diametro][carico]) tiresObj[larghezza][sezione][diametro][carico] = [];
            
            // Aggiungi la velocità solo se non è già presente
            if (!tiresObj[larghezza][sezione][diametro][carico].includes(velocita)) {
                tiresObj[larghezza][sezione][diametro][carico].push(velocita);
            }
        });
        
        return tiresObj;
    }
    
    // Inizializza la struttura dati
    const tiresObj = inizializzaDati();
    
    // Funzione per trovare selettori sia per ID che per nome di campo
    function getSelector(idOrName) {
        // Prima cerca per ID
        let element = document.getElementById(idOrName);
        if (element) return element;
        
        // Se non trovato per ID, cerca per nome nella wpcf7-form-control-wrap
        const wraps = document.querySelectorAll(`.wpcf7-form-control-wrap[data-name="${idOrName}"]`);
        if (wraps.length > 0) {
            const selects = wraps[0].querySelectorAll('select');
            if (selects.length > 0) {
                return selects[0];
            }
        }
        
        return null;
    }
    
    // Funzione per aggiornare le select in base alle selezioni precedenti
    function updateSelectors() {
        const larghezzaSelect = getSelector('larghezza-pneumatico') || getSelector('larghezza');
        const sezioneSelect = getSelector('sezione-pneumatico') || getSelector('sezione');
        const diametroSelect = getSelector('diametro-pneumatico') || getSelector('diametro');
        const caricoSelect = getSelector('carico-pneumatico') || getSelector('carico');
        const velocitaSelect = getSelector('velocita-pneumatico') || getSelector('velocita');
        
        if (!larghezzaSelect || !sezioneSelect || !diametroSelect || !caricoSelect || !velocitaSelect) {
            console.error('Non è stato possibile trovare tutti i selettori necessari per il filtro pneumatici');
            return;
        }
        
        // Ottieni i valori correnti
        const larghezzaValue = larghezzaSelect.value;
        const sezioneValue = sezioneSelect.value;
        const diametroValue = diametroSelect.value;
        const caricoValue = caricoSelect.value;
        
        // Aggiorna sezione in base alla larghezza selezionata
        if (larghezzaValue && larghezzaValue !== '- - Larghezza - -') {
            const availableSezioni = Object.keys(tiresObj[larghezzaValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentSezione = sezioneSelect.value;
            
            // Reimposta la lista
            sezioneSelect.innerHTML = '<option value="- - Spalla - -">- - Spalla - -</option>';
            
            // Aggiungi le opzioni disponibili
            availableSezioni.forEach(sez => {
                sezioneSelect.innerHTML += `<option value="${sez}">${sez}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableSezioni.includes(currentSezione)) {
                sezioneSelect.value = currentSezione;
            }
        }
        
        // Aggiorna diametro in base a larghezza e sezione
        if (larghezzaValue && sezioneValue && sezioneValue !== '- - Spalla - -') {
            const availableDiametri = Object.keys(tiresObj[larghezzaValue][sezioneValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentDiametro = diametroSelect.value;
            
            // Reimposta la lista
            diametroSelect.innerHTML = '<option value="- - Diametro - -">- - Diametro - -</option>';
            
            // Aggiungi le opzioni disponibili
            availableDiametri.forEach(diam => {
                diametroSelect.innerHTML += `<option value="${diam}">${diam}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableDiametri.includes(currentDiametro)) {
                diametroSelect.value = currentDiametro;
            }
        }
        
        // Aggiorna carico in base a larghezza, sezione e diametro
        if (larghezzaValue && sezioneValue && diametroValue && diametroValue !== '- - Diametro - -') {
            const availableCarichi = Object.keys(tiresObj[larghezzaValue][sezioneValue][diametroValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentCarico = caricoSelect.value;
            
            // Reimposta la lista
            caricoSelect.innerHTML = '<option value="- - Carico - -">- - Carico - -</option>';
            
            // Aggiungi le opzioni disponibili
            availableCarichi.forEach(car => {
                caricoSelect.innerHTML += `<option value="${car}">${car}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableCarichi.includes(currentCarico)) {
                caricoSelect.value = currentCarico;
            }
        }
        
        // Aggiorna velocità in base a larghezza, sezione, diametro e carico
        if (larghezzaValue && sezioneValue && diametroValue && caricoValue && caricoValue !== '- - Carico - -') {
            const availableVelocita = (tiresObj[larghezzaValue][sezioneValue][diametroValue][caricoValue] || []).sort();
            
            // Salva il valore corrente se possibile
            const currentVelocita = velocitaSelect.value;
            
            // Reimposta la lista
            velocitaSelect.innerHTML = '<option value="- - Velocità - -">- - Velocità - -</option>';
            
            // Aggiungi le opzioni disponibili
            availableVelocita.forEach(vel => {
                velocitaSelect.innerHTML += `<option value="${vel}">${vel}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableVelocita.includes(currentVelocita)) {
                velocitaSelect.value = currentVelocita;
            }
        }
        
        // Aggiorna i colori dei placeholder
        fixPlaceholderColors();
    }
    
    // Aggiungi listener di eventi a tutte le select
    function addSelectorListeners() {
        // Trova tutti i selettori delle gomme
        const selectors = [
            getSelector('larghezza-pneumatico') || getSelector('larghezza'),
            getSelector('sezione-pneumatico') || getSelector('sezione'),
            getSelector('diametro-pneumatico') || getSelector('diametro'),
            getSelector('carico-pneumatico') || getSelector('carico'),
            getSelector('velocita-pneumatico') || getSelector('velocita')
        ].filter(selector => selector !== null);
        
        selectors.forEach(selector => {
            selector.addEventListener('change', updateSelectors);
        });
    }
    
    // Funzione per correggere i colori dei placeholder nelle select
    function fixPlaceholderColors() {
        // Trova tutti i selettori delle gomme
        const selectors = [
            getSelector('larghezza-pneumatico') || getSelector('larghezza'),
            getSelector('sezione-pneumatico') || getSelector('sezione'),
            getSelector('diametro-pneumatico') || getSelector('diametro'),
            getSelector('carico-pneumatico') || getSelector('carico'),
            getSelector('velocita-pneumatico') || getSelector('velocita')
        ].filter(selector => selector !== null);
        
        selectors.forEach(select => {
            if (select.selectedIndex === 0) {
                select.style.color = '#999999'; // grigio per i placeholder
            } else {
                select.style.color = '#000000'; // nero per i valori selezionati
            }
        });
    }
    
    // Funzione per verificare se CF7 ha caricato correttamente
    function initializeWhenReady() {
        // Verifica se CF7 è stato caricato completamente
        const cf7Form = document.querySelector('.wpcf7-form');
        if (!cf7Form) {
            // Se non trova il form, riprova tra 100ms
            setTimeout(initializeWhenReady, 100);
            return;
        }
        
        // Inizializza i listener
        addSelectorListeners();
        
        // Imposta i colori iniziali
        fixPlaceholderColors();
        
        // Gestisci anche il cambio di colore durante la selezione
        const selectors = [
            getSelector('larghezza-pneumatico') || getSelector('larghezza'),
            getSelector('sezione-pneumatico') || getSelector('sezione'),
            getSelector('diametro-pneumatico') || getSelector('diametro'),
            getSelector('carico-pneumatico') || getSelector('carico'),
            getSelector('velocita-pneumatico') || getSelector('velocita')
        ].filter(selector => selector !== null);
        
        selectors.forEach(select => {
            select.addEventListener('change', function() {
                if (this.selectedIndex === 0) {
                    this.style.color = '#999999'; // grigio per i placeholder
                } else {
                    this.style.color = '#000000'; // nero per i valori selezionati
                }
            });
        });
    }
    
    // Inizializza quando il DOM è pronto
    initializeWhenReady();
    
    // In alcune configurazioni, CF7 potrebbe modificare il DOM dopo l'evento DOMContentLoaded
    // Quindi impostiamo un altro timer per essere sicuri
    setTimeout(initializeWhenReady, 500);
    setTimeout(initializeWhenReady, 1000);
    setTimeout(initializeWhenReady, 2000);
}); 