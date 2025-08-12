# Script PowerShell per generare interfaccia web con dati dal database
# Uso: .\GeneraWebInterface.ps1

param(
    [string]$ServerName = ".",
    [string]$DatabaseName = "OfferteWeb",
    [string]$CsvPath = "C:\Antonio\RegoleB2bPerSoldi\FileDiImportazioneCSV\RegoleListiniDistribuzione.csv",
    [string]$OutputFile = "RegoleDistribuzione_Live.html"
)

Write-Host "🔄 Generazione interfaccia web per Regole Distribuzione..." -ForegroundColor Cyan

# Funzione per leggere dal database SQL Server
function Get-RegoleFromDatabase {
    param($Server, $Database)
    
    try {
        Write-Host "📊 Connessione al database $Database su server $Server..." -ForegroundColor Yellow
        
        $connectionString = "Server=$Server;Database=$Database;Integrated Security=true;TrustServerCertificate=true;"
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        $query = @"
            SELECT ID, NomeListino, CifraIn, CifraOut, Margine, MargPiu, MargMeno, 
                   Settore, RicaricoPercentuale, ProvvPiatt, MargMenoEstivo, 
                   MargMenoAS, MargMenoInvernale, DataCreazione, DataModifica
            FROM RegoleListiniDistribuzione 
            ORDER BY NomeListino, Settore, CifraIn
"@
        
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        $adapter = New-Object System.Data.SqlClient.SqlDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset)
        
        $connection.Close()
        
        Write-Host "✅ Caricate $($dataset.Tables[0].Rows.Count) regole dal database" -ForegroundColor Green
        return $dataset.Tables[0]
        
    } catch {
        Write-Host "❌ Errore connessione database: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Funzione per leggere dal CSV
function Get-RegoleFromCSV {
    param($FilePath)
    
    try {
        if (-not (Test-Path $FilePath)) {
            Write-Host "⚠️ File CSV non trovato: $FilePath" -ForegroundColor Yellow
            return $null
        }
        
        Write-Host "📄 Lettura file CSV: $FilePath..." -ForegroundColor Yellow
        
        $csvData = Import-Csv -Path $FilePath -Delimiter ';' -Encoding UTF8
        
        Write-Host "✅ Caricate $($csvData.Count) regole dal CSV" -ForegroundColor Green
        return $csvData
        
    } catch {
        Write-Host "❌ Errore lettura CSV: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Funzione per convertire in JSON
function ConvertTo-JsonData {
    param($Data, $Source)
    
    $jsonData = @()
    
    foreach ($row in $Data) {
        $jsonRow = @{
            ID = if ($Source -eq "Database") { $row.ID } else { $row.ID }
            NomeListino = $row.NomeListino
            CifraIn = if ($row.CifraIn -eq "null" -or [string]::IsNullOrEmpty($row.CifraIn)) { $null } else { [decimal]$row.CifraIn }
            CifraOut = if ($row.CifraOut -eq "null" -or [string]::IsNullOrEmpty($row.CifraOut)) { $null } else { [decimal]$row.CifraOut }
            Margine = if ($row.Margine -eq "null" -or [string]::IsNullOrEmpty($row.Margine)) { $null } else { [decimal]$row.Margine }
            MargPiu = if ($row.MargPiu -eq "null" -or [string]::IsNullOrEmpty($row.MargPiu)) { $null } else { [decimal]$row.MargPiu }
            MargMeno = if ($row.MargMeno -eq "null" -or [string]::IsNullOrEmpty($row.MargMeno)) { $null } else { [decimal]$row.MargMeno }
            Settore = $row.Settore
            RicaricoPercentuale = if ($row.RicaricoPercentuale -eq "null" -or [string]::IsNullOrEmpty($row.RicaricoPercentuale)) { $null } else { [decimal]$row.RicaricoPercentuale }
            ProvvPiatt = if ($row.ProvvPiatt -eq "null" -or [string]::IsNullOrEmpty($row.ProvvPiatt)) { $null } else { [decimal]$row.ProvvPiatt }
            MargMenoEstivo = if ($row.MargMenoEstivo -eq "null" -or [string]::IsNullOrEmpty($row.MargMenoEstivo)) { $null } else { [decimal]$row.MargMenoEstivo }
            MargMenoAS = if ($row.MargMenoAS -eq "null" -or [string]::IsNullOrEmpty($row.MargMenoAS)) { $null } else { [decimal]$row.MargMenoAS }
            MargMenoInvernale = if ($row.MargMenoInvernale -eq "null" -or [string]::IsNullOrEmpty($row.MargMenoInvernale)) { $null } else { [decimal]$row.MargMenoInvernale }
            DataCreazione = if ($Source -eq "Database") { $row.DataCreazione } else { $row.DataCreazione }
            DataModifica = if ($Source -eq "Database") { $row.DataModifica } else { $row.DataModifica }
        }
        $jsonData += $jsonRow
    }
    
    return $jsonData | ConvertTo-Json -Depth 3 -Compress
}

# Prova prima il database, poi il CSV
$regoleData = Get-RegoleFromDatabase -Server $ServerName -Database $DatabaseName
$dataSource = "Database SQL Server"

if ($regoleData -eq $null -or $regoleData.Rows.Count -eq 0) {
    Write-Host "🔄 Tentativo lettura da CSV..." -ForegroundColor Yellow
    $regoleData = Get-RegoleFromCSV -FilePath $CsvPath
    $dataSource = "File CSV"
}

if ($regoleData -eq $null) {
    Write-Host "❌ Impossibile caricare dati né da database né da CSV!" -ForegroundColor Red
    exit 1
}

# Converti in JSON
$jsonDataString = if ($dataSource -eq "Database SQL Server") {
    ConvertTo-JsonData -Data $regoleData.Rows -Source "Database"
} else {
    ConvertTo-JsonData -Data $regoleData -Source "CSV"
}

# Template HTML con dati incorporati
$htmlTemplate = @"
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestione Regole Distribuzione - Live Data</title>
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css" rel="stylesheet">
    <style>
        /* CSS identico alla versione precedente */
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }
        .container { max-width: 1600px; margin: 0 auto; background: white; border-radius: 15px; box-shadow: 0 20px 40px rgba(0,0,0,0.1); overflow: hidden; }
        .header { background: linear-gradient(45deg, #2c3e50, #34495e); color: white; padding: 25px; text-align: center; }
        .header h1 { font-size: 2.5rem; margin-bottom: 10px; }
        .data-source { background: #27ae60; color: white; padding: 10px 20px; border-radius: 20px; display: inline-flex; align-items: center; gap: 10px; margin-top: 10px; }
        .toolbar { background: #f8f9fa; padding: 20px; border-bottom: 1px solid #dee2e6; display: flex; gap: 15px; flex-wrap: wrap; align-items: center; }
        .btn { padding: 10px 20px; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; display: flex; align-items: center; gap: 8px; transition: all 0.3s ease; }
        .btn-primary { background: #007bff; color: white; }
        .btn-success { background: #28a745; color: white; }
        .btn-warning { background: #ffc107; color: #212529; }
        .btn-danger { background: #dc3545; color: white; }
        .btn:hover:not(:disabled) { transform: translateY(-2px); box-shadow: 0 5px 15px rgba(0,0,0,0.2); }
        .btn:disabled { opacity: 0.6; cursor: not-allowed; }
        .filters { background: #e9ecef; padding: 15px; display: flex; gap: 15px; flex-wrap: wrap; align-items: center; }
        .filter-group { display: flex; flex-direction: column; gap: 5px; }
        .filter-group label { font-weight: 600; color: #495057; font-size: 0.9rem; }
        .filter-input { padding: 8px 12px; border: 1px solid #ced4da; border-radius: 6px; font-size: 0.9rem; }
        .table-container { overflow-x: auto; max-height: 60vh; }
        .data-table { width: 100%; border-collapse: collapse; font-size: 0.9rem; }
        .data-table th { background: #343a40; color: white; padding: 12px 8px; text-align: left; position: sticky; top: 0; z-index: 10; }
        .data-table td { padding: 10px 8px; border-bottom: 1px solid #dee2e6; border-right: 1px solid #dee2e6; }
        .data-table tbody tr:hover { background-color: #f8f9fa; }
        .data-table tbody tr.selected { background-color: #d1ecf1; }
        .listino-badge { padding: 4px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 600; }
        .listino-piattaforme { background: #d4edda; color: #155724; }
        .listino-b2b { background: #d1ecf1; color: #0c5460; }
        .listino-collegati { background: #f8d7da; color: #721c24; }
        .status-bar { background: #f8f9fa; padding: 15px; border-top: 1px solid #dee2e6; display: flex; justify-content: space-between; align-items: center; font-size: 0.9rem; color: #6c757d; }
        .notification { position: fixed; top: 20px; right: 20px; padding: 15px 20px; border-radius: 8px; color: white; font-weight: 600; z-index: 1000; transform: translateX(400px); transition: transform 0.3s ease; }
        .notification.show { transform: translateX(0); }
        .notification.success { background: #28a745; }
        .notification.error { background: #dc3545; }
        .notification.warning { background: #ffc107; color: #212529; }
        .refresh-note { background: #fff3cd; color: #856404; padding: 10px 15px; margin: 10px 0; border-radius: 8px; border-left: 4px solid #ffc107; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-table"></i> Gestione Regole Distribuzione</h1>
            <p>Dati caricati da: $dataSource</p>
            <div class="data-source">
                <i class="fas fa-database"></i> Snapshot generato il: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
            </div>
        </div>

        <div class="refresh-note">
            <strong><i class="fas fa-info-circle"></i> Nota:</strong> 
            Per aggiornare i dati, rigenera questo file eseguendo: <code>.\GeneraWebInterface.ps1</code>
        </div>

        <div class="toolbar">
            <button class="btn btn-success" onclick="showAddForm()">
                <i class="fas fa-plus"></i> Nuova Regola (Solo visualizzazione)
            </button>
            <button class="btn btn-primary" onclick="regenerateInterface()">
                <i class="fas fa-sync-alt"></i> Rigenera Interfaccia
            </button>
            <button class="btn btn-warning" onclick="exportToCSV()">
                <i class="fas fa-file-csv"></i> Esporta CSV
            </button>
            <button class="btn btn-danger" onclick="deleteSelected()" disabled id="btnDelete">
                <i class="fas fa-trash"></i> Elimina (Solo visualizzazione)
            </button>
        </div>

        <div class="filters">
            <div class="filter-group">
                <label>Listino:</label>
                <select id="filterListino" class="filter-input" onchange="applyFilters()">
                    <option value="">Tutti</option>
                    <option value="Piattaforme">Piattaforme</option>
                    <option value="B2B">B2B</option>
                    <option value="Collegati">Collegati</option>
                </select>
            </div>
            <div class="filter-group">
                <label>Settore:</label>
                <select id="filterSettore" class="filter-input" onchange="applyFilters()">
                    <option value="">Tutti</option>
                    <option value="Vettura">Vettura</option>
                    <option value="Autocarro">Autocarro</option>
                    <option value="MotoScooter">MotoScooter</option>
                </select>
            </div>
            <div class="filter-group">
                <label>Prezzo Da:</label>
                <input type="number" id="filterPrezzoMin" class="filter-input" onchange="applyFilters()" placeholder="€">
            </div>
            <div class="filter-group">
                <label>Prezzo A:</label>
                <input type="number" id="filterPrezzoMax" class="filter-input" onchange="applyFilters()" placeholder="€">
            </div>
            <div class="filter-group">
                <label>Cerca:</label>
                <input type="text" id="filterSearch" class="filter-input" onchange="applyFilters()" placeholder="Cerca...">
            </div>
            <button class="btn btn-primary" onclick="clearFilters()">
                <i class="fas fa-times"></i> Pulisci Filtri
            </button>
        </div>

        <div class="table-container">
            <table class="data-table" id="dataTable">
                <thead>
                    <tr>
                        <th><input type="checkbox" id="selectAll" onchange="toggleSelectAll()"></th>
                        <th>ID</th>
                        <th>Listino</th>
                        <th>Cifra In (€)</th>
                        <th>Cifra Out (€)</th>
                        <th>Margine (€)</th>
                        <th>Marg+</th>
                        <th>Marg-</th>
                        <th>Settore</th>
                        <th>Ricarico %</th>
                        <th>Provv. Piatt.</th>
                        <th>Marg- Estivo</th>
                        <th>Marg- AS</th>
                        <th>Marg- Invernale</th>
                        <th>Data Creazione</th>
                        <th>Data Modifica</th>
                    </tr>
                </thead>
                <tbody id="tableBody">
                </tbody>
            </table>
        </div>

        <div class="status-bar">
            <div>
                <span id="recordCount">Caricamento...</span> | 
                <span id="selectedCount">0 selezionate</span>
            </div>
            <div>
                Fonte: $dataSource | Generato: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
            </div>
        </div>
    </div>

    <div id="notification" class="notification"></div>

    <script>
        // Dati incorporati dal PowerShell
        const csvData = $jsonDataString;
        let filteredData = [...csvData];
        let selectedRows = new Set();

        // Inizializzazione
        document.addEventListener('DOMContentLoaded', function() {
            renderTable();
            updateStatusBar();
            showNotification('Interfaccia caricata con dati da: $dataSource', 'success');
        });

        // Rendering tabella
        function renderTable() {
            const tbody = document.getElementById('tableBody');
            tbody.innerHTML = '';

            if (filteredData.length === 0) {
                tbody.innerHTML = '<tr><td colspan="16" style="text-align: center; padding: 40px; color: #6c757d;">Nessun risultato trovato</td></tr>';
                return;
            }

            filteredData.forEach(row => {
                const tr = document.createElement('tr');
                tr.dataset.id = row.ID;
                
                if (selectedRows.has(row.ID)) {
                    tr.classList.add('selected');
                }

                tr.innerHTML = `
                    <td><input type="checkbox" onchange="toggleRowSelection({row.ID})" {selectedRows.has(row.ID) ? 'checked' : ''}></td>
                    <td>{row.ID || 'N/A'}</td>
                    <td><span class="listino-badge listino-{(row.NomeListino || '').toLowerCase()}">{row.NomeListino || ''}</span></td>
                    <td>{formatNumber(row.CifraIn)}</td>
                    <td>{formatNumber(row.CifraOut)}</td>
                    <td>{formatNumber(row.Margine)}</td>
                    <td>{formatNumber(row.MargPiu)}</td>
                    <td>{formatNumber(row.MargMeno)}</td>
                    <td>{row.Settore || ''}</td>
                    <td>{formatNumber(row.RicaricoPercentuale)}</td>
                    <td>{formatNumber(row.ProvvPiatt)}</td>
                    <td>{formatNumber(row.MargMenoEstivo)}</td>
                    <td>{formatNumber(row.MargMenoAS)}</td>
                    <td>{formatNumber(row.MargMenoInvernale)}</td>
                    <td>{formatDate(row.DataCreazione)}</td>
                    <td>{formatDate(row.DataModifica)}</td>
                `;

                tbody.appendChild(tr);
            });
        }

        // Applica filtri
        function applyFilters() {
            const filterListino = document.getElementById('filterListino').value;
            const filterSettore = document.getElementById('filterSettore').value;
            const filterPrezzoMin = parseFloat(document.getElementById('filterPrezzoMin').value) || 0;
            const filterPrezzoMax = parseFloat(document.getElementById('filterPrezzoMax').value) || Infinity;
            const filterSearch = document.getElementById('filterSearch').value.toLowerCase();

            filteredData = csvData.filter(row => {
                return (!filterListino || row.NomeListino === filterListino) &&
                       (!filterSettore || row.Settore === filterSettore) &&
                       ((row.CifraIn || 0) >= filterPrezzoMin) &&
                       ((row.CifraOut || 0) <= filterPrezzoMax) &&
                       (!filterSearch || JSON.stringify(row).toLowerCase().includes(filterSearch));
            });

            renderTable();
            updateStatusBar();
        }

        // Altre funzioni helper
        function clearFilters() {
            document.getElementById('filterListino').value = '';
            document.getElementById('filterSettore').value = '';
            document.getElementById('filterPrezzoMin').value = '';
            document.getElementById('filterPrezzoMax').value = '';
            document.getElementById('filterSearch').value = '';
            filteredData = [...csvData];
            renderTable();
            updateStatusBar();
        }

        function toggleRowSelection(id) {
            if (selectedRows.has(id)) {
                selectedRows.delete(id);
            } else {
                selectedRows.add(id);
            }
            updateStatusBar();
            document.getElementById('btnDelete').disabled = selectedRows.size === 0;
        }

        function toggleSelectAll() {
            const selectAll = document.getElementById('selectAll').checked;
            const checkboxes = document.querySelectorAll('#tableBody input[type="checkbox"]');
            
            if (selectAll) {
                filteredData.forEach(row => selectedRows.add(row.ID));
            } else {
                selectedRows.clear();
            }
            
            checkboxes.forEach(cb => cb.checked = selectAll);
            updateStatusBar();
            document.getElementById('btnDelete').disabled = selectedRows.size === 0;
        }

        function updateStatusBar() {
            document.getElementById('recordCount').textContent = `{filteredData.length} regole visualizzate ({csvData.length} totali)`;
            document.getElementById('selectedCount').textContent = `{selectedRows.size} selezionate`;
        }

        function formatNumber(value) {
            if (value === null || value === undefined) return '--';
            return Number(value).toFixed(2);
        }

        function formatDate(dateString) {
            if (!dateString) return '--';
            return new Date(dateString).toLocaleString('it-IT');
        }

        function showNotification(message, type) {
            const notification = document.getElementById('notification');
            notification.textContent = message;
            notification.className = `notification {type}`;
            notification.classList.add('show');
            setTimeout(() => notification.classList.remove('show'), 4000);
        }

        function showAddForm() {
            showNotification('Funzionalità di modifica non disponibile in modalità snapshot. Usa l\'API per modifiche in tempo reale.', 'warning');
        }

        function deleteSelected() {
            showNotification('Funzionalità di eliminazione non disponibile in modalità snapshot. Usa l\'API per modifiche in tempo reale.', 'warning');
        }

        function exportToCSV() {
            const csvContent = generateCSVContent();
            const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
            const link = document.createElement('a');
            const url = URL.createObjectURL(blob);
            link.setAttribute('href', url);
            link.setAttribute('download', 'RegoleListiniDistribuzione_Export.csv');
            link.style.visibility = 'hidden';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            showNotification('CSV esportato!', 'success');
        }

        function generateCSVContent() {
            const headers = ['ID', 'NomeListino', 'CifraIn', 'CifraOut', 'Margine', 'MargPiu', 'MargMeno', 'Settore', 'RicaricoPercentuale', 'ProvvPiatt', 'MargMenoEstivo', 'MargMenoAS', 'MargMenoInvernale', 'DataCreazione', 'DataModifica'];
            const csvRows = [headers.join(';')];
            
            csvData.forEach(row => {
                const values = headers.map(header => {
                    let value = row[header];
                    if (value === null || value === undefined) value = 'null';
                    return value;
                });
                csvRows.push(values.join(';'));
            });
            
            return csvRows.join('\n');
        }

        function regenerateInterface() {
            showNotification('Per rigenerare l\'interfaccia, esegui: .\\GeneraWebInterface.ps1', 'warning');
        }
    </script>
</body>
</html>
"@

# Sostituisci i placeholder nel template
$htmlContent = $htmlTemplate -replace '\$dataSource', $dataSource
$htmlContent = $htmlContent -replace '\{([^}]+)\}', '${$1}'

# Salva il file HTML
try {
    $htmlContent | Out-File -FilePath $OutputFile -Encoding UTF8
    Write-Host "✅ Interfaccia web generata: $OutputFile" -ForegroundColor Green
    Write-Host "🌐 Apri il file nel browser per visualizzare i dati" -ForegroundColor Cyan
    Write-Host "📊 Fonte dati: $dataSource" -ForegroundColor Yellow
    Write-Host "🔄 Per aggiornare, riesegui questo script" -ForegroundColor Yellow
} catch {
    Write-Host "❌ Errore nella generazione del file: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Opzionalmente apri il file nel browser
$openBrowser = Read-Host "Vuoi aprire l'interfaccia nel browser? (s/N)"
if ($openBrowser -eq 's' -or $openBrowser -eq 'S') {
    Start-Process $OutputFile
}

Write-Host "🎉 Operazione completata!" -ForegroundColor Green 