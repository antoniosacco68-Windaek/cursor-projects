function estraiDatiPreventivi() {
  try {
    //var foglio = SpreadsheetApp.openById('12Vdtjne3zJIME6uM0iYaNTgrK_mtRj2rGAvCv9tqrgA');
   // var sheet = foglio.getActiveSheet();
    //Logger.log('Foglio aperto con successo');

    // Ottieni le etichette da Gmail
    var etichettaLavorate = GmailApp.getUserLabelByName('Lavorata');
    if (!etichettaLavorate) {
      Logger.log('Creazione etichetta Lavorata');
      etichettaLavorate = GmailApp.createLabel('Lavorata');
    }

    var ricerca = 'from:sql@bolognagomme.com label:Preventivi_Web_Automatici -label:lavorata after:2025/01/09';
    Logger.log('Eseguo ricerca: ' + ricerca);

    var threads = GmailApp.search(ricerca);
    Logger.log('Trovati ' + threads.length + ' thread');

    if (threads.length === 0) {
      Logger.log('Nessuna nuova email da processare');
      return;
    }
    
    // Intestazioni CSV
    var intestazioni = [
        'DataRichiesta',
        'Nome',
        'Cognome',
        'Email',
        'Telefono',
        'CAP',
        'Negozio',
        'TargaVeicolo',
        'Marca',
        'Modello',
        'TipoPreventivo',
        'Larghezza',
        'Spalla',
        'Diametro',
        'CodCar',
        'CodVel',
        'Stagionalita',
        'NumeroPneumatici',
        'FasciaDiPrezzo',
        'Km',
        'TipoManutenzione',
        'LarghezzaMotoAnt',
        'SpallaMotoAnt',
        'DiametroMotoAnt',
        'CodCarMotoAnt',
        'CodVelMotoAnt',
        'LarghezzaMotoPost',
        'SpallaMotoPost',
        'DiametroMotoPost',
        'CodCarMotoPost',
        'CodVelMotoPost',
        'CorpoMessaggio'
      ];
    
    threads.forEach(function(thread, threadIndex) {
      if (!thread) {
        Logger.log('Thread #' + threadIndex + ' non valido');
        return;
      }

      var messages = thread.getMessages();
      
      messages.forEach(function(email) {
        try {
          Logger.log('------- INIZIO ELABORAZIONE EMAIL -------');
          Logger.log('Data email: ' + email.getDate());
          
          if (!email || !email.getPlainBody) {
            Logger.log('Email non valida, salto alla successiva');
            return;
          }
          
          var contenuto = email.getPlainBody();
          if (!contenuto) {
            Logger.log('Contenuto email vuoto, salto alla successiva');
            return;
          }
          
          if (!isEmailOriginale(email, contenuto)) {
            Logger.log('Email saltata perché non è l\'originale');
            return;
          }
          
          Logger.log('Email originale trovata, estraggo i dati...');

          var emailDate = email.getDate();
          var formattedDate = Utilities.formatDate(emailDate, Session.getTimeZone(), 'dd/MM/yyyy HH:mm');
          
           var datiCliente = {
            data: formattedDate,// Data formattata
            nome: estraiCampoSicuro(contenuto, 'Nome: ', '\n').replace(/<.*>/, '').trim(),
            cognome: estraiCampoSicuro(contenuto, 'Cognome: ', '\n').replace(/<.*>/, '').trim(),
            email: estraiCampoSicuro(contenuto, '<', '>'),
            telefono: estraiCampoSicuro(contenuto, 'Telefono: ', '\n'),
            cap: estraiCampoSicuro(contenuto, 'CAP: ', '\n'),
            negozio: estraiCampoSicuro(contenuto, 'Negozio selezionato: ', '\n'),
            targa: estraiCampoSicuro(contenuto, 'Targa: ', '\n'),
            marca: estraiCampoSicuro(contenuto, 'Marca: ', '\n'),
            modello: estraiCampoSicuro(contenuto, 'Modello: ', '\n'),
            tipopreventivo: estraiCampoSicuro(contenuto, 'Tipo Preventivo: ', '\n'),
            larghezza: estraiCampoSicuro(contenuto, 'Larghezza: ', '\n'),
            spalla: estraiCampoSicuro(contenuto, 'Spalla: ', '\n'),
            diametro: estraiCampoSicuro(contenuto, 'Diametro: ', '\n'),
            codcar: estraiCampoSicuro(contenuto, 'Carico: ', '\n'),
            codvel: estraiCampoSicuro(contenuto, 'Velocità: ', '\n'),
            stagionalita: estraiCampoSicuro(contenuto, 'Stagionalità: ', '\n'),
            NumeroPneumatici: estraiCampoSicuro(contenuto, 'Numero Pneumatici: ', '\n'),
            fasciadiprezzo: estraiCampoSicuro(contenuto, 'Fascia di Prezzo: ', '\n'),
            km: estraiCampoSicuro(contenuto, 'Km: ', '\n'),
            tipomanutenzione: estraiCampoSicuro(contenuto, 'Tipo Manutenzione: ', '\n'),
            larghezzamotoant: estraiCampoSicuro(contenuto, 'LarghezzaMotoAnt: ', '\n'),
            spallamotoant: estraiCampoSicuro(contenuto, 'SpallaMotoAnt: ', '\n'),
            diametromotoant: estraiCampoSicuro(contenuto, 'DiametroMotoAnt: ', '\n'),
            caricomotoant: estraiCampoSicuro(contenuto, 'CaricoMotoAnt: ', '\n'),
            velocitamotoant: estraiCampoSicuro(contenuto, 'VelocitàMotoAnt: ', '\n'),
            larghezzamotopost: estraiCampoSicuro(contenuto, 'LarghezzaMotoPost: ', '\n'),
            spallamotopost: estraiCampoSicuro(contenuto, 'SpallaMotoPost: ', '\n'),
            diametromotopost: estraiCampoSicuro(contenuto, 'DiametroMotoPost: ', '\n'),
            caricomotopost: estraiCampoSicuro(contenuto, 'CaricoMotoPost: ', '\n'),
            velocitamotopost: estraiCampoSicuro(contenuto, 'VelocitàMotoPost: ', '\n'),
            corpoMessaggio: estraiCampoSicuro(contenuto, 'Messaggio aggiuntivo:','--').trim()
          };

          // Gestione marca e modello
          //var marcaModello = estraiCampoSicuro(contenuto, 'Marca e modello: ', '\n');
          //if (marcaModello) {
            //var parti = marcaModello.split(' ');
            //if (parti.length > 1) {
              //datiCliente.marca = parti[0];
              //datiCliente.modello = parti.slice(1).join(' ');
            //} else {
              //datiCliente.marca = marcaModello;
            //}
          //}
        
           Logger.log('Dati estratti:');
           Logger.log('data: ' + datiCliente.data);
           Logger.log('nome: ' + datiCliente.nome);
           Logger.log('cognome: ' + datiCliente.cognome);
           Logger.log('email: ' + datiCliente.email);
           Logger.log('telefono: ' + datiCliente.telefono);
           Logger.log('cap: ' + datiCliente.cap);
           Logger.log('negozio: ' + datiCliente.negozio);
           Logger.log('targa: ' + datiCliente.targa);
           Logger.log('marca: ' + datiCliente.marca);
           Logger.log('modello: ' + datiCliente.modello);
           Logger.log('tipopreventivo: ' + datiCliente.tipopreventivo);
           Logger.log('larghezza: ' + datiCliente.larghezza);
           Logger.log('spalla: ' + datiCliente.spalla);
           Logger.log('diametro: ' + datiCliente.diametro);
           Logger.log('codcar: ' + datiCliente.codcar);
           Logger.log('codvel: ' + datiCliente.codvel);
           Logger.log('stagionalita: ' + datiCliente.stagionalita);
           Logger.log('numeropneumatici: ' + datiCliente.NumeroPneumatici);
           Logger.log('fasciadiprezzo: ' + datiCliente.fasciadiprezzo);
           Logger.log('km: ' + datiCliente.km);
           Logger.log('tipomanutenzione: ' + datiCliente.tipomanutenzione);
           Logger.log('larghezzamotoant: ' + datiCliente.larghezzamotoant);
           Logger.log('spallamotoant: ' + datiCliente.spallamotoant);
           Logger.log('diametromotoant: ' + datiCliente.diametromotoant);
           Logger.log('caricomotoant: ' + datiCliente.caricomotoant);
           Logger.log('velocitamotoant: ' + datiCliente.velocitamotoant);
           Logger.log('larghezzamotopost: ' + datiCliente.larghezzamotopost);
           Logger.log('spallamotopost: ' + datiCliente.spallamotopost);
           Logger.log('diametromotopost: ' + datiCliente.diametromotopost);
           Logger.log('caricomotopost: ' + datiCliente.caricomotopost);
           Logger.log('velocitamotopost: ' + datiCliente.velocitamotopost);
           Logger.log('corpoMessaggio: ' + datiCliente.corpoMessaggio);

           
          // Crea il CSV
          var csvData = [intestazioni];
          var valori = [
             datiCliente.data,
            datiCliente.nome,
            datiCliente.cognome,
            datiCliente.email,
            datiCliente.telefono,
            datiCliente.cap,
            datiCliente.negozio,
            datiCliente.targa,
            datiCliente.marca,
            datiCliente.modello,
            datiCliente.tipopreventivo,
            datiCliente.larghezza,
            datiCliente.spalla,
            datiCliente.diametro,
            datiCliente.codcar,
            datiCliente.codvel,
            datiCliente.stagionalita,
            datiCliente.NumeroPneumatici,
            datiCliente.fasciadiprezzo,
            datiCliente.km,
            datiCliente.tipomanutenzione,
            datiCliente.larghezzamotoant,
            datiCliente.spallamotoant,
            datiCliente.diametromotoant,
            datiCliente.caricomotoant,
            datiCliente.velocitamotoant,
            datiCliente.larghezzamotopost,
            datiCliente.spallamotopost,
            datiCliente.diametromotopost,
            datiCliente.caricomotopost,
            datiCliente.velocitamotopost,
            datiCliente.corpoMessaggio
          ];

          csvData.push(valori);

           // Crea il nome file
           var dataString = Utilities.formatDate(new Date(), Session.getTimeZone(), 'yyyyMMdd_HHmmss');
           var fileName = 'preventivo_' + dataString + '_' + datiCliente.nome.replace(/\s/g, '_') + '.json';
           var jsonContent = convertToJSON(csvData);
           
          // Salva il file nel Drive
           var folder = DriveApp.getFolderById('1UuNGIrlbk6ibnWJhORqoNV4uHDZNGnFn'); // Sostituisci con l'ID della tua cartella
           var file = folder.createFile(fileName, jsonContent, MimeType.PLAIN_TEXT);
           var blob = file.getBlob().setContentType('application/json');
           var fileFinal = folder.createFile(blob.setName(fileName));
           file.setTrashed(true);
           Logger.log('JSON creato e salvato con nome: ' + fileName);
          
          // Aggiungi l'etichetta
          thread.addLabel(etichettaLavorate);
          // Marca il thread come letto
          thread.markRead();
          Logger.log('Etichetta Lavorata aggiunta e mail marcata come letta');

        } catch (error) {
          Logger.log('Errore nell\'elaborazione dell\'email: ' + error.toString());
        }
      });
    });

    Logger.log('Elaborazione completata.');
    
  } catch (error) {
    Logger.log('Errore generale: ' + error.toString() + '\n' + error.stack);
  }
}

 function convertToJSON(data) {
  var intestazioni = data[0];
  var valori = data[1];
  var jsonObject = {};

  for (var i = 0; i < intestazioni.length; i++) {
    jsonObject[intestazioni[i]] = valori[i] == null ? null : String(valori[i]);
  }

  return JSON.stringify(jsonObject);
}
  
  function isEmailOriginale(email, contenuto) {
    try {
      Logger.log('Controllo mittente...');
      if (email.getFrom().toLowerCase().indexOf('sql@bolognagomme.com') === -1) {
        Logger.log('Email scartata: mittente non corretto - ' + email.getFrom());
        return false;
      }
      Logger.log('Mittente OK');
      
      Logger.log('Controllo oggetto...');
      var oggetto = email.getSubject();
      if (oggetto.toLowerCase().indexOf('fwd:') === 0) {
        Logger.log('Email scartata: è un inoltro (fwd:) - ' + oggetto);
        return false;
      }
      Logger.log('Oggetto OK');
      
      Logger.log('Controllo Content-Type...');
      var headers = email.getHeader('Content-Type');
      if (headers && headers.indexOf('multipart/alternative') !== -1) {
        Logger.log('Email scartata: è un inoltro (multipart/alternative)');
        return false;
      }
      Logger.log('Content-Type OK');
      
      Logger.log('Controllo contenuto...');
      if (contenuto.indexOf('Content-Type: multipart/alternative;') !== -1) {
        Logger.log('Email scartata: contiene header multipart');
        return false;
      }
      Logger.log('Contenuto OK');

      return true;
    } catch (error) {
      Logger.log('Errore in isEmailOriginale: ' + error);
      return false;
    }
  }
  
  // Funzione di supporto migliorata per gestire null/undefined
  function estraiCampoSicuro(testo, inizioCon, finiscoCon) {
    if (!testo || !inizioCon || !finiscoCon) return '';
    
    try {
      var inizio = testo.indexOf(inizioCon);
      if (inizio === -1) return '';
      
      inizio += inizioCon.length;
      var fine = testo.indexOf(finiscoCon, inizio);
      if (fine === -1) fine = testo.length;
      
      var estratto = testo.substring(inizio, fine).trim();
           estratto = estratto.replace(/\s+/g, ' ');
            return estratto.trim();
    } catch (error) {
      Logger.log('Errore in estraiCampoSicuro: ' + error);
      return '';
    }
  }