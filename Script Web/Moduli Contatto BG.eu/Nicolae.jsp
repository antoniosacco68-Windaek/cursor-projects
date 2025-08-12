
<div class="form-container">
    <div class="form-group inline-fields">
        <div>
            <label for="nome">* Nome</label>
            [text* nome id:nome class:nome-input placeholder "Nome"]
        </div>
        <div>
            <label for="cognome">* Cognome</label>
            [text* cognome id:cognome class:cognome-input placeholder "Cognome"]
        </div>
    </div>
    <div class="form-group">
        <div>
            <label for="email">* Email</label>
            [text* email id:email class:email-input placeholder "Email"]
        </div>
    </div>
    <div class="form-group inline-fields">
        <div>
            <label for="telefono">* Telefono</label>
            [text* telefono id:telefono class:telefono-input placeholder "Telefono"]
        </div>
        <div>
            <label for="targa">* Targa veicolo</label>
            [text targa id:targa class:targa-input placeholder "Targa veicolo"]
        </div>
    </div>
    <div class="form-group inline-fields">
        <div>
            <label for="marca-veicolo">* Marca veicolo</label>
            [text marcaveicolo id:marca-veicolo class:marca-veicolo-input placeholder "Marca veicolo"]
        </div>
        <div>
            <label for="modello-veicolo">* Modello veicolo</label>
            [text modelloveicolo id:modello-veicolo class:modello-veicolo-input placeholder "Modello veicolo"]
        </div>
    </div>
    <div class="form-group" style="display: none;">
        <div>
            <label for="cap">CAP</label>
            [text cap id:cap class:cap-input placeholder "CAP"]
        </div>
    </div>
    <div class="form-group">
      <label for="tipo-preventivo">Tipologia preventivo</label>
        [select* selected_tipo_preventivo id:tipo-preventivo class:preventivo-selector first_as_label "- - Tipologia preventivo - -" "PREVENTIVO PNEUMATICI" "PREVENTIVO MECCANICA" "PREVENTIVO PNEUMATICI MOTO"]
    </div>
    <div class="preventivo-group preventivo_pneumatici hidden">
         <div class="form-group tire-size-container">
            <label class="main-label">Misura pneumatici</label>
            <div class="tire-size-selectors">
              <div class="tire-select-group">
                   <label for="larghezza-pneumatico">Larghezza</label>
                    [select larghezza id:larghezza-pneumatico class:tire-select first_as_label "Larghezza"
                       "155" "165" "175" "185" "195" "205" "215" "225" "235" "245" "255" "265" "275" "285" "295" "305" "315" "325" "345" "355" "750"]
              </div>
              <div class="tire-select-group">
                 <label for="sezione-pneumatico">Spalla</label>
                   [select sezione id:sezione-pneumatico class:tire-select first_as_label "Spalla"
                    "25" "30" "35" "40" "45" "50" "55" "60" "65" "70" "75" "80" "85"]
              </div>
               <div class="tire-select-group">
                   <label for="diametro-pneumatico">Diametro</label>
                    [select diametro id:diametro-pneumatico class:tire-select first_as_label "Diametro"
                    "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24"]
              </div>
             <div class="tire-select-group">
                  <label for="carico-pneumatico">Carico</label>
                [select carico id:carico-pneumatico class:tire-select first_as_label "Carico" "74" "77" "79" "80" "81" "82" "83" "84" "85" "86" "87" "88" "89" "90" "91" "92" "93" "94" "95" "96" "97" "98" "99" "100" "101" "102" "103" "104" "105" "106" "107" "108" "109" "110" "111" "112" "113" "114" "115" "116" "117" "120" "121"]
               </div>
              <div class="tire-select-group">
                   <label for="velocita-pneumatico">Velocità</label>
                  [select velocita id:velocita-pneumatico class:tire-select first_as_label "Velocità" "N" "Q" "R" "S" "T" "H" "V" "W" "Y"]
              </div>
            </div>
        </div>
        <div class="form-group">
           <label for="stagionalita-pneumatico">Stagionalità Pneumatici</label>
           [select stagionalita id:stagionalita-pneumatico first_as_label "- - Stagionalità Pneumatici - -" "ESTIVE" "INVERNALI" "QUATTRO STAGIONI"]
        </div>
         <div>
            <label for="NrPneumatici">Numero Pneumatici</label>
            [select NrPneumatici id:NrPneumatici first_as_label "- - Nr Pneumatici - -" "1" "2" "3" "4"]
         </div>
        <div class="form-group">
           <label for="fascia-prezzo-pneumatico">Fascia Prezzo Pneumatici</label>
           [select fasciaprezzo id:fascia-prezzo-pneumatico first_as_label "- - Fascia Prezzo Pneumatico - -" "CLASSE T1 PREMIUM" "CLASSE T2 MEDIUM" "CLASSE T3 ECONOMY" "CLASSE T4 USATE" "CLASSE T5 LE NOSTRE PROPOSTE"]
        </div>
    </div>
     <div class="preventivo-group preventivo_pneumatici_moto hidden">
         <div class="form-group tire-size-container">
            <label class="main-label">Misura pneumatico anteriore</label>
            <div class="tire-size-selectors">
                <div class="tire-select-group">
                   <label for="larghezza-pneumatico-moto-ant">Larghezza Anteriore</label>
                    [select larghezza_moto_ant id:larghezza-pneumatico-moto-ant class:tire-select first_as_label "Larghezza"
                       "100" "110" "120" "125" "130" "140" "150" "160" "165" "170" "180" "190" "2" "200" "210" "240" "250" "260" "275" "3" "300" "325" "350" "4" "400" "410" "460" "60" "70" "80" "85" "90"]
                </div>
                <div class="tire-select-group">
                    <label for="sezione-pneumatico-moto-ant">Spalla Anteriore</label>
                    [select sezione_moto_ant id:sezione-pneumatico-moto-ant class:tire-select first_as_label "Spalla"
                        "25" "40" "45" "50" "55" "60" "65" "70" "75" "80" "85" "90" "100"]
                </div>
                <div class="tire-select-group">
                    <label for="diametro-pneumatico-moto-ant">Diametro Anteriore</label>
                    [select diametro_moto_ant id:diametro-pneumatico-moto-ant class:tire-select first_as_label "Diametro"
                    "10" "11" "12" "13" "8" "14" "15" "16" "17" "18" "19" "20" "21" "23" "420"]
                </div>
                <div class="tire-select-group">
                    <label for="carico-pneumatico-moto-ant">Carico Anteriore</label>
                    [select carico_moto_ant id:carico-pneumatico-moto-ant class:tire-select first_as_label "Carico" "29" "30" "33" "34" "35" "36" "37" "38" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72" "73" "74" "75" "76" "77" "78" "79" "80" "81" "82" "84" "86"]
                </div>
                <div class="tire-select-group">
                    <label for="velocita-pneumatico-moto-ant">Velocità Anteriore</label>
                    [select velocita_moto_ant id:velocita-pneumatico-moto-ant class:tire-select first_as_label "Velocità" "H" "J" "L" "M" "N" "P" "Q" "R" "S" "T" "V" "W"]
                </div>
            </div>
        </div>
         <div class="form-group tire-size-container">
            <label class="main-label">Misura pneumatico posteriore</label>
            <div class="tire-size-selectors">
              <div class="tire-select-group">
                   <label for="larghezza-pneumatico-moto-post">Larghezza Posteriore</label>
                    [select larghezza_moto_post id:larghezza-pneumatico-moto-post class:tire-select first_as_label "Larghezza"
                       "100" "110" "120" "125" "130" "140" "150" "160" "165" "170" "180" "190" "2" "200" "210" "240" "250" "260" "275" "3" "300" "325" "350" "4" "400" "410" "460" "60" "70" "80" "85" "90"]
              </div>
              <div class="tire-select-group">
                 <label for="sezione-pneumatico-moto-post">Spalla Posteriore</label>
                   [select sezione_moto_post id:sezione-pneumatico-moto-post class:tire-select first_as_label "Spalla"
                    "25" "40" "45" "50" "55" "60" "65" "70" "75" "80" "85" "90" "100"]
              </div>
               <div class="tire-select-group">
                   <label for="diametro-pneumatico-moto-post">Diametro Posteriore</label>
                    [select diametro_moto_post id:diametro-pneumatico-moto-post class:tire-select first_as_label "Diametro"
                    "10" "11" "12" "13" "8" "14" "15" "16" "17" "18" "19" "20" "21" "23" "420"]
              </div>
             <div class="tire-select-group">
                  <label for="carico-pneumatico-moto-post">Carico Posteriore</label>
                [select carico_moto_post id:carico-pneumatico-moto-post class:tire-select first_as_label "Carico" "29" "30" "33" "34" "35" "36" "37" "38" "40" "41" "42" "43" "44" "45" "46" "47" "48" "49" "50" "51" "52" "53" "54" "55" "56" "57" "58" "59" "60" "61" "62" "63" "64" "65" "66" "67" "68" "69" "70" "71" "72" "73" "74" "75" "76" "77" "78" "79" "80" "81" "82" "84" "86"]
               </div>
              <div class="tire-select-group">
                   <label for="velocita-pneumatico-moto-post">Velocità Posteriore</label>
                  [select velocita_moto_post id:velocita-pneumatico-moto-post class:tire-select first_as_label "Velocità" "H" "J" "L" "M" "N" "P" "Q" "R" "S" "T" "V" "W"]
              </div>
            </div>
        </div>
    </div>

    <div class="preventivo-group preventivo_meccanica hidden">
       <div class="form-group">
        <label for="km-manutenzione">KM</label>
           [text km id:km-manutenzione class:km-input placeholder "KM"]
       </div>
        <div class="form-group">
          <label for="tipo-manutenzione">Tipo manutenzione</label>
            [text tipo_manutenzione id:tipo-manutenzione class:tipo-manutenzione-input placeholder "Tipo manutenzione"]
        </div>
    </div>
    
    <div class="form-group">
         <label for="negozio">Seleziona un centro</label>
        [select* menu-616 id:negozio first_as_label "- - Seleziona un centro - -" "BG1-BARGELLINO (Bologna)" "BG2-BORGO PANIGALE (Bologna)" "BG3-VILLANOVA (Castenaso)" "BG4-PONTE RIZZOLI (Ozzano Emilia)" "BG5-CASTEL GUELFO (Bologna)" "BG6-CASTEL SAN PIETRO (Bologna)" "BG7-FUNO DI ARGELATO (Bologna)"]
    </div>
    <div class="form-group">
         <label for="richiesta">Testo della tua richiesta</label>
        [textarea your-message id:richiesta class:richiesta-input placeholder "Testo della tua richiesta"]
    </div>

    <div class="checkbox-contatti form-group">
       [checkbox* checkbox-244 id:privacy-check "Ho letto e accettato le condizioni elencate nella nostra"]
       <a href="/privacy" target="_blank">privacy policy</a> (ai sensi dell'art. 13 del GDPR 679/2016)
    </div>
    <div class="checkbox-contatti form-group">
        [checkbox newsletter id:newsletter-check "Autorizzo"] al trattamento dei miei dati per finalità di marketing elencate nella 
        <a href="/privacy" target="_blank">privacy policy</a> (ai sensi dell'art.9 e art. 13 del GDPR 679/2016) e all'iscrizione alla newsletter.
    </div>
    <p style="text-align: center;">[submit "Invia Richiesta"]</p>
</div>

<script>
(function(){
  // Oggetti di dati per memorizzare le combinazioni valide
  let tireData = {}, tireDataMoto = {};
  let tiresDataReady = false; // Flag per indicare se i dati sono stati caricati

  // Debug flag - imposta a true per vedere i messaggi di debug dettagliati
  const DEBUG = true;
  
  function debugLog(...args) {
    if (DEBUG) {
      console.log(...args);
    }
  }

  // Costruisce la struttura dati dalle informazioni nel JSON
  function buildMap(list) {
    debugLog("Costruzione mappa dai dati...", list.length, "elementi");
    const out = {};
    
    if (!Array.isArray(list)) {
      console.error("Formato dati non valido:", list);
      return out;
    }
    
    list.forEach(line => {
      if (typeof line !== 'string') return;
      
      // Analizza ogni elemento separato da trattini
      const parts = line.split('-');
      if (parts.length !== 5) return;
      
      const [width, ratio, diameter, load, speed] = parts;
      
      // Verifica che tutti i componenti siano presenti
      if (!width || !ratio || !diameter || !load || !speed) {
        debugLog("Dati incompleti:", line);
        return;
      }
      
      // Aggiungi larghezza se non esiste ancora
      if (!out[width]) {
        out[width] = {};
      }
      
      // Aggiungi rapporto se non esiste ancora per questa larghezza
      if (!out[width][ratio]) {
        out[width][ratio] = {};
      }
      
      // Aggiungi diametro se non esiste ancora per questo rapporto
      if (!out[width][ratio][diameter]) {
        out[width][ratio][diameter] = {};
      }
      
      // Aggiungi carico se non esiste ancora per questo diametro
      if (!out[width][ratio][diameter][load]) {
        out[width][ratio][diameter][load] = [];
      }
      
      // Aggiungi velocità se non è già presente
      if (!out[width][ratio][diameter][load].includes(speed)) {
        out[width][ratio][diameter][load].push(speed);
      }
    });
    
    debugLog("Mappa costruita con", Object.keys(out).length, "larghezze uniche");
    return out;
  }

  // Inizializza i menu a discesa con i valori filtrati
  function initTireFilter(map, selectors, preventivo) {
    debugLog(`Inizializzazione filtri pneumatici per "${preventivo}" con selettori:`, selectors);
    
    // Verifica prima se tutti i selettori sono presenti nel DOM 
    const allElementsExist = selectors.every(selector => document.querySelector(selector));
    if (!allElementsExist) {
      debugLog(`Impossibile trovare tutti gli elementi per "${preventivo}". Verifica che il preventivo sia visibile nel DOM.`);
      return false;
    }
    
    // Recupera tutti gli elementi dei menu a discesa
    const elements = selectors.map(selector => document.querySelector(selector));
    const [widthSelect, ratioSelect, diameterSelect, loadSelect, speedSelect] = elements;
    
    debugLog("Elementi trovati:", 
             "width:", widthSelect.id, 
             "ratio:", ratioSelect.id, 
             "diameter:", diameterSelect.id, 
             "load:", loadSelect.id, 
             "speed:", speedSelect.id);
    
    // Funzione per ripulire un menu a discesa e mantenere solo la prima opzione
    function resetSelect(select) {
      if (!select) return;
      
      const defaultOption = select.options[0];
      select.innerHTML = '';
      
      if (defaultOption) {
        select.appendChild(new Option(defaultOption.text, defaultOption.value));
      }
      
      select.selectedIndex = 0;
    }
    
    // Funzione per popolare un menu a discesa con valori filtrati
    function populateSelect(select, values) {
      if (!select || !Array.isArray(values) || values.length === 0) return;
      
      // Ordina numericamente
      const sortedValues = [...values].sort((a, b) => {
        const numA = parseFloat(a);
        const numB = parseFloat(b);
        return numA - numB;
      });
      
      sortedValues.forEach(value => {
        select.appendChild(new Option(value, value));
      });
      
      debugLog(`Popolato ${select.id} con ${sortedValues.length} opzioni:`, sortedValues);
    }
    
    // All'apertura della pagina, popola il menu delle larghezze in base ai dati disponibili
    function initializeWidths() {
      debugLog(`Inizializzazione larghezze disponibili per "${preventivo}"`);
      resetSelect(widthSelect);
      
      const availableWidths = Object.keys(map);
      if (availableWidths.length > 0) {
        populateSelect(widthSelect, availableWidths);
        debugLog(`Dropdown larghezze inizializzato con ${availableWidths.length} opzioni`);
      } else {
        console.warn(`Nessuna larghezza disponibile nei dati per "${preventivo}"`);
      }
    }
    
    // Gestisce il cambio di larghezza
    widthSelect.addEventListener('change', function() {
      debugLog("EVENTO: Cambio larghezza");
      
      // Reimposta i menu dipendenti
      resetSelect(ratioSelect);
      resetSelect(diameterSelect);
      resetSelect(loadSelect);
      resetSelect(speedSelect);
      
      const selectedWidth = this.value;
      debugLog("Larghezza selezionata:", selectedWidth);
      
      // Se è selezionata l'opzione di default o non ci sono dati, esce
      if (!selectedWidth || selectedWidth === widthSelect.options[0].value || !map[selectedWidth]) {
        debugLog("Nessuna larghezza valida selezionata o nessun dato disponibile");
        return;
      }
      
      // Ottiene e popola i rapporti disponibili per questa larghezza
      const availableRatios = Object.keys(map[selectedWidth]);
      populateSelect(ratioSelect, availableRatios);
      debugLog(`Trovati ${availableRatios.length} rapporti per larghezza ${selectedWidth}:`, availableRatios);
    });
    
    // Gestisce il cambio di rapporto
    ratioSelect.addEventListener('change', function() {
      debugLog("EVENTO: Cambio rapporto");
      
      // Reimposta i menu dipendenti
      resetSelect(diameterSelect);
      resetSelect(loadSelect);
      resetSelect(speedSelect);
      
      const selectedWidth = widthSelect.value;
      const selectedRatio = this.value;
      debugLog("Valori selezionati:", "Larghezza:", selectedWidth, "Rapporto:", selectedRatio);
      
      // Se è selezionata l'opzione di default o non ci sono dati, esce
      if (!selectedRatio || selectedRatio === ratioSelect.options[0].value || 
          !map[selectedWidth] || !map[selectedWidth][selectedRatio]) {
        debugLog("Nessun rapporto valido selezionato o nessun dato disponibile");
        return;
      }
      
      // Ottiene e popola i diametri disponibili per questo rapporto
      const availableDiameters = Object.keys(map[selectedWidth][selectedRatio]);
      populateSelect(diameterSelect, availableDiameters);
      debugLog(`Trovati ${availableDiameters.length} diametri per larghezza ${selectedWidth} e rapporto ${selectedRatio}:`, availableDiameters);
    });
    
    // Gestisce il cambio di diametro
    diameterSelect.addEventListener('change', function() {
      debugLog("EVENTO: Cambio diametro");
      
      // Reimposta i menu dipendenti
      resetSelect(loadSelect);
      resetSelect(speedSelect);
      
      const selectedWidth = widthSelect.value;
      const selectedRatio = ratioSelect.value;
      const selectedDiameter = this.value;
      debugLog("Valori selezionati:", "Larghezza:", selectedWidth, "Rapporto:", selectedRatio, "Diametro:", selectedDiameter);
      
      // Se è selezionata l'opzione di default o non ci sono dati, esce
      if (!selectedDiameter || selectedDiameter === diameterSelect.options[0].value || 
          !map[selectedWidth] || !map[selectedWidth][selectedRatio] || 
          !map[selectedWidth][selectedRatio][selectedDiameter]) {
        debugLog("Nessun diametro valido selezionato o nessun dato disponibile");
        return;
      }
      
      // Ottiene e popola i carichi disponibili per questo diametro
      const availableLoads = Object.keys(map[selectedWidth][selectedRatio][selectedDiameter]);
      populateSelect(loadSelect, availableLoads);
      debugLog(`Trovati ${availableLoads.length} carichi per la combinazione selezionata:`, availableLoads);
    });
    
    // Gestisce il cambio di carico
    loadSelect.addEventListener('change', function() {
      debugLog("EVENTO: Cambio carico");
      
      // Reimposta il menu dipendente
      resetSelect(speedSelect);
      
      const selectedWidth = widthSelect.value;
      const selectedRatio = ratioSelect.value;
      const selectedDiameter = diameterSelect.value;
      const selectedLoad = this.value;
      debugLog("Valori selezionati:", "Larghezza:", selectedWidth, "Rapporto:", selectedRatio, 
              "Diametro:", selectedDiameter, "Carico:", selectedLoad);
      
      // Se è selezionata l'opzione di default o non ci sono dati, esce
      if (!selectedLoad || selectedLoad === loadSelect.options[0].value || 
          !map[selectedWidth] || !map[selectedWidth][selectedRatio] || 
          !map[selectedWidth][selectedRatio][selectedDiameter] || 
          !map[selectedWidth][selectedRatio][selectedDiameter][selectedLoad]) {
        debugLog("Nessun carico valido selezionato o nessun dato disponibile");
        return;
      }
      
      // Ottiene e popola le velocità disponibili per questo carico
      const availableSpeeds = map[selectedWidth][selectedRatio][selectedDiameter][selectedLoad];
      populateSelect(speedSelect, availableSpeeds);
      debugLog(`Trovate ${availableSpeeds.length} velocità per la combinazione selezionata:`, availableSpeeds);
    });
    
    // Inizializza il menu delle larghezze
    initializeWidths();
    return true;
  }

  // Inizializza i filtri solo per il preventivo selezionato
  function initFiltersByPreventivo(preventivoType) {
    debugLog(`Inizializzazione filtri per preventivo: ${preventivoType}`);
    
    // Se i dati non sono ancora pronti, esci
    if (!tiresDataReady) {
      debugLog("Dati pneumatici non ancora pronti, caricamento in corso...");
      return;
    }
    
    // Inizializza solo i filtri relativi al preventivo selezionato
    if (preventivoType === 'PREVENTIVO PNEUMATICI') {
      debugLog("Inizializzazione filtri pneumatici auto");
      initTireFilter(tireData, [
        '#larghezza-pneumatico',
        '#sezione-pneumatico',
        '#diametro-pneumatico',
        '#carico-pneumatico',
        '#velocita-pneumatico'
      ], "Auto");
    } 
    else if (preventivoType === 'PREVENTIVO PNEUMATICI MOTO') {
      debugLog("Inizializzazione filtri pneumatici moto anteriori");
      initTireFilter(tireDataMoto, [
        '#larghezza-pneumatico-moto-ant',
        '#sezione-pneumatico-moto-ant',
        '#diametro-pneumatico-moto-ant',
        '#carico-pneumatico-moto-ant',
        '#velocita-pneumatico-moto-ant'
      ], "Moto Anteriori");
      
      debugLog("Inizializzazione filtri pneumatici moto posteriori");
      initTireFilter(tireDataMoto, [
        '#larghezza-pneumatico-moto-post',
        '#sezione-pneumatico-moto-post',
        '#diametro-pneumatico-moto-post',
        '#carico-pneumatico-moto-post',
        '#velocita-pneumatico-moto-post'
      ], "Moto Posteriori");
    }
  }

  // Mostra/nasconde le sezioni preventivo in base alla selezione
  function toggleGroups() {
    // Prova più selettori possibili per il dropdown
    const selectElement = document.querySelector('#tipo-preventivo, .preventivo-selector, [name="selected_tipo_preventivo"]');
    
    if (!selectElement) {
      console.warn('Preventivo select element not found');
      return;
    }
    
    const selectedValue = selectElement.value;
    debugLog('Tipologia preventivo selected:', selectedValue);
    
    // Se non è stato selezionato nessun valore o è l'opzione default, esci
    if (!selectedValue || selectedValue === selectElement.options[0].value) {
      debugLog('Nessun preventivo selezionato o selezionata opzione di default');
      return;
    }
    
    // Nasconde tutti i gruppi preventivo prima
    const allGroups = document.querySelectorAll('.preventivo-group');
    allGroups.forEach(group => {
      group.classList.add('hidden');
      group.style.display = 'none';
    });
    
    // Mostra il gruppo appropriato in base alla selezione
    if (selectedValue === 'PREVENTIVO PNEUMATICI') {
      const target = document.querySelector('.preventivo_pneumatici');
      if (target) {
        target.classList.remove('hidden');
        target.style.display = 'block';
        debugLog('Showing pneumatici group');
        
        // Inizializza i filtri per questo tipo di preventivo
        // Aspetta un momento per dare tempo al DOM di aggiornare la visualizzazione
        setTimeout(() => initFiltersByPreventivo(selectedValue), 300);
      }
    } 
    else if (selectedValue === 'PREVENTIVO PNEUMATICI MOTO') {
      const target = document.querySelector('.preventivo_pneumatici_moto');
      if (target) {
        target.classList.remove('hidden');
        target.style.display = 'block';
        debugLog('Showing pneumatici moto group');
        
        // Inizializza i filtri per questo tipo di preventivo
        // Aspetta un momento per dare tempo al DOM di aggiornare la visualizzazione
        setTimeout(() => initFiltersByPreventivo(selectedValue), 300);
      }
    } 
    else if (selectedValue === 'PREVENTIVO MECCANICA') {
      const target = document.querySelector('.preventivo_meccanica');
      if (target) {
        target.classList.remove('hidden');
        target.style.display = 'block';
        debugLog('Showing meccanica group');
      }
    }
  }

  // Aggiunge listener di eventi per il selettore del tipo di preventivo
  function setupSelectListeners() {
    // Prova più selettori possibili
    const selectElement = document.querySelector('#tipo-preventivo, .preventivo-selector, [name="selected_tipo_preventivo"]');
    
    if (selectElement) {
      debugLog('Found select element:', selectElement);
      
      // Aggiunge listener di eventi
      selectElement.addEventListener('change', function() {
        toggleGroups();
      });
      
      // Verifica subito se c'è già un valore selezionato
      if (selectElement.value && selectElement.value !== selectElement.options[0].value) {
        debugLog('Valore già selezionato al caricamento:', selectElement.value);
        toggleGroups();
      }
    } else {
      console.warn('Select element not found for event binding');
    }
  }

  // Carica i dati degli pneumatici dal JSON con dati di fallback
  function loadTireData() {
    // Definisce dati di fallback in caso di fallimento del fetch
    const fallbackData = {
      auto: [
        "155-60-15-74-T", "155-60-20-80-Q", "155-65-14-79-T", "155-70-19-84-Q", "155-70-19-88-Q",
        "165-65-14-79-H", "185-60-15-84-V", "195-65-15-91-H", "205-55-16-91-V", "225-45-17-94-W"
      ],
      moto: [
        "120-70-17-58-H", "180-55-17-73-W", "190-50-17-73-W"
      ]
    };
    
    debugLog('Caricamento dati pneumatici da /wp-content/misure.json');
    
    // Per test locale, carica i dati direttamente dal file JSON
    const testData = {
      auto: [
        "155-60-15-74-T", "155-60-15-74-T", "155-60-20-80-Q", "155-65-14-79-T", "155-70-19-84-Q", "155-70-19-88-Q",
        "165-60-14-75-H", "165-60-15-81-H", "165-60-15-81-T", "165-65-14-83-T", "165-65-15-81-T"
        // ... altri dati auto
      ],
      moto: [
        "155-60-15-74-T", "155-60-15-74-T", "155-60-20-80-Q", "155-65-14-79-T", "155-70-19-84-Q", "155-70-19-88-Q"
        // ... altri dati moto
      ]
    };
    
    // In ambiente di test/sviluppo, usa direttamente i dati incorporati
    if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      debugLog('Ambiente locale rilevato, utilizzo dati di test');
      return Promise.resolve(testData);
    }
    
    return fetch('/wp-content/misure.json')
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! Status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        debugLog('Dati pneumatici caricati con successo');
        
        // Verifica che i dati abbiano il formato atteso
        if (!data.auto || !data.moto || !Array.isArray(data.auto) || !Array.isArray(data.moto)) {
          console.error('Formato dati JSON non valido');
          return fallbackData;
        }
        
        return data;
      })
      .catch(error => {
        console.error('Errore nel caricamento dei dati:', error);
        debugLog('Utilizzo dati di fallback');
        return fallbackData;
      });
  }

  // Inizializza il modulo
  function initForm() {
    debugLog('Inizializzazione form...');
    
    // Carica i dati degli pneumatici 
    loadTireData()
      .then(data => {
        // Genera la struttura dati per i filtri
        tireData = buildMap(data.auto);
        tireDataMoto = buildMap(data.moto);
        
        debugLog('Dati pneumatici elaborati con successo');
        debugLog('Numero pneumatici auto:', Object.keys(tireData).length);
        debugLog('Numero pneumatici moto:', Object.keys(tireDataMoto).length);
        
        // Imposta il flag che indica che i dati sono pronti
        tiresDataReady = true;
        
        // Verifica se un preventivo è già selezionato e inizializza i filtri per esso
        const selectElement = document.querySelector('#tipo-preventivo, .preventivo-selector, [name="selected_tipo_preventivo"]');
        if (selectElement && selectElement.value && selectElement.value !== selectElement.options[0].value) {
          toggleGroups();
        }
      })
      .catch(error => {
        console.error('Errore inizializzazione form:', error);
      });
    
    // Configura i listener di eventi per il dropdown
    setupSelectListeners();
  }

  // Aggiunge delegazione di eventi per gestire i cambiamenti su elementi caricati dinamicamente
  document.body.addEventListener('change', function(event) {
    if (event.target.id === 'tipo-preventivo' || 
        event.target.classList.contains('preventivo-selector') ||
        event.target.name === 'selected_tipo_preventivo') {
      debugLog('Preventivo select changed via delegation');
      toggleGroups();
    }
  });

  // Supporto per gli eventi di Contact Form 7
  document.addEventListener('wpcf7init', function() {
    debugLog('CF7 inizializzato, caricamento dati...');
    setTimeout(initForm, 500); // Tempo più breve per caricare i dati più velocemente
  });

  // Inizializza al caricamento della pagina
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initForm);
  } else {
    // DOM già caricato
    debugLog('DOM già caricato, inizializzazione immediata');
    initForm();
  }
})();
</script>


