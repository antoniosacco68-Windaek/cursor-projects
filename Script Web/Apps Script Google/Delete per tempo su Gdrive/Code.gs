// Configurazione delle sottocartelle e dei relativi periodi di conservazione
const FOLDER_CONFIG = {
  '1fv8E04koyk-BtJ-4hEJgRusiMt3Lcvlh': { // Cartella principale
    'Sottocartella1': 7,  // Mantieni i file per 7 giorni
    'Sottocartella2': 15, // Mantieni i file per 15 giorni
    'Sottocartella3': 30, // Mantieni i file per 30 giorni
    // Aggiungi qui altre sottocartelle con i relativi giorni
  }
};

function deleteOldFiles() {
  // Ottieni la cartella principale
  const mainFolder = DriveApp.getFolderById('1fv8E04koyk-BtJ-4hEJgRusiMt3Lcvlh');
  
  // Ottieni tutte le sottocartelle
  const subFolders = mainFolder.getFolders();
  
  // Contatore totale dei file eliminati
  let totalDeletedCount = 0;
  
  // Itera su tutte le sottocartelle
  while (subFolders.hasNext()) {
    const subFolder = subFolders.next();
    const folderName = subFolder.getName();
    
    // Verifica se la sottocartella è nella configurazione
    if (FOLDER_CONFIG['1fv8E04koyk-BtJ-4hEJgRusiMt3Lcvlh'][folderName]) {
      const retentionDays = FOLDER_CONFIG['1fv8E04koyk-BtJ-4hEJgRusiMt3Lcvlh'][folderName];
      
      // Calcola la data di riferimento
      const retentionDate = new Date();
      retentionDate.setDate(retentionDate.getDate() - retentionDays);
      
      // Ottieni tutti i file nella sottocartella
      const files = subFolder.getFiles();
      let folderDeletedCount = 0;
      
      // Itera su tutti i file nella sottocartella
      while (files.hasNext()) {
        const file = files.next();
        const fileDate = file.getDateCreated();
        
        // Se il file è più vecchio del periodo di conservazione, eliminalo
        if (fileDate < retentionDate) {
          file.setTrashed(true);
          folderDeletedCount++;
        }
      }
      
      // Log del risultato per questa sottocartella
      Logger.log(`Nella cartella "${folderName}" eliminati ${folderDeletedCount} file più vecchi di ${retentionDays} giorni`);
      totalDeletedCount += folderDeletedCount;
    }
  }
  
  // Log del risultato totale
  Logger.log(`Totale file eliminati: ${totalDeletedCount}`);
}

// Funzione per creare un trigger giornaliero
function createDailyTrigger() {
  // Elimina eventuali trigger esistenti
  const triggers = ScriptApp.getProjectTriggers();
  triggers.forEach(trigger => ScriptApp.deleteTrigger(trigger));
  
  // Crea un nuovo trigger giornaliero
  ScriptApp.newTrigger('deleteOldFiles')
    .timeBased()
    .everyDays(1)
    .atHour(1) // Esegue alle 1:00 AM
    .create();
} 