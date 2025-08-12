param (
    [string]$apiKey,  # API Key da passare
    [string]$country = "it",  # Paese, default 'it'
    [int]$counter = 0,  # Counter, default 0
    [int]$no_tagging = 0,  # No tagging, default 0
    [int]$tracking_number = 0,  # Tracking number filter, default 0 (all orders)
    [string]$order_role = "SELLER",  # Order role, default "SELLER"
    [int]$demo = 0  # Demo mode, default 0 (real data)
)

# Validazione parametri obbligatori
if ([string]::IsNullOrEmpty($apiKey)) {
    Write-Error "Parametro apiKey è obbligatorio"
    exit 1
}

# URL dell'API per gli ultimi ordini
$url = "https://api-b2b.alzura.com/common/latestorders"

# Headers della richiesta HTTP
$headers = @{
    'Country' = $country
    'X-AUTH-TOKEN' = $apiKey
    'Accept' = 'application/vnd.saitowag.api+json;version=1.0'
    'Content-Type' = 'application/json'
}

try {
    # Esegui la richiesta HTTP GET con Invoke-WebRequest usando l'opzione UseBasicParsing
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -UseBasicParsing

    # Estrai il contenuto della risposta come stringa
    $json = $response.Content

    # Escapa gli apici singoli nel JSON per evitare errori SQL
    $jsonEscaped = $json -replace "'", "''"

    # Verifica che il JSON non sia vuoto
    if ([string]::IsNullOrEmpty($json)) {
        Write-Warning "Risposta API vuota"
        exit 0
    }

    # Connessione al database SQL Server
    $serverName = "Impresa24"  # Nome del server SQL
    $databaseName = "Tyre24"
    $connectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True;"

    # Query SQL per inserire il JSON nella tabella Tjson_BGD
    $query = "INSERT INTO Tjson_BGD (Json_Table, Elaborato) VALUES ('$jsonEscaped', 0);"

    # Esegui il comando SQL
    Invoke-Sqlcmd -ConnectionString $connectionString -Query $query

    Write-Output "Download e inserimento completato con successo"
}
catch {
    Write-Error "Errore durante il download o l'inserimento: $($_.Exception.Message)"
    exit 1
} 