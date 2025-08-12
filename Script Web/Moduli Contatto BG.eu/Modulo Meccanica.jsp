<div class="form-container">
    <div class="form-group inline-fields">
        <div>
            <label for="nome">Nome</label>
            [text* nome id:nome class:nome-input placeholder "Nome"]
        </div>
        <div>
            <label for="cognome">Cognome</label>
            [text* cognome id:cognome class:cognome-input placeholder "Cognome"]
        </div>
    </div>
    <div class="form-group inline-fields">
        <div>
            <label for="email">Email</label>
            [text* email id:email class:email-input placeholder "Email"]
        </div>
        <div>
            <label for="telefono">Telefono</label>
            [text* telefono id:telefono class:telefono-input placeholder "Telefono"]
        </div>
    </div>

    <div class="form-group" style="display: none;">
        <label for="cap">CAP</label>
        [text cap id:cap class:cap-input placeholder "CAP"]
    </div>

    <div class="form-group inline-fields">
        <div>
            <label for="targa">Targa veicolo</label>
            [text targa id:targa class:targa-input placeholder "Targa veicolo"]
        </div>
        <div>
            <label for="marca-veicolo">Marca veicolo</label>
            [text marcaveicolo id:marca-veicolo class:marca-veicolo-input placeholder "Marca veicolo"]
        </div>
        <div>
            <label for="modello-veicolo">Modello veicolo</label>
            [text modelloveicolo id:modello-veicolo class:modello-veicolo-input placeholder "Modello veicolo"]
        </div>
    </div>
    
    <!-- Campo per i servizi selezionati (compatibile con CF7) -->
    <div class="form-group">
        <label for="servizi-selezionati">Servizi selezionati</label>
        [text servizi_selezionati id:servizi-selezionati]
    </div>
    
    <!-- Campo "Tipologia preventivo" nascosto e preimpostato su "PREVENTIVO MECCANICA" -->
    <div class="form-group" style="display: none;">
        <label for="tipo-preventivo">Tipologia preventivo</label>
        [select* selected_tipo_preventivo id:tipo-preventivo class:preventivo-selector "PREVENTIVO MECCANICA"]
    </div>

    <!-- Sezioni pneumatici nascoste -->
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

    <!-- Sezione meccanica (mostrata per impostazione predefinita) -->
    <div class="preventivo-group preventivo_meccanica">
       <div class="form-group">
        <label for="km-manutenzione">KM</label>
           [text km id:km-manutenzione class:km-input placeholder "KM"]
       </div>
        <!-- Campo "Tipo manutenzione" nascosto perché sostituito dalle checkbox -->
        <div class="form-group" style="display: none;">
          <label for="tipo-manutenzione">Tipo manutenzione</label>
            [text tipo_manutenzione id:tipo-manutenzione class:tipo-manutenzione-input placeholder "Tipo manutenzione"]
        </div>
        
        <!-- Lista degli interventi di manutenzione selezionabili -->
        <div class="form-group">
            <label class="main-label">Seleziona gli interventi richiesti:</label>
            <div class="servizi-container">
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-olio" class="servizio-checkbox" value="Sostituzione Olio">
                    <label for="sostituzione-olio">Sostituzione Olio</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-filtro-olio" class="servizio-checkbox" value="Sostituzione Filtro Olio">
                    <label for="sostituzione-filtro-olio">Sostituzione Filtro Olio</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-filtro-aria" class="servizio-checkbox" value="Sostituzione Filtro Aria">
                    <label for="sostituzione-filtro-aria">Sostituzione Filtro Aria</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-filtro-abitacolo" class="servizio-checkbox" value="Sostituzione Filtro Abitacolo">
                    <label for="sostituzione-filtro-abitacolo">Sostituzione Filtro Abitacolo</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-filtro-carburante" class="servizio-checkbox" value="Sostituzione Filtro Carburante">
                    <label for="sostituzione-filtro-carburante">Sostituzione Filtro Carburante</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-candele" class="servizio-checkbox" value="Sostituzione Candele">
                    <label for="sostituzione-candele">Sostituzione Candele</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-dischi-pastiglie-ant" class="servizio-checkbox" value="Sostituzione Dischi + Pastiglie Anteriori">
                    <label for="sostituzione-dischi-pastiglie-ant">Sostituzione Dischi + Pastiglie Anteriori</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-dischi-pastiglie-post" class="servizio-checkbox" value="Sostituzione Dischi + Pastiglie Posteriori">
                    <label for="sostituzione-dischi-pastiglie-post">Sostituzione Dischi + Pastiglie Posteriori</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-pastiglie-ant" class="servizio-checkbox" value="Sostituzione Pastiglie Anteriori">
                    <label for="sostituzione-pastiglie-ant">Sostituzione Pastiglie Anteriori</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="sostituzione-pastiglie-post" class="servizio-checkbox" value="Sostituzione Pastiglie Posteriori">
                    <label for="sostituzione-pastiglie-post">Sostituzione Pastiglie Posteriori</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="pulizia-moto-idrogeno" class="servizio-checkbox" value="Pulizia Motore con Idrogeno">
                    <label for="pulizia-moto-idrogeno">Pulizia Motore con Idrogeno</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="pulizia-fap" class="servizio-checkbox" value="Pulizia FAP">
                    <label for="pulizia-fap">Pulizia FAP</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="revisione-bombole-metano" class="servizio-checkbox" value="Revisione Bombole Metano">
                    <label for="revisione-bombole-metano">Revisione Bombole Metano</label>
                </div>
                <div class="servizio-item">
                    <input type="checkbox" id="manutenzione-cambio-automatico" class="servizio-checkbox" value="Manutenzione Cambio Automatico">
                    <label for="manutenzione-cambio-automatico">Manutenzione Cambio Automatico</label>
                </div>
            </div>
        </div>
    </div>
    
    <div class="form-group">
         <label for="richiesta">Note aggiuntive o altre richieste</label>
        [textarea your-message id:richiesta class:richiesta-input placeholder "Inserisci qui altre richieste o dettagli aggiuntivi"]
    </div>
    
    <div class="form-group">
         <label for="negozio">Seleziona un centro</label>
        [select* menu-616 id:negozio first_as_label "- - Seleziona un centro - -" "BG1-BARGELLINO (Bologna)" "BG2-BORGO PANIGALE (Bologna)" "BG3-VILLANOVA (Castenaso)" "BG4-PONTE RIZZOLI (Ozzano Emilia)" "BG5-CASTEL GUELFO (Bologna)" "BG6-CASTEL SAN PIETRO (Bologna)" "BG7-FUNO DI ARGELATO (Bologna)"]
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
    .preventivo-group.hidden{
        display:none;
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
    
    /* Stile per gli elementi della lista servizi */
    .servizi-container {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 10px;
    }
    
    .servizio-item {
        display: flex;
        align-items: center;
        gap: 8px;
        padding: 6px;
        border: 1px solid #eee;
        border-radius: 4px;
        background-color: #f9f9f9;
    }
    
    .servizio-item:hover {
        background-color: #f0f0f0;
    }
    
    .servizio-item label {
        cursor: pointer;
        flex: 1;
    }
    
    .servizio-checkbox {
        cursor: pointer;
        width: 18px;
        height: 18px;
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
        .servizi-container {
            grid-template-columns: 1fr;
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