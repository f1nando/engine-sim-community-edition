$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$destination = Join-Path $root '.native-tools/directx-release'
New-Item -ItemType Directory -Force $destination | Out-Null
$package = Join-Path $destination 'microsoft.dxsdk.d3dx.9.29.952.8.nupkg'
if (-not (Test-Path $package)) {
    Invoke-WebRequest 'https://api.nuget.org/v3-flatcontainer/microsoft.dxsdk.d3dx/9.29.952.8/microsoft.dxsdk.d3dx.9.29.952.8.nupkg' -OutFile $package -UseBasicParsing
}
if ((Get-FileHash $package -Algorithm SHA256).Hash -ne 'EAD0906AE8A26C18A7525DA7490127A2110F7C58F18293738283E30E97C6EA4B') {
    throw 'Official D3DX package hash mismatch'
}
$extracted = Join-Path $destination '9.29.952.8'
if (-not (Test-Path $extracted)) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($package, $extracted)
}
Get-ChildItem "$extracted/build/native/release/bin/x64/*.dll" | ForEach-Object {
    $signature = Get-AuthenticodeSignature $_.FullName
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
        throw "Microsoft runtime signature failed: $($_.Name)"
    }
}
Write-Output 'Official D3DX release package verified. No system settings or security policies changed.'
