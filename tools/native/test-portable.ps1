param([string]$Version = '1.0.0-lab.1')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
if ($Version -notmatch '^[0-9A-Za-z][0-9A-Za-z.-]*$') { throw 'Invalid version' }
if (Get-Process -Name 'engine-sim-app', 'EngineSim' -ErrorAction SilentlyContinue) {
    throw 'Close running simulator windows before testing the portable copy.'
}
$name = "engine-sim-lab-$Version-windows-x64"
$zip = Join-Path $root "dist/$name.zip"
$verification = [IO.Path]::GetFullPath((Join-Path $env:LOCALAPPDATA "Temp/opencode/portable verification $([Guid]::NewGuid())"))
New-Item -ItemType Directory -Force $verification | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::ExtractToDirectory($zip, $verification)
$package = Join-Path $verification $name
$exe = Join-Path $package 'EngineSim.exe'
foreach ($line in Get-Content "$package/SHA256SUMS.txt") {
    if ($line -notmatch '^([a-f0-9]{64})  (.+)$') { throw 'Invalid checksum manifest' }
    $expected = $Matches[1]
    $path = [IO.Path]::GetFullPath((Join-Path $package $Matches[2]))
    if (-not $path.StartsWith("$package\", [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid package path' }
    if ((Get-FileHash $path -Algorithm SHA256).Hash.ToLower() -ne $expected) { throw "Hash mismatch: $path" }
}
function Run-Validation([string]$argument, [int]$timeoutSeconds) {
    # Intentionally NOT the package folder: the exe must establish its own CWD.
    $process = Start-Process -FilePath $exe -ArgumentList $argument -WorkingDirectory $verification -PassThru
    if (-not $process.WaitForExit($timeoutSeconds * 1000)) { throw "Validation timed out: $argument" }
    if ($process.ExitCode -ne 0) { throw "Validation failed: $argument, exit $($process.ExitCode)" }
}
Run-Validation '--validate-catalog' 60
$catalog = Get-Content "$package/runtime/catalog-validation.log"
if (($catalog | Where-Object { $_ -match ': PASS$' }).Count -ne 12 -or $catalog -match ': FAIL$') {
    throw 'All 12 engine entry scripts must compile from the extracted portable folder.'
}
Run-Validation '--validate-history-ui' 120
$history = Get-Content "$package/runtime/history-ui-validation.log"
if ($history -notcontains 'RESULT: PASS') { throw 'Portable history integration validation did not pass' }
$process = Start-Process -FilePath $exe -WorkingDirectory $verification -PassThru
if ($process.WaitForExit(8000)) { throw "Normal GUI exited unexpectedly: $($process.ExitCode)" }
$process.Refresh()
if ($process.MainWindowHandle -eq 0 -or -not $process.Responding) { throw 'Portable window unavailable or unresponsive' }
if (-not $process.CloseMainWindow()) { throw 'Could not request normal portable-window shutdown' }
if (-not $process.WaitForExit(15000)) { throw 'Portable GUI did not shut down normally' }
$report = @(
    'Portable ZIP extraction and all manifest checksums: PASS'
    'Launch from a different working directory (path containing spaces): PASS'
    'Engine catalog compile: 12/12 PASS'
    "History integration: $(($history | Where-Object { $_ -match '^PASS:' }).Count) PASS"
    'Normal GUI window responding and normal shutdown: PASS'
    'Not a clean-machine, physical input, audio, SmartScreen or Smart App Control certification.'
    "Executable Authenticode status: $((Get-AuthenticodeSignature $exe).Status)"
)
$report | Set-Content (Join-Path $root "dist/$name-tests.txt") -Encoding UTF8
$report
Write-Output "Verified extracted copy: $package"
