param([string]$Version = '1.0.0-lab.1')
$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^[0-9A-Za-z][0-9A-Za-z.-]*$') { throw 'Invalid version' }
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$release = Join-Path $root 'native/build/portable/Release'
if (-not (Test-Path "$release/engine-sim-app.exe")) { throw 'Build -BuildName portable first' }
& "$PSScriptRoot/prepare-portable.ps1"
$output = Join-Path $root "dist/engine-sim-lab-$Version-windows-x64"
if (Test-Path $output) { throw "Output already exists; refusing overwrite: $output" }
New-Item -ItemType Directory -Force "$output/runtime", "$output/workspace", "$output/engine/fonts", "$output/LICENSES" | Out-Null
Copy-Item "$release/engine-sim-app.exe" "$output/EngineSim.exe"
Copy-Item "$root/native/assets" "$output/assets" -Recurse
Copy-Item "$root/native/es" "$output/es" -Recurse
$basic = Join-Path $root 'native/dependencies/submodules/delta-studio/engines/basic'
Copy-Item "$basic/shaders" "$output/engine/shaders" -Recurse
Copy-Item "$basic/fonts/Silkscreen" "$output/engine/fonts/Silkscreen" -Recurse
@('engine', 'assets') | Set-Content "$output/delta.conf" -Encoding ASCII
'catalog/gm_ls.mr' | Set-Content "$output/workspace/selected-engine.txt" -Encoding ASCII
'Working logs and temporary files are created here.' | Set-Content "$output/runtime/README.txt" -Encoding ASCII
Copy-Item "$PSScriptRoot/portable/README.ru.txt" "$output/README.ru.txt"
Copy-Item "$PSScriptRoot/portable/THIRD-PARTY-NOTICES.txt" "$output/THIRD-PARTY-NOTICES.txt"

$sdl = Join-Path $root '.native-tools/SDL2-devel-2.32.10-VC/SDL2-2.32.10'
$image = Join-Path $root '.native-tools/SDL2_image-devel-2.8.12-VC/SDL2_image-2.8.12'
Copy-Item "$sdl/lib/x64/SDL2.dll", "$image/lib/x64/SDL2_image.dll" $output
Copy-Item "$sdl/LICENSE.txt" "$output/LICENSES/SDL2.txt"
Copy-Item "$image/LICENSE.txt" "$output/LICENSES/SDL2_image.txt"
$dx = Join-Path $root '.native-tools/directx-release/9.29.952.8'
Copy-Item "$dx/build/native/release/bin/x64/*.dll" $output
Copy-Item "$dx/LICENSE.txt" "$output/LICENSES/Microsoft-D3DX-LICENSE.txt"
Copy-Item "$dx/NOTICE.md" "$output/LICENSES/Microsoft-D3DX-NOTICE.md"
Copy-Item "$dx/README.md" "$output/LICENSES/Microsoft-D3DX-README.md"

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$crt = Get-ChildItem "$vs/VC/Redist/MSVC" -Directory | Where-Object Name -Match '^\d' | Sort-Object Name -Descending | Select-Object -First 1
Get-ChildItem "$($crt.FullName)/x64/Microsoft.VC143.CRT/*.dll" | ForEach-Object {
    $signature = Get-AuthenticodeSignature $_.FullName
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'Microsoft Corporation') {
        throw "Microsoft CRT signature failed: $($_.Name)"
    }
    Copy-Item $_.FullName $output
}
$licenses = @{
    'EngineSimulator-MIT.txt' = "$root/native/LICENSE"
    'DeltaStudio-MIT.txt' = "$root/native/dependencies/submodules/delta-studio/LICENSE"
    'ConstraintSolver-MIT.txt' = "$root/native/dependencies/submodules/simple-2d-constraint-solver/LICENSE"
    'CsvIo-MIT.txt' = "$root/native/dependencies/submodules/csv-io/LICENSE"
    'Piranha-MIT.txt' = "$PSScriptRoot/licenses/Piranha-MIT.txt"
    'Silkscreen.txt' = "$basic/fonts/Silkscreen/Kottke Silkscreen License.txt"
    'Boost.txt' = "$root/.native-tools/packages-baseline/x64-engine-sim/share/boost-vcpkg-helpers/boost_LICENSE_1_0.txt"
}
foreach ($name in $licenses.Keys) { Copy-Item $licenses[$name] "$output/LICENSES/$name" }

$toolsVersion = (Get-Content "$vs/VC/Auxiliary/Build/Microsoft.VCToolsVersion.default.txt").Trim()
$dumpbin = "$vs/VC/Tools/MSVC/$toolsVersion/bin/Hostx64/x64/dumpbin.exe"
$dependencies = & $dumpbin /DEPENDENTS "$output/EngineSim.exe"
if ($LASTEXITCODE -ne 0 -or ($dependencies -join "`n") -match 'd3dx\d+d_\d+\.dll') { throw 'Executable still depends on debug DirectX' }
if (Get-ChildItem "$output/*d_43.dll") { throw 'Debug runtime must not be shipped' }
($dependencies -replace [regex]::Escape($output), '.') | Set-Content "$output/DEPENDENCIES.txt" -Encoding ASCII
$flex = Get-Content "$root/native/dependencies/submodules/piranha/dependencies/libraries/flex/include/FlexLexer.h"
$flex[4..27] | Set-Content "$output/LICENSES/FlexLexer-BSD.txt" -Encoding ASCII
$stb = Get-Content "$root/native/dependencies/submodules/delta-studio/dependencies/libraries/stb/stb/stb_truetype.h" -Raw
$licenseOffset = $stb.IndexOf('ALTERNATIVE A - MIT License')
if ($licenseOffset -lt 0) { throw 'STB license notice not found' }
$stb.Substring($licenseOffset) | Set-Content "$output/LICENSES/STB-notices.txt" -Encoding ASCII
Get-ChildItem $output -File -Recurse | Sort-Object FullName | ForEach-Object {
    $path = $_.FullName.Substring($output.Length + 1).Replace('\', '/')
    '{0}  {1}' -f (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower(), $path
} | Set-Content "$output/SHA256SUMS.txt" -Encoding ASCII
$zip = "$output.zip"
if (Test-Path $zip) { throw 'ZIP already exists; refusing overwrite' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($output, $zip, [IO.Compression.CompressionLevel]::Optimal, $true)
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
"$hash  $([IO.Path]::GetFileName($zip))" | Set-Content "$zip.sha256" -Encoding ASCII
Write-Output "Portable package: $zip"
