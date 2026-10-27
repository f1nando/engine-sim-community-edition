param([ValidateSet('modernization')][string]$BuildName = 'modernization')

# Runs the in-app integration scenario, not synthetic hardware Raw Input.
# No foreground window, keyboard or mouse capture is needed. The scenario
# renders real frames, records 34 simulated seconds, reloads and then exits.
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$exe = Join-Path $root "native/build/$BuildName/Release/engine-sim-app.exe"
$workingDirectory = Join-Path $root 'native/build'
if (Get-Process -Name 'engine-sim-app' -ErrorAction SilentlyContinue) {
    throw 'Close the simulator before the integration test to avoid duplicate audio instances.'
}
& (Join-Path $PSScriptRoot 'run-baseline.ps1') -BuildName $BuildName -PrepareOnly
$process = Start-Process -FilePath $exe -ArgumentList '--validate-history-ui' -WorkingDirectory $workingDirectory -PassThru
if (-not $process.WaitForExit(120000)) { throw 'Integration test did not exit in 120 seconds; inspect its window/log.' }
Get-Content (Join-Path $workingDirectory 'history-ui-validation.log')
if ($process.ExitCode -ne 0) { throw "Integration test failed with exit code $($process.ExitCode)." }
