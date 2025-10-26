# Dioxus CLI Installer Script (PowerShell)
# Downloads pre-built binaries from GitHub releases
# Usage:
#   .\install-dx-rc.ps1              - Install latest release (including pre-releases)
#   .\install-dx-rc.ps1 -Stable      - Install latest stable release only
#   .\install-dx-rc.ps1 v0.7.0-rc.3  - Install specific version

param(
    [string]$Version,
    [switch]$Stable,
    [switch]$Update
)

$ErrorActionPreference = "Stop"

# Function to get latest release from GitHub
function Get-LatestRelease {
    param([bool]$StableOnly)

    $apiUrl = "https://api.github.com/repos/dioxuslabs/dioxus/releases"

    if ($StableOnly) {
        Write-Host "Fetching latest stable release..." -ForegroundColor DarkGray
        $release = Invoke-RestMethod "$apiUrl/latest"
        return $release.tag_name
    } else {
        Write-Host "Fetching latest release (including pre-releases)..." -ForegroundColor DarkGray
        $releases = Invoke-RestMethod $apiUrl
        return $releases[0].tag_name
    }
}

# Function to get currently installed version
function Get-CurrentVersion {
    if (Get-Command dx -ErrorAction SilentlyContinue) {
        $versionOutput = dx --version 2>&1 | Out-String
        if ($versionOutput -match 'dioxus (\d+\.\d+\.\d+(?:-[\w.]+)?)') {
            return $matches[1]
        }
    }
    return "not_installed"
}

$target = "x86_64-pc-windows-msvc"
$githubRepo = "https://github.com/dioxuslabs/dioxus"

# Determine which version to install
$currentVersion = Get-CurrentVersion

if ($Version) {
    # Specific version provided
    $dxVersion = $Version
    Write-Host "Installing Dioxus CLI $dxVersion (Specific Version)" -ForegroundColor White
} elseif ($Stable) {
    # Get latest stable only
    $dxVersion = Get-LatestRelease -StableOnly $true
    if (-not $dxVersion) {
        Write-Host "Error: Failed to fetch latest stable release from GitHub API" -ForegroundColor Red
        exit 1
    }
    Write-Host "Installing Dioxus CLI $dxVersion (Stable)" -ForegroundColor White
} else {
    # Auto-detect latest release (including RC)
    $dxVersion = Get-LatestRelease -StableOnly $false
    if (-not $dxVersion) {
        Write-Host "Error: Failed to fetch latest release from GitHub API" -ForegroundColor Red
        exit 1
    }

    # Check if update is needed
    if ($currentVersion -ne "not_installed") {
        Write-Host "Currently installed: v$currentVersion" -ForegroundColor DarkGray
        $versionWithoutV = $dxVersion -replace '^v', ''
        if ($currentVersion -eq $versionWithoutV) {
            Write-Host "Already up to date! (v$currentVersion)" -ForegroundColor Green
            exit 0
        } else {
            Write-Host "Update available: $currentVersion → $versionWithoutV" -ForegroundColor White
        }
    }

    Write-Host "Installing Dioxus CLI $dxVersion" -ForegroundColor White
}

$dxUri = "$githubRepo/releases/download/$dxVersion/dx-$target.zip"

# Install paths
$dxInstall = if ($env:DX_INSTALL) { $env:DX_INSTALL } else { "$env:USERPROFILE\.dx" }
$binDir = "$dxInstall\bin"
$exe = "$binDir\dx.exe"
$cargoBinDir = "$env:USERPROFILE\.cargo\bin"
$cargoBinExe = "$cargoBinDir\dx.exe"

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir -Force | Out-Null
}

Write-Host "Downloading from: $dxUri" -ForegroundColor DarkGray
$zipPath = "$exe.zip"

try {
    Invoke-WebRequest -Uri $dxUri -OutFile $zipPath -UseBasicParsing
    Expand-Archive -Path $zipPath -DestinationPath $binDir -Force

    # Copy to cargo bin if it exists
    if (Test-Path $cargoBinDir) {
        Copy-Item $exe $cargoBinExe -Force -ErrorAction SilentlyContinue
    }

    Remove-Item $zipPath

    Write-Host ""
    Write-Host "dx was installed successfully to:" -ForegroundColor Green
    Write-Host "  $exe" -ForegroundColor DarkGray
    if (Test-Path $cargoBinExe) {
        Write-Host "  $cargoBinExe" -ForegroundColor DarkGray
    }
    Write-Host ""

    # Verify installation
    if (Test-Path $exe) {
        $versionOutput = & $exe --version 2>&1
        Write-Host "Installed version: $versionOutput" -ForegroundColor Green
    }

    Write-Host ""
    if (Get-Command dx -ErrorAction SilentlyContinue) {
        Write-Host "✓ dx is available in PATH" -ForegroundColor Green
        Write-Host "Run 'dx --help' to get started" -ForegroundColor White
    } else {
        Write-Host "Add ~/.dx/bin to your PATH:" -ForegroundColor Yellow
        Write-Host "  `$env:PATH += `";$binDir`"" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Then run 'dx --help' to get started" -ForegroundColor White
    }

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}
