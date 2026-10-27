param([ValidateSet('baseline', 'modernization')][string]$BuildName = 'baseline', [switch]$PrepareOnly)
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$workingDirectory = Join-Path $root 'native\build'
$release = Join-Path $workingDirectory "$BuildName\Release"
$exe = Join-Path $release 'engine-sim-app.exe'
if (-not (Test-Path $exe)) { throw 'Build the baseline application first' }
$dlls = @(
    (Join-Path $root 'native\dependencies\submodules\delta-studio\dependencies\runtime\x64\D3DX10d_43.dll'),
    (Join-Path $root '.native-tools\SDL2-devel-2.32.10-VC\SDL2-2.32.10\lib\x64\SDL2.dll'),
    (Join-Path $root '.native-tools\SDL2_image-devel-2.8.12-VC\SDL2_image-2.8.12\lib\x64\SDL2_image.dll')
)
foreach ($dll in $dlls) {
    if (-not (Test-Path $dll)) { throw "Missing runtime library: $dll" }
    $target = Join-Path $release (Split-Path $dll -Leaf)
    if (Test-Path $target) {
        if ((Get-FileHash $dll).Hash -ne (Get-FileHash $target).Hash) {
            throw "Different runtime library already exists; refusing overwrite: $target"
        }
    }
    else { Copy-Item -LiteralPath $dll -Destination $target }
}
# Upstream resolves ../assets and ../dependencies relative to the working directory.
# Windows application-control errors must be reported, not bypassed.
if ($PrepareOnly) { return }
$process = Start-Process -FilePath $exe -WorkingDirectory $workingDirectory -PassThru
Write-Output "Started baseline process $($process.Id); verify image, sound and controls."
