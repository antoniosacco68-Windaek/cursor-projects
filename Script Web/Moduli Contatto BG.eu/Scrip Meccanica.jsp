<script>
// Script ottimizzato per il modulo meccanica - versione produzione
(function() {
    // Funzione principale che verrà eseguita dopo il caricamento della pagina
    function initScript() {
        // Nascondi il campo servizi_selezionati e la sua etichetta
        setTimeout(function() {
            // Trova il campo servizi_selezionati
            const serviziInput = findServiziInput();
            if (serviziInput) {
                // Nascondi l'input
                serviziInput.style.display = 'none';
                
                // Cerca anche il suo label/container e nascondilo
                if (serviziInput.parentNode) {
                    // Se il parent è un div (probabilmente contiene anche il label)
                    if (serviziInput.parentNode.tagName === 'DIV') {
                        serviziInput.parentNode.style.display = 'none';
                    }
                    
                    // Cerca il label relativo a questo input
                    const labels = serviziInput.parentNode.querySelectorAll('label');
                    labels.forEach(label => {
                        if (label.htmlFor === serviziInput.id || 
                            label.textContent.toLowerCase().includes('servizi selezionati')) {
                            label.style.display = 'none';
                        }
                    });
                }
            }
        }, 500);
        
        // MODIFICATO: Cerca SOLO le checkbox relative ai servizi, escludendo privacy e newsletter
        const allCheckboxes = document.querySelectorAll('input[type="checkbox"]');
        
        // Filtra le checkbox escludendo quelle di privacy e newsletter
        const serviziCheckboxes = Array.from(allCheckboxes).filter(checkbox => {
            // Escludi esplicitamente le checkbox con id noti di privacy e newsletter
            if (checkbox.id === 'privacy-check' || checkbox.id === 'newsletter-check') {
                return false;
            }
            
            // Escludi checkbox che contengono "privacy" o "newsletter" nel loro id o name
            if ((checkbox.id && checkbox.id.toLowerCase().includes('privacy')) || 
                (checkbox.id && checkbox.id.toLowerCase().includes('newsletter')) || 
                (checkbox.name && checkbox.name.toLowerCase().includes('privacy')) || 
                (checkbox.name && checkbox.name.toLowerCase().includes('newsletter'))) {
                return false;
            }
            
            // Escludi checkbox che hanno un label associato contenente "privacy" o "newsletter"
            const label = checkbox.nextElementSibling;
            if (label && label.tagName === 'LABEL' && 
                (label.textContent.toLowerCase().includes('privacy') || 
                 label.textContent.toLowerCase().includes('newsletter'))) {
                return false;
            }
            
            // Verifica se la checkbox è all'interno di un container di servizi
            const isInServicesContainer = checkbox.closest('.servizi-container') !== null ||
                                         checkbox.closest('.servizio-item') !== null ||
                                         checkbox.closest('.preventivo_meccanica') !== null;
            
            // Considera le checkbox nella sezione servizi o quelle con la classe specifica
            return isInServicesContainer || checkbox.classList.contains('servizio-checkbox');
        });
        
        // Funzione per trovare il campo servizi_selezionati
        function findServiziInput() {
            // Metodo 1: Cerca per ID
            let input = document.getElementById('servizi-selezionati');
            
            // Metodo 2: Cerca per nome
            if (!input) {
                input = document.querySelector('input[name="servizi_selezionati"]');
            }
            
            // Metodo 3: Cerca qualsiasi input dopo il label "Servizi selezionati"
            if (!input) {
                const labels = Array.from(document.querySelectorAll('label'));
                const serviziLabel = labels.find(label => 
                    label.textContent.toLowerCase().includes('servizi selezionati'));
                
                if (serviziLabel) {
                    // Cerca l'input associato al label
                    if (serviziLabel.htmlFor) {
                        input = document.getElementById(serviziLabel.htmlFor);
                    }
                    
                    // Se non ha trovato con htmlFor, cerca il campo successivo
                    if (!input && serviziLabel.nextElementSibling) {
                        input = serviziLabel.nextElementSibling.querySelector('input');
                    }
                    
                    // Cerca qualsiasi input nella stessa div
                    if (!input && serviziLabel.parentNode) {
                        input = serviziLabel.parentNode.querySelector('input');
                    }
                }
            }
            
            // Metodo 4: Cerca tutti gli input di tipo text e prendi il primo disponibile
            if (!input) {
                const allInputs = document.querySelectorAll('input[type="text"]');
                
                // Trova il primo input che sembra essere per i servizi (ha un nome/id che contiene "servizi")
                input = Array.from(allInputs).find(inp => 
                    (inp.id && inp.id.toLowerCase().includes('servizi')) || 
                    (inp.name && inp.name.toLowerCase().includes('servizi')));
                
                if (!input && allInputs.length > 0) {
                    // Se non troviamo nulla, prova a usare il quarto input (che spesso è dove si trova il campo servizi)
                    const index = Math.min(3, allInputs.length - 1);
                    input = allInputs[index];
                }
            }
            
            return input;
        }
        
        // Trova il campo servizi_selezionati
        const serviziInput = findServiziInput();
        
        // Se non abbiamo trovato gli elementi chiave, riprova più tardi
        if (serviziCheckboxes.length === 0 || !serviziInput) {
            setTimeout(initScript, 1000);
            return;
        }
        
        // Funzione per aggiornare il campo con i servizi selezionati
        function updateServiziSelezionati() {
            // Ottieni i servizi selezionati come array
            const serviziSelezionati = Array.from(serviziCheckboxes)
                .filter(checkbox => checkbox.checked)
                .map(checkbox => {
                    // Cerca prima il testo dell'etichetta associata
                    if (checkbox.nextElementSibling && checkbox.nextElementSibling.tagName === 'LABEL') {
                        return checkbox.nextElementSibling.textContent.trim();
                    }
                    // Altrimenti usa il valore della checkbox
                    return checkbox.value || 'Servizio selezionato';
                });
            
            // Aggiorna il campo input
            if (serviziInput) {
                // Formato: Separato da virgole
                serviziInput.value = serviziSelezionati.join(', ');
                
                // Forza l'aggiornamento dell'input con diversi metodi
                serviziInput.dispatchEvent(new Event('change', { bubbles: true }));
                serviziInput.dispatchEvent(new Event('input', { bubbles: true }));
                serviziInput.setAttribute('value', serviziInput.value);
            }
        }
        
        // Aggiungi event listener a ogni checkbox di servizi
        serviziCheckboxes.forEach((checkbox) => {
            // Rimuovi eventuali listener precedenti
            checkbox.removeEventListener('click', updateServiziSelezionati);
            checkbox.removeEventListener('change', updateServiziSelezionati);
            
            // Aggiungi nuovi listener
            checkbox.addEventListener('click', updateServiziSelezionati);
            checkbox.addEventListener('change', updateServiziSelezionati);
        });
        
        // Intercetta il submit del form
        const form = document.querySelector('.wpcf7-form');
        if (form) {
            form.addEventListener('submit', updateServiziSelezionati);
        }
        
        // Aggiorna all'inizializzazione
        updateServiziSelezionati();
    }
    
    // Attendi che la pagina sia caricata e poi inizializza lo script
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initScript);
    } else {
        initScript();
    }
    
    // Per sicurezza, esegui anche un controllo ritardato
    setTimeout(initScript, 1500);
})();
</script>