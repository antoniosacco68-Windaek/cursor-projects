

Sto lavorando sui tuoi dati: ho letto `Risultati.csv`, lo script `Pneumatico SalesForce.sql` e gli schemi/estratti di `Deposito` e `SchedaLavoro`. L’anagrafica che generi è coerente con le chiavi `External_Id__c` che hai colorato nel foglio e permette di ricostruire bene la storia.

### Come imposterei gli “Eventi Pneumatico” (proposta)
- **Event types** (campo `TipoEvento`):
  - `MONTAGGIO_NUOVE`: da `SchedaLavoro` + `ArtSchedaLavoro` per righe di montaggio (fasce A/B/C/U/R, non `%MS_STAG%`). Chiave = `External_Id__c` dell’anagrafica.
  - `RIMONTAGGIO_DA_DEPOSITO`: da `SchedaLavoro` con codici tipo `@MS_STAG%`, legato al relativo `IdDeposito` della stessa scheda (join su `Deposito.D_IdSchedaLavoro = SchedaLavoro.IdSchedaLavoro`). Mappo al corretto `External_Id__c` cercando in anagrafica l’ultima voce del veicolo con stesso articolo (match su `CodiceArticolo` o `LEFT(CodiceArticolo,7)`), usando `D_DotAnt/D_DotPost` quando presenti.
  - `DEPOSITO`: da `Deposito` quando `D_TipoDepositoR1/R2` contiene “DEPOSITO”. Per ogni lato (ant/post) emetto 1 evento e lo lego all’`External_Id__c` del set uscente determinato come sopra.
  - `SMALTIMENTO`: da `Deposito` quando `D_TipoDepositoR1/R2` contiene “SMALTITE”.
  - `PORTA_VIA`: da `Deposito` quando `D_TipoDepositoR1/R2` contiene “Porta Via”.
- **Chiavi di join e disambiguazione**
  - Sempre a livello di veicolo (`IdVeicolo`) e famiglia articolo: `CodiceArticolo` esatto o `LEFT(CodiceArticolo,7)` per gestire varianti (es. 2854022-...).
  - Usare `DOT` dal montaggio (`asl.Art_DOT`) o, se assente, il DOT calcolato (stessa logica dell’anagrafica). Per il deposito usare `D_DotAnt/D_DotPost` quando non null.
- **Campi evento principali**
  - `External_Id__c`, `IdVeicolo`, `CodiceArticolo`, `DOT`, `IdSchedaLavoro` o `IdDeposito`, `DataEvento` (da `sl.Data_Lavori` o `d.Data`/`D_ModificatoData`), `TipoEvento`, `Quantita`.
- **Output**
  - Una vista/CTE che concatena i 4 insiemi di eventi e li ordina per `DataEvento`, così puoi vedere la timeline per ciascun `External_Id__c` e confermare gli esiti in `Risultati.csv` (le righe 1–9 e l’anagrafica sotto combaciano con questa logica: i set 3622 del 2023 finiscono in deposito, vengono rimontati a 05/2024 e poi smaltiti a 11/2024; i nuovi 0825 del 06/2025 risultano “Montata” e i set precedenti tornano “Depositata”).

### Punti da chiarire (brevi)
1. Confermi che le righe “stagionali” in `SchedaLavoro` si identificano con `Art_Codice LIKE '%MS_STAG%'` e indicano rimontaggio da deposito?

	Risposta:
		si ti confermo che i cambi stagionali si identificano con `Art_Codice LIKE '%MS_STAG%'` e indicano rimontaggio da deposito e riga di TBL Deposito per quello che smontiamo.

2. Per la data dell’evento di deposito/smaltimento uso `Deposito.Data`; se disponibile `D_ModificatoData` preferisci quella?

	Risposta:
		no sempre `Deposito.Data`

3. Il match su famiglia articolo (`LEFT(CodiceArticolo,7)`) va sempre bene quando i codici differiscono (es. 3992900 vs 3109700), e si può usare `DOT` per disambiguare?

	Risposta:
		Allora non ho capito bene ma il Codice Articolo è un UNIVOCO del nostro sistema (Ant_Descrittori_WebSmall.csv) e quindi non devi fare nessun LEFT lo puoi usare intero e lo rendiamo
		univoco qundo creiamo le Anagrafica Pneumatico con il DOT di Art_SchedaLavoro se c'è altrimenti con le regole della Data - 90 giorni, idem per il Deposito se non abbiamo mai mappato la gomma
		montandola nuova e li prendiamo il DOT di Deposito se esiste altrimenti sempre la regola Deposito.Data - 90 giorni per generarlo.
		Se non sono stato chiaro o ti serve altro non inventrti nulla ma domandi ancora in merito a questo.

4. Vuoi che crei un file `Eventi_Pneumatico.sql` con la query completa e un output di controllo per confrontare automaticamente con `Risultati.csv`?

	Risposta:
		Come ritieni più opportun, se puoi credo che possa essere comodo per un confronto comunque come pensi sia meglio ...

Se mi dai l’ok su questi 4 punti, te lo implemento subito.

- Ho letto `Risultati.csv`, `Pneumatico SalesForce.sql`, e gli schemi/estratti di `Deposito` e `SchedaLavoro`, verificando coerenza delle chiavi `External_Id__c`.
- Ti ho proposto i tipi evento, le regole di matching e i campi chiave per generare la timeline partendo dall’anagrafica “perfetta”.
- Ho chiesto 4 conferme mirate; con l’ok procedo a scrivere lo script `Eventi_Pneumatico.sql`.