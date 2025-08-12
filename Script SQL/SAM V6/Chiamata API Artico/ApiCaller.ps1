param(
    [string]$Action,          # "token", "api", "post", "delete", o "full"
    [string]$ServerUrl = "http://116.203.46.193:2000",
    [string]$Username = "webapi",
    [string]$Password = "webapi", 
    [string]$CompanyId = "BO",
    [string]$Endpoint = "",   # es: "/api/v1/artico?pageno=1&pagesize=10"
    [string]$Token = "",      # per chiamate API
    [string]$OutputFile = "", # file dove salvare la risposta (opzionale)
    [string]$Method = "GET",  # GET, POST, DELETE
    [string]$BodyFile = "",   # file JSON per body POST
    [string]$BodyJson = ""    # JSON diretto per body POST
)

# Funzione per ottenere il token
function Get-AuthToken {
    param($ServerUrl, $Username, $Password, $CompanyId)
    
    try {
        $tokenUrl = "$ServerUrl/api/token"
        $body = "jwtusername=$Username&jwtpassword=$Password&companyid=$CompanyId"
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method POST -Body $body -ContentType "application/x-www-form-urlencoded"
        
        return $response.token
    }
    catch {
        Write-Output "ERRORE_TOKEN: $($_.Exception.Message)"
        return $null
    }
}

# Funzione per chiamare API
function Invoke-ApiCall {
    param($ServerUrl, $Endpoint, $Token, $OutputFile, $Method, $BodyFile, $BodyJson)
    
    try {
        $apiUrl = "$ServerUrl$Endpoint"
        $headers = @{
            "Authorization" = "bearer $Token"
            "Accept" = "application/json"
        }
        
        Write-Output "Chiamando: $Method $apiUrl"
        
        # Gestione parametri request
        $requestParams = @{
            Uri = $apiUrl
            Method = $Method
            Headers = $headers
        }
        
        # Gestione body per POST
        if ($Method -eq "POST") {
            $requestParams["ContentType"] = "application/json"
            
            # Priorità: BodyJson diretto, poi BodyFile
            if ($BodyJson -ne "") {
                $requestParams["Body"] = $BodyJson
                Write-Output "Body: $BodyJson"
            }
            elseif ($BodyFile -ne "" -and (Test-Path $BodyFile)) {
                $bodyContent = Get-Content $BodyFile -Raw
                $requestParams["Body"] = $bodyContent
                Write-Output "Body da file: $BodyFile"
            }
            else {
                Write-Output "ERRORE: Body richiesto per POST ma non fornito"
                return $null
            }
        }
        
        $response = Invoke-RestMethod @requestParams
        $jsonResponse = $response | ConvertTo-Json -Depth 10 -Compress
        
        # Se specificato, salva in file
        if ($OutputFile -ne "") {
            $jsonResponse | Out-File -FilePath $OutputFile -Encoding UTF8
            Write-Output "SALVATO_IN: $OutputFile"
        }
        
        # Output informazioni
        Write-Output "SUCCESSO: Risposta ricevuta"
        Write-Output "LUNGHEZZA: $($jsonResponse.Length) caratteri"
        
        # Se c'è un campo ID, lo evidenzia
        if ($response.id) {
            Write-Output "ID_CREATO: $($response.id)"
        }
        
        # Se è una risposta con data, conta gli elementi
        if ($response.data) {
            $count = $response.data.Count
            Write-Output "ELEMENTI: $count"
        }
        
        # Per DELETE, mostra status
        if ($Method -eq "DELETE") {
            Write-Output "DELETE_COMPLETATO: $($response -ne $null)"
        }
        
        Write-Output "RESPONSE_JSON: $jsonResponse"
        
        return $response
    }
    catch {
        Write-Output "ERRORE_API: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            Write-Output "STATUS_CODE: $($_.Exception.Response.StatusCode)"
        }
        return $null
    }
}

# === MAIN LOGIC ===
switch ($Action.ToLower()) {
    "token" {
        $token = Get-AuthToken -ServerUrl $ServerUrl -Username $Username -Password $Password -CompanyId $CompanyId
        if ($token) {
            Write-Output "TOKEN_SUCCESS: $token"
        }
    }
    
    "api" {
        if ($Token -eq "") {
            Write-Output "ERRORE: Token richiesto per chiamate API"
            exit 1
        }
        
        $result = Invoke-ApiCall -ServerUrl $ServerUrl -Endpoint $Endpoint -Token $Token -OutputFile $OutputFile -Method $Method -BodyFile $BodyFile -BodyJson $BodyJson
    }
    
    "post" {
        if ($Token -eq "") {
            Write-Output "ERRORE: Token richiesto per chiamate POST"
            exit 1
        }
        
        $result = Invoke-ApiCall -ServerUrl $ServerUrl -Endpoint $Endpoint -Token $Token -OutputFile $OutputFile -Method "POST" -BodyFile $BodyFile -BodyJson $BodyJson
    }
    
    "delete" {
        if ($Token -eq "") {
            Write-Output "ERRORE: Token richiesto per chiamate DELETE"
            exit 1
        }
        
        $result = Invoke-ApiCall -ServerUrl $ServerUrl -Endpoint $Endpoint -Token $Token -OutputFile $OutputFile -Method "DELETE" -BodyFile $BodyFile -BodyJson $BodyJson
    }
    
    "full" {
        # Processo completo: ottieni token + chiama API
        Write-Output "=== OTTENENDO TOKEN ==="
        $token = Get-AuthToken -ServerUrl $ServerUrl -Username $Username -Password $Password -CompanyId $CompanyId
        
        if ($token) {
            Write-Output "=== CHIAMANDO API ==="
            $result = Invoke-ApiCall -ServerUrl $ServerUrl -Endpoint $Endpoint -Token $token -OutputFile $OutputFile -Method $Method -BodyFile $BodyFile -BodyJson $BodyJson
        }
    }
    
    default {
        Write-Output "ERRORE: Azione non valida. Usa: token, api, post, delete, o full"
        Write-Output "Esempi:"
        Write-Output "  -Action token"
        Write-Output "  -Action post -Token 'your_token' -Endpoint '/api/v1/fatTes-fattura/simplified' -BodyFile 'C:\temp\body.json'"
        Write-Output "  -Action delete -Token 'your_token' -Endpoint '/api/v1/fatTes-fattura/356010'"
        Write-Output "  -Action full -Endpoint '/api/v1/fatTes-fattura/simplified' -Method POST -BodyFile 'C:\temp\body.json'"
    }
} 