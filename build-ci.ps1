
$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
$borealisRepo = "https://github.com/14185638/borealis.git"
$borealisRef = "winrt-dev"
$borealisCommit = "b35041cb0c8589e41a4a1510745a195831a06e68"
$wiliwiliRepo = "https://github.com/14185638/wiliwili.git"
$wiliwiliRef = "winrt-dev"
$wiliwiliCommit = "8d2f16e24db7418498a729f691b5d8e45ba7531a"

function Ensure-GitCheckout {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Repo,
        [Parameter(Mandatory = $true)][string]$Ref,
        [Parameter(Mandatory = $true)][string]$Commit
    )

    $newCheckout = $false

    if (-not (Test-Path $Path)) {
        Write-Host "Cloning $Path..."
        & git clone --no-checkout $Repo $Path
        if ($LASTEXITCODE -ne 0) { Write-Error "git clone failed for $Path"; exit 1 }
        $newCheckout = $true
    }

    if (-not (Test-Path (Join-Path $Path ".git"))) {
        Write-Error "$Path exists but is not a git checkout"
        exit 1
    }

    Push-Location $Path
    try {
        if (-not $newCheckout) {
            $changes = & git status --porcelain
            if ($changes) {
                Write-Error "$Path has local changes; clean it before building"
                exit 1
            }
        }

        $origin = (& git config --get remote.origin.url).Trim()
        if ($origin -ne $Repo) {
            & git remote set-url origin $Repo
            if ($LASTEXITCODE -ne 0) { Write-Error "failed to set origin for $Path"; exit 1 }
        }

        Write-Host "Fetching $Path $Ref at $Commit..."
        & git fetch --depth 1 origin $Commit
        if ($LASTEXITCODE -ne 0) { Write-Error "git fetch failed for $Path"; exit 1 }

        & git checkout --detach $Commit
        if ($LASTEXITCODE -ne 0) { Write-Error "git checkout failed for $Path at $Commit"; exit 1 }

        $actualCommit = (& git rev-parse HEAD).Trim()
        if ($actualCommit -ne $Commit) {
            Write-Error "$Path checkout mismatch: expected $Commit but got $actualCommit"
            exit 1
        }
    }
    finally {
        Pop-Location
    }
}

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

Ensure-GitCheckout -Path "borealis" -Repo $borealisRepo -Ref $borealisRef -Commit $borealisCommit
Ensure-GitCheckout -Path "wiliwili" -Repo $wiliwiliRepo -Ref $wiliwiliRef -Commit $wiliwiliCommit

Set-Location wiliwili
& git submodule update --init --depth 1 -- "library/libpdr" "library/pystring" "library/mongoose"
if ($LASTEXITCODE -ne 0) { Write-Error "wiliwili submodule update failed"; exit 1 }

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