<style>
    .form-container {
        display: flex;
        flex-direction: column;
        gap: 10px;
    }
    .form-group{
        display: flex;
        flex-direction: column;
        gap:5px;
    }
    .main-label{
        display: block;
        margin-bottom: 5px;
        font-weight: bold;
    }
     .tire-size-container {
        margin-bottom: 10px;
    }
    .tire-size-selectors{
        display: flex;
        flex-wrap: wrap;
        gap: 10px;
    }

   .tire-select-group {
        flex-grow: 1;
        flex-basis: calc(20% - 10px);
        min-width: calc(20% - 10px);
    }
.preventivo-group.hidden {
  display: none !important;  /* Using !important to override any other display styles */
}
    .tire-select {
        width: 100%;
        padding: 8px;
        border: 1px solid #ccc;
        border-radius: 4px;
    }

    .checkbox-contatti {
    display: flex;
    align-items: center;
    gap: 5px;
    margin-bottom: 10px;
  }
  
    .checkbox-contatti a {
      color: #000000;
      text-decoration: none;
    }

    .checkbox-contatti a:hover {
      text-decoration: underline;
    }
    /* Placeholders Style */
    ::placeholder {
       color: #000000;
       opacity: 2;
    }
    /* Media Query per schermi piccoli (es. telefoni) */
    @media (max-width: 768px) {
       .tire-size-selectors {
            flex-direction: column;
        }
        .tire-select-group {
           width: 100%;
           min-width: auto;
           margin-bottom: 10px;
        }
    }
    /* New Rules */
    .form-group.inline-fields {
        display: flex;
        flex-direction: row;
        gap: 20px; /* Spazio tra i campi */
        align-items: flex-start; /* Allinea i campi in alto */
    }
    .form-group.inline-fields > div {
        flex: 1; /* Distribuisce lo spazio tra i campi */
    }
</style>