# Script per scaricare e installare le DLL di Google API
# Crea una cartella temporanea
$tempFolder = "C:\Temp\GoogleApiDLL"
New-Item -ItemType Directory -Path $tempFolder -Force

# Imposta la directory di destinazione per le DLL
$destinationPath = "C:\Antonio\GoogleApi\lib"
New-Item -ItemType Directory -Path $destinationPath -Force

# Scarica NuGet.exe se non è presente
$nugetPath = "$tempFolder\nuget.exe"
if (-not (Test-Path $nugetPath)) {
    Write-Host "Scarico NuGet.exe..."
    Invoke-WebRequest -Uri "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -OutFile $nugetPath
}

# Scarica i pacchetti NuGet
Write-Host "Scarico i pacchetti Google API..."
& $nugetPath install Google.Apis.Gmail.v1 -OutputDirectory $tempFolder

# Copia le DLL necessarie nella cartella di destinazione
Write-Host "Copio le DLL nella cartella $destinationPath..."

# Elenca tutte le cartelle dei pacchetti scaricati
$packageFolders = Get-ChildItem -Path $tempFolder -Directory

# Cerca le DLL necessarie in tutte le cartelle dei pacchetti
$dllsToFind = @(
    "Google.Apis.Core.dll",
    "Google.Apis.dll",
    "Google.Apis.Auth.dll",
    "Google.Apis.Gmail.v1.dll",
    "Newtonsoft.Json.dll"
)

foreach ($dllName in $dllsToFind) {
    $dllFound = $false
    
    foreach ($folder in $packageFolders) {
        $dlls = Get-ChildItem -Path $folder.FullName -Recurse -Filter $dllName
        
        foreach ($dll in $dlls) {
            if ($dll.DirectoryName -like "*net462*" -or $dll.DirectoryName -like "*netstandard2.0*") {
                Write-Host "Copio $($dll.Name) da $($dll.FullName)..."
                Copy-Item -Path $dll.FullName -Destination $destinationPath -Force
                $dllFound = $true
                break
            }
        }
        
        if ($dllFound) {
            break
        }
    }
    
    if (-not $dllFound) {
        Write-Host "⚠️ Non è stato possibile trovare $dllName" -ForegroundColor Yellow
    }
}

# Elenca le DLL copiate
Write-Host "`nDLL disponibili in $destinationPath:" -ForegroundColor Green
Get-ChildItem -Path $destinationPath -Filter "*.dll" | ForEach-Object { Write-Host "- $($_.Name)" }

Write-Host "`nOgni DLL è stata copiata nella cartella $destinationPath. Ora puoi eseguire lo script invioemail.ps1" 