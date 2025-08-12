document.addEventListener('DOMContentLoaded', function() {
    const tireMotoData = tireDataMotoString.trim().split('\n').map(line => line.trim()).filter(line => line.length > 0);
    const tiresMotoObj = {};
    
    tireMotoData.forEach(tireStr => {
        const [larghezza, spalla, diametro, carico, velocita] = tireStr.split('-');
        if (!tiresMotoObj[larghezza]) tiresMotoObj[larghezza] = {};
        if (!tiresMotoObj[larghezza][spalla]) tiresMotoObj[larghezza][spalla] = {};
        if (!tiresMotoObj[larghezza][spalla][diametro]) tiresMotoObj[larghezza][spalla][diametro] = {};
        if (!tiresMotoObj[larghezza][spalla][diametro][carico]) tiresMotoObj[larghezza][spalla][diametro][carico] = [];
        tiresMotoObj[larghezza][spalla][diametro][carico].push(velocita);
    });

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

    // Funzioni di aggiornamento per pneumatici anteriori
    function updateAntSelectors() {
        const larghezzaSelect = getSelector('larghezza-pneumatico-ant') || getSelector('larghezza_ant');
        const spallaSelect = getSelector('sezione-pneumatico-ant') || getSelector('sezione_ant');
        const diametroSelect = getSelector('diametro-pneumatico-ant') || getSelector('diametro_ant');
        const caricoSelect = getSelector('carico-pneumatico-ant') || getSelector('carico_ant');
        const velocitaSelect = getSelector('velocita-pneumatico-ant') || getSelector('velocita_ant');
        
        if (!larghezzaSelect || !spallaSelect || !diametroSelect || !caricoSelect || !velocitaSelect) {
            console.error('Non è stato possibile trovare tutti i selettori necessari per il filtro pneumatici anteriori');
            return;
        }
        
        const larghezzaValue = larghezzaSelect.value;
        const spallaValue = spallaSelect.value;
        const diametroValue = diametroSelect.value;
        const caricoValue = caricoSelect.value;
        
        // Reset and update spalla based on larghezza
        if (larghezzaValue && larghezzaValue !== '- - Larghezza - -') {
            const availableSpalle = Object.keys(tiresMotoObj[larghezzaValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentSpalla = spallaSelect.value;
            
            spallaSelect.innerHTML = '<option value="- - Spalla - -">- - Spalla - -</option>';
            availableSpalle.forEach(sez => {
                spallaSelect.innerHTML += `<option value="${sez}">${sez}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableSpalle.includes(currentSpalla)) {
                spallaSelect.value = currentSpalla;
            }
        }
        
        // Reset and update diametro based on larghezza and spalla
        if (larghezzaValue && spallaValue && spallaValue !== '- - Spalla - -') {
            const availableDiametri = Object.keys(tiresMotoObj[larghezzaValue][spallaValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentDiametro = diametroSelect.value;
            
            diametroSelect.innerHTML = '<option value="- - Diametro - -">- - Diametro - -</option>';
            availableDiametri.forEach(diam => {
                diametroSelect.innerHTML += `<option value="${diam}">${diam}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableDiametri.includes(currentDiametro)) {
                diametroSelect.value = currentDiametro;
            }
        }
        
        // Reset and update carico based on larghezza, spalla, and diametro
        if (larghezzaValue && spallaValue && diametroValue && diametroValue !== '- - Diametro - -') {
            const availableCarichi = Object.keys(tiresMotoObj[larghezzaValue][spallaValue][diametroValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentCarico = caricoSelect.value;
            
            caricoSelect.innerHTML = '<option value="- - Carico - -">- - Carico - -</option>';
            availableCarichi.forEach(car => {
                caricoSelect.innerHTML += `<option value="${car}">${car}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableCarichi.includes(currentCarico)) {
                caricoSelect.value = currentCarico;
            }
        }
        
        // Reset and update velocita based on larghezza, spalla, diametro, and carico
        if (larghezzaValue && spallaValue && diametroValue && caricoValue && caricoValue !== '- - Carico - -') {
            const availableVelocita = tiresMotoObj[larghezzaValue][spallaValue][diametroValue][caricoValue] || [];
            
            // Salva il valore corrente se possibile
            const currentVelocita = velocitaSelect.value;
            
            velocitaSelect.innerHTML = '<option value="- - Velocità - -">- - Velocità - -</option>';
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
    
    // Funzioni di aggiornamento per pneumatici posteriori
    function updatePostSelectors() {
        const larghezzaSelect = getSelector('larghezza-pneumatico-post') || getSelector('larghezza_post');
        const spallaSelect = getSelector('sezione-pneumatico-post') || getSelector('sezione_post');
        const diametroSelect = getSelector('diametro-pneumatico-post') || getSelector('diametro_post');
        const caricoSelect = getSelector('carico-pneumatico-post') || getSelector('carico_post');
        const velocitaSelect = getSelector('velocita-pneumatico-post') || getSelector('velocita_post');
        
        if (!larghezzaSelect || !spallaSelect || !diametroSelect || !caricoSelect || !velocitaSelect) {
            console.error('Non è stato possibile trovare tutti i selettori necessari per il filtro pneumatici posteriori');
            return;
        }
        
        const larghezzaValue = larghezzaSelect.value;
        const spallaValue = spallaSelect.value;
        const diametroValue = diametroSelect.value;
        const caricoValue = caricoSelect.value;
        
        // Reset and update spalla based on larghezza
        if (larghezzaValue && larghezzaValue !== '- - Larghezza - -') {
            const availableSpalle = Object.keys(tiresMotoObj[larghezzaValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentSpalla = spallaSelect.value;
            
            spallaSelect.innerHTML = '<option value="- - Spalla - -">- - Spalla - -</option>';
            availableSpalle.forEach(sez => {
                spallaSelect.innerHTML += `<option value="${sez}">${sez}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableSpalle.includes(currentSpalla)) {
                spallaSelect.value = currentSpalla;
            }
        }
        
        // Reset and update diametro based on larghezza and spalla
        if (larghezzaValue && spallaValue && spallaValue !== '- - Spalla - -') {
            const availableDiametri = Object.keys(tiresMotoObj[larghezzaValue][spallaValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentDiametro = diametroSelect.value;
            
            diametroSelect.innerHTML = '<option value="- - Diametro - -">- - Diametro - -</option>';
            availableDiametri.forEach(diam => {
                diametroSelect.innerHTML += `<option value="${diam}">${diam}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableDiametri.includes(currentDiametro)) {
                diametroSelect.value = currentDiametro;
            }
        }
        
        // Reset and update carico based on larghezza, spalla, and diametro
        if (larghezzaValue && spallaValue && diametroValue && diametroValue !== '- - Diametro - -') {
            const availableCarichi = Object.keys(tiresMotoObj[larghezzaValue][spallaValue][diametroValue] || {}).sort((a, b) => parseInt(a) - parseInt(b));
            
            // Salva il valore corrente se possibile
            const currentCarico = caricoSelect.value;
            
            caricoSelect.innerHTML = '<option value="- - Carico - -">- - Carico - -</option>';
            availableCarichi.forEach(car => {
                caricoSelect.innerHTML += `<option value="${car}">${car}</option>`;
            });
            
            // Ripristina il valore precedente se ancora valido
            if (availableCarichi.includes(currentCarico)) {
                caricoSelect.value = currentCarico;
            }
        }
        
        // Reset and update velocita based on larghezza, spalla, diametro, and carico
        if (larghezzaValue && spallaValue && diametroValue && caricoValue && caricoValue !== '- - Carico - -') {
            const availableVelocita = tiresMotoObj[larghezzaValue][spallaValue][diametroValue][caricoValue] || [];
            
            // Salva il valore corrente se possibile
            const currentVelocita = velocitaSelect.value;
            
            velocitaSelect.innerHTML = '<option value="- - Velocità - -">- - Velocità - -</option>';
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
    
    // Aggiungi event listener ai selettori
    function addSelectorListeners() {
        // Selettori pneumatici anteriori
        const antSelectors = [
            getSelector('larghezza-pneumatico-ant') || getSelector('larghezza_ant'),
            getSelector('sezione-pneumatico-ant') || getSelector('sezione_ant'),
            getSelector('diametro-pneumatico-ant') || getSelector('diametro_ant'),
            getSelector('carico-pneumatico-ant') || getSelector('carico_ant')
        ].filter(selector => selector !== null);
        
        antSelectors.forEach(selector => {
            selector.addEventListener('change', updateAntSelectors);
        });
        
        // Selettori pneumatici posteriori
        const postSelectors = [
            getSelector('larghezza-pneumatico-post') || getSelector('larghezza_post'),
            getSelector('sezione-pneumatico-post') || getSelector('sezione_post'),
            getSelector('diametro-pneumatico-post') || getSelector('diametro_post'),
            getSelector('carico-pneumatico-post') || getSelector('carico_post')
        ].filter(selector => selector !== null);
        
        postSelectors.forEach(selector => {
            selector.addEventListener('change', updatePostSelectors);
        });
    }

    // Funzione per correggere i colori dei placeholder nelle select
    function fixPlaceholderColors() {
        const selects = document.querySelectorAll('.tire-select');
        selects.forEach(select => {
            // Imposta il colore iniziale
            if (select.selectedIndex === 0) {
                select.style.color = '#999999'; // grigio per i placeholder
            } else {
                select.style.color = '#000000'; // nero per i valori selezionati
            }
            
            // Aggiungi listener per il cambio
            select.addEventListener('change', function() {
                if (this.selectedIndex === 0) {
                    this.style.color = '#999999'; // grigio per i placeholder
                } else {
                    this.style.color = '#000000'; // nero per i valori selezionati
                }
            });
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
    }
    
    // Inizializza quando il DOM è pronto
    initializeWhenReady();
    
    // In alcune configurazioni, CF7 potrebbe modificare il DOM dopo l'evento DOMContentLoaded
    // Quindi impostiamo altri timer per essere sicuri
    setTimeout(initializeWhenReady, 500);
    setTimeout(initializeWhenReady, 1000);
    setTimeout(initializeWhenReady, 2000);
});
