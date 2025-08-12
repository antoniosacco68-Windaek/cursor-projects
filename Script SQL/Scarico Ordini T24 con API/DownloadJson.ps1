param (
    [string]$orderId  # Questo sarà passato dallo script T-SQL
)

# Parametri dell'API
$url = "https://api-b2b.alzura.com/common/order/$orderId"
$apiKey = "OGQ1NzljYmZjYzRjYmI4MTg4MTMyMjY3MTVjZjUwNzYxNThlODU4NTg4NTYzOWU4MTYxYmE5YmJkYWM3MWU1NjBjODEyYWEwMTg3YWE1MDQwNjRlNWE5M2U1MzFkZTI4YmM5OGRhYWY3YjJlNDA="

# Headers della richiesta HTTP
$headers = @{
    'Country' = 'it'
    'X-AUTH-TOKEN' = $apiKey
    'Accept' = 'application/vnd.saitowag.api+json;version=1.0'
    'Content-Type' = 'application/json'
}

# Esegui la richiesta HTTP GET con Invoke-WebRequest usando l'opzione UseBasicParsing
$response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -UseBasicParsing

# Estrai il contenuto della risposta come stringa
$json = $response.Content

# Escapa gli apici singoli nel JSON per evitare errori SQL
$jsonEscaped = $json -replace "'", "''"

# Stampa il JSON per il debug
# Write-Output $json

# Connessione al database SQL Server
$serverName = "Impresa24"  # Sostituisci con il nome del tuo server SQL
$databaseName = "Tyre24"
$connectionString = "Server=$serverName;Database=$databaseName;Integrated Security=True;"

# Query SQL per inserire il JSON nella tabella, usando il JSON escapato
$query = "INSERT INTO Tjson (Json_Table) VALUES ('$jsonEscaped');"

# Esegui il comando SQL
Invoke-Sqlcmd -ConnectionString $connectionString -Query $query
