param([switch]$ConfigureOnly, [ValidateSet('baseline', 'modernization', 'portable')][string]$BuildName = 'baseline')
$ErrorActionPreference = 'Stop'
$root = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
if (-not (Test-Path $vswhere)) { throw 'Visual Studio Build Tools locator not found' }
$vs = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio C++ workload not found' }
$cmake = Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
if (-not (Test-Path $cmake)) { throw 'Install C++ CMake tools for Windows' }
$packages = Join-Path $root '.native-tools\packages-baseline'
$prefix = Join-Path $packages 'x64-engine-sim'
$flex = Join-Path $root '.native-tools\winflexbison-2.5.25\win_flex.exe'
$bison = Join-Path $root '.native-tools\winflexbison-2.5.25\win_bison.exe'
$sdl = Join-Path $root '.native-tools\SDL2-devel-2.32.10-VC\SDL2-2.32.10'
$image = Join-Path $root '.native-tools\SDL2_image-devel-2.8.12-VC\SDL2_image-2.8.12'
foreach ($path in @($flex, $bison, (Join-Path $sdl 'include\SDL.h'), (Join-Path $image 'include\SDL_image.h'))) {
    if (-not (Test-Path $path)) { throw "Native dependency missing: $path" }
}
$source = Join-Path $root 'native'
$build = Join-Path $source "build\$BuildName"
$args = @('-S', $source, '-B', $build, '-G', 'Visual Studio 17 2022', '-A', 'x64',
    "-DCMAKE_GENERATOR_INSTANCE=$vs",
    "-DCMAKE_TOOLCHAIN_FILE=$root/.native-tools/vcpkg/scripts/buildsystems/vcpkg.cmake",
    "-DVCPKG_INSTALLED_DIR=$packages", '-DVCPKG_TARGET_TRIPLET=x64-engine-sim',
    "-DVCPKG_OVERLAY_TRIPLETS=$root/tools/native/triplets", '-DVCPKG_MANIFEST_MODE=OFF',
    "-DSDL2_DIR=$sdl", "-DSDL2_IMAGE_INCLUDE_DIR=$image/include", "-DSDL2_IMAGE_LIBRARY=$image/lib/x64/SDL2_image.lib", "-DBOOST_ROOT=$prefix",
    "-DFLEX_EXECUTABLE=$flex", "-DBISON_EXECUTABLE=$bison",
    '-DCMAKE_POLICY_DEFAULT_CMP0167=OLD', '-DDISCORD_ENABLED=OFF', '-DDTV=OFF', '-DPIRANHA_ENABLED=ON')
if ($BuildName -eq 'portable') {
    $directx = Join-Path $root '.native-tools/directx-release/9.29.952.8'
    if (-not (Test-Path "$directx/build/native/release/lib/x64/d3dx10.lib")) { throw 'Run prepare-portable.ps1 first' }
    $args += @('-DPORTABLE_RELEASE=ON', "-DPORTABLE_D3DX_ROOT=$directx")
}
& $cmake @args
if ($LASTEXITCODE -ne 0) { throw "Native configure failed ($LASTEXITCODE)" }
if (-not $ConfigureOnly) {
    & $cmake --build $build --config Release --target engine-sim-app --parallel 8
    if ($LASTEXITCODE -ne 0) { throw "Native build failed ($LASTEXITCODE)" }
}
