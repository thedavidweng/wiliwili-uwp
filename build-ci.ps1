
$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot

if (-not ($env:VCPKG_ROOT)) {
    $env:VCPKG_ROOT = $env:VCPKG_INSTALLATION_ROOT
}
if (-not (Test-Path "$env:VCPKG_ROOT\vcpkg.exe")) {
    Write-Error "No vcpkg.exe"
    exit 1
}

Write-Host "VCPKG_ROOT: $env:VCPKG_ROOT"

if (-not (Test-Path '.\libs\mpv\lib\mpv.lib')) {
    $mpvUrl = 'https://github.com/ikas-mc/wiliwili-uwp-poc/releases/download/0.4/x64-uwp-mpv.zip'
    $mpvHash = '82f8ce29700bf2c586d64c991f602b78c3e9a560c9094f07572db7f7e3ab7cef'
    Write-Host "Downloading mpv..."
    & curl.exe -L -o '.\x64-uwp-mpv.zip' $mpvUrl

    $actualHash = (Get-FileHash '.\x64-uwp-mpv.zip' -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -ne $mpvHash) {
        Write-Error "x64-uwp-mpv.zip hash mismatch: expected $mpvHash but got $actualHash"
        exit 1
    }

    Expand-Archive '.\x64-uwp-mpv.zip' -DestinationPath '.\libs\mpv\' -Force
}
if (-not (Test-Path '.\libs\mpv\lib\mpv.lib')) {
    Write-Error "Failed to install x64-uwp-mpv.zip"
    exit 1
}

if (-not (Test-Path "./borealis")) {
    Write-Host "Cloning borealis..."
    & git clone --depth 1 https://github.com/xfangfang/borealis.git borealis
}
if (-not (Test-Path "./wiliwili")) {
    Write-Host "Cloning wiliwili v1.6.0..."
    & git clone --depth 1 -b v1.6.0 https://github.com/xfangfang/wiliwili.git wiliwili
    Set-Location wiliwili
    & git submodule update --init --depth 1 -- "library/libpdr" "library/pystring" "library/mongoose"
}

Set-Location $workDir

# update build version
if ($env:VERSION_BUILD_NUMBER) {
    $appxManifestPath = Convert-Path ".\wiliwili-uwp\package.appxManifest"
    [xml]$manifest = Get-Content -Path $appxManifestPath
    $version = $manifest.Package.Identity.Version
    $versionParts = $version -split '\.'
    if ($versionParts.Length -eq 4) {
        $versionParts[3] = $env:VERSION_BUILD_NUMBER
        $manifest.Package.Identity.Version = $versionParts -join "."
    }
    else {
        Write-Error "Version format error: $version"
        exit 1
    }
    Write-Host "package new version: $($manifest.Package.Identity.Version)"
    $manifest.Save($appxManifestPath)
}

Write-Host "Running cmake..."
& cmake --preset=uwp-release
if ($LASTEXITCODE -ne 0) { Write-Error "cmake failed"; exit 1 }

Write-Host "Running msbuild..."
& msbuild build\wiliwili-uwp.vcxproj /m /p:configuration="release" /p:platform="x64" /p:AppxBundlePlatforms="x64" /p:UapAppxPackageBuildMode="SideloadOnly" /p:PackageOptionalProjectsInIdeBuilds=False
if ($LASTEXITCODE -ne 0) { Write-Error "msbuild failed"; exit 1 }

Write-Host "Build completed successfully."
