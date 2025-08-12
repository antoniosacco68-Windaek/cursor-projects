# Script per scaricare Google.Apis.Core.dll
$tempFolder = "C:\Temp\GoogleApisCore"
$destinationPath = "C:\Antonio\GoogleApi\lib"

# Crea cartella temporanea
Write-Host "Creo cartella temporanea $tempFolder..."
New-Item -ItemType Directory -Path $tempFolder -Force | Out-Null

# Scarica NuGet.exe se non è presente
$nugetPath = "$tempFolder\nuget.exe"
if (-not (Test-Path $nugetPath)) {
    Write-Host "Scarico NuGet.exe..."
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath
}

# Metodo 1: Scarica direttamente dal pacchetto NuGet
Write-Host "Scarico Google.Apis.Core da NuGet..."
& $nugetPath install Google.Apis.Core -OutputDirectory $tempFolder

# Se il download da NuGet non funziona, prova a scaricare il file direttamente
$coreApiFound = $false

# Cerca nelle cartelle scaricate
$downloadedFolders = Get-ChildItem -Path $tempFolder -Directory -Filter "Google.Apis.Core*"
if ($downloadedFolders) {
    Write-Host "Cerco Google.Apis.Core.dll nella cartella scaricata..."
    
    foreach ($folder in $downloadedFolders) {
        $dllFiles = Get-ChildItem -Path $folder.FullName -Recurse -Filter "Google.Apis.Core.dll"
        
        foreach ($dll in $dllFiles) {
            # Preferisci la versione net462 o netstandard2.0 che sono compatibili con .NET Framework
            if ($dll.DirectoryName -like "*net462*" -or $dll.DirectoryName -like "*netstandard2.0*") {
                Write-Host "Copio $($dll.Name) da $($dll.FullName) a $destinationPath..."
                Copy-Item -Path $dll.FullName -Destination $destinationPath -Force
                $coreApiFound = $true
                break
            }
        }
        
        # Se non abbiamo trovato una versione specifica, prendi la prima che troviamo
        if (-not $coreApiFound -and $dllFiles.Count -gt 0) {
            $dll = $dllFiles[0]
            Write-Host "Copio $($dll.Name) da $($dll.FullName) a $destinationPath..."
            Copy-Item -Path $dll.FullName -Destination $destinationPath -Force
            $coreApiFound = $true
        }
    }
}

# Metodo 2: Se non funziona il download, scarica il file direttamente
if (-not $coreApiFound) {
    Write-Host "Download diretto di Google.Apis.Core.dll..."
    $directDownloadUrl = "https://globalcdn.nuget.org/packages/google.apis.core.1.69.0.nupkg"
    $nupkgPath = "$tempFolder\google.apis.core.nupkg"
    
    try {
        Invoke-WebRequest -Uri $directDownloadUrl -OutFile $nupkgPath
        
        # Rinomina .nupkg a .zip per estrarlo
        $zipPath = "$tempFolder\google.apis.core.zip"
        Rename-Item -Path $nupkgPath -NewName $zipPath -Force
        
        # Estrai il file ZIP
        Expand-Archive -Path $zipPath -DestinationPath "$tempFolder\extracted" -Force
        
        # Cerca la DLL
        $extractedDlls = Get-ChildItem -Path "$tempFolder\extracted" -Recurse -Filter "Google.Apis.Core.dll"
        
        if ($extractedDlls.Count -gt 0) {
            # Preferisci net462 o netstandard2.0
            $bestDll = $extractedDlls | Where-Object { $_.DirectoryName -like "*net462*" -or $_.DirectoryName -like "*netstandard2.0*" } | Select-Object -First 1
            
            # Se non troviamo la versione preferita, prendi la prima
            if (-not $bestDll -and $extractedDlls.Count -gt 0) {
                $bestDll = $extractedDlls[0]
            }
            
            if ($bestDll) {
                Write-Host "Copio $($bestDll.Name) da $($bestDll.FullName) a $destinationPath..."
                Copy-Item -Path $bestDll.FullName -Destination $destinationPath -Force
                $coreApiFound = $true
            }
        }
    } catch {
        Write-Host "Errore durante il download diretto: $_"
    }
}

# Verifica finale
if ($coreApiFound) {
    Write-Host "`n✅ Google.Apis.Core.dll è stata scaricata e copiata in $destinationPath."
    Write-Host "Ora puoi eseguire lo script invioemail.ps1"
} else {
    Write-Host "`n❌ Non è stato possibile scaricare Google.Apis.Core.dll."
    
    # Link per download manuale
    Write-Host "`nPuoi scaricare manualmente il file da questi link:"
    Write-Host "1. https://www.nuget.org/packages/Google.Apis.Core/"
    Write-Host "2. Scarica il pacchetto, rinomina l'estensione da .nupkg a .zip"
    Write-Host "3. Estrai il file e cerca Google.Apis.Core.dll nella cartella lib/netstandard2.0"
    Write-Host "4. Copia il file in $destinationPath"
} 