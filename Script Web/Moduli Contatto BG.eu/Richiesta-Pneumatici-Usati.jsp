<div class="form-container">
    <div class="form-group tire-size-container">
        <label class="main-label" style="text-align: left; font-weight: bold;">MISURA PNEUMATICI OBBLIGATORIA</label>
        <div class="tire-size-selectors">
            <div class="tire-select-group">
                <label for="larghezza-pneumatico">* Larghezza</label>
                [select* larghezza id:larghezza-pneumatico class:tire-select first_as_label "- - Larghezza - -"
                    "155" "165" "175" "185" "195" "205" "215" "225" "235" "245" "255" "265" "275" "285" "295" "305" "315" "325" "345" "355" "750"]
            </div>
            <div class="tire-select-group">
                <label for="sezione-pneumatico">* Spalla</label>
                [select* sezione id:sezione-pneumatico class:tire-select first_as_label "- - Spalla - -"
                    "25" "30" "35" "40" "45" "50" "55" "60" "65" "70" "75" "80" "85"]
            </div>
            <div class="tire-select-group">
                <label for="diametro-pneumatico">* Diametro</label>
                [select* diametro id:diametro-pneumatico class:tire-select first_as_label "- - Diametro - -"
                    "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24"]
            </div>
            <div class="tire-select-group">
                <label for="carico-pneumatico">* Carico</label>
                [select* carico id:carico-pneumatico class:tire-select first_as_label "- - Carico - -" "74" "77" "79" "80" "81" "82" "83" "84" "85" "86" "87" "88" "89" "90" "91" "92" "93" "94" "95" "96" "97" "98" "99" "100" "101" "102" "103" "104" "105" "106" "107" "108" "109" "110" "111" "112" "113" "114" "115" "116" "117" "120" "121"]
            </div>
            <div class="tire-select-group">
                <label for="velocita-pneumatico">* Velocità</label>
                [select* velocita id:velocita-pneumatico class:tire-select first_as_label "- - Velocità - -" "N" "Q" "R" "S" "T" "H" "V" "W" "Y"]
            </div>
        </div>
    </div>
    
    <div class="form-group">
        <label for="stagionalita-pneumatico">* Stagionalità Pneumatici</label>
        [select* stagionalita id:stagionalita-pneumatico first_as_label "- - Stagionalità Pneumatici - -" "ESTIVE" "INVERNALI" "QUATTRO STAGIONI"]
    </div>
    
    <div class="form-group">
        <label for="NrPneumatici">* Numero Pneumatici</label>
        [select* NrPneumatici id:NrPneumatici first_as_label "- - Nr Pneumatici - -" "1" "2" "3" "4"]
    </div>
    
    <div class="form-group" style="display: none;">
        <input type="hidden" name="fasciaprezzo" value="CLASSE T4 USATE">
    </div>
    
    <div class="form-group">
        <label for="negozio">* Seleziona un centro</label>
        [select* menu-616 id:negozio first_as_label "- - Seleziona un centro - -" "BG1-BARGELLINO (Bologna)" "BG2-BORGO PANIGALE (Bologna)" "BG3-VILLANOVA (Castenaso)" "BG4-PONTE RIZZOLI (Ozzano Emilia)" "BG5-CASTEL GUELFO (Bologna)" "BG6-CASTEL SAN PIETRO (Bologna)" "BG7-FUNO DI ARGELATO (Bologna)"]
    </div>
    
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
            [text* targa id:targa class:targa-input placeholder "Targa veicolo"]
        </div>
    </div>
    <div class="form-group inline-fields">
        <div>
            <label for="marca-veicolo">* Marca veicolo</label>
            [text* marcaveicolo id:marca-veicolo class:marca-veicolo-input placeholder "Marca veicolo"]
        </div>
        <div>
            <label for="modello-veicolo">* Modello veicolo</label>
            [text* modelloveicolo id:modello-veicolo class:modello-veicolo-input placeholder "Modello veicolo"]
        </div>
    </div>
    <div class="form-group" style="display: none;">
        <div>
            <label for="cap">CAP</label>
            [text cap id:cap class:cap-input placeholder "CAP"]
        </div>
    </div>
    <div class="form-group" style="display: none;">
        <input type="hidden" name="selected_tipo_preventivo" value="PREVENTIVO PNEUMATICI">
    </div>
    
    <div class="form-group">
        <label for="richiesta">Testo aggiuntivo (non scrivere qui la misura ma usa gli appositi campi)</label>
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