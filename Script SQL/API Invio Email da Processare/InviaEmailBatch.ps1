# Parametri in ingresso
param(
    [Parameter(Mandatory=$true, ParameterSetName="SingleEmail")]
    [string]$EmailID,
    
    [Parameter(Mandatory=$true, ParameterSetName="BatchFile")]
    [string]$BatchFile,
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrentJobs = 5
)

function Send-SingleEmail {
    param (
        [Parameter(Mandatory=$true)]
        [string]$EmailID,
        
        [Parameter(Mandatory=$false)]
        [string]$BatchID = $null
    )
    
    # ... existing code ...
                
                # Aggiorna il database con il successo
                $updateCmd = New-Object System.Data.SqlClient.SqlCommand
                $updateCmd.Connection = $connection
                $updateCmd.CommandText = "UPDATE [dbo].[EmailDataDaProcessare] SET [Inviata] = 1, [DataInvio] = GETDATE(), [EmailID] = @EmailID, [Note] = NULL WHERE [ID] = @Id"
                $updateCmd.Parameters.AddWithValue("@EmailID", $response.Id)
                $updateCmd.Parameters.AddWithValue("@Id", $EmailID)
                $updateCmd.CommandTimeout = 30
                $updateCmd.ExecuteNonQuery()
# ... existing code ...

# ... existing code ...
# Elaborazione principale
$batchStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$batchID = [System.Guid]::NewGuid().ToString()

try {
    if ($PSCmdlet.ParameterSetName -eq "SingleEmail") {
        # Modalità email singola
        Write-Log "Elaborazione email singola: $EmailID" "INFO"
        $result = Send-SingleEmail -EmailID $EmailID -BatchID $batchID
        Write-Output $result
    } else {
        # ... existing code ...
        # Crea uno script block riutilizzabile con tutte le funzioni necessarie
        $scriptBlock = {
            param($EmailID, $Functions, $BatchID)
            
            # Importa le funzioni
            . ([ScriptBlock]::Create($Functions))
            
            # Elabora l'email
            Send-SingleEmail -EmailID $EmailID -BatchID $BatchID
        }
        
        # ... existing code ...
        
        foreach ($id in $emailIDs) {
            # ... existing code ...
            
            # Avvia un nuovo job
            $job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $id, $functionDefs, $batchID
            # ... existing code ...
        }
# ... existing code ...
} catch {
    # ... existing code ...
} 