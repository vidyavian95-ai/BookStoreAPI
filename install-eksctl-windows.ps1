# Install eksctl on Windows
# Run this in PowerShell as Administrator

# Create temp directory
$tempDir = "$env:TEMP\eksctl-install"
New-Item -ItemType Directory -Force -Path $tempDir | Out-Null

# Download eksctl for Windows
$eksctlUrl = "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_Windows_amd64.zip"
$zipFile = "$tempDir\eksctl.zip"

Write-Host "Downloading eksctl from $eksctlUrl..."
Invoke-WebRequest -Uri $eksctlUrl -OutFile $zipFile

# Extract to a directory in PATH
$installDir = "C:\Program Files\eksctl"
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Force -Path $installDir | Out-Null
}

Write-Host "Extracting to $installDir..."
Expand-Archive -Path $zipFile -DestinationPath $installDir -Force

# Add to PATH if not already there
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
if ($currentPath -notlike "*$installDir*") {
    Write-Host "Adding eksctl to system PATH..."
    [Environment]::SetEnvironmentVariable(
        "Path",
        "$currentPath;$installDir",
        "Machine"
    )
    Write-Host "Please restart your terminal for PATH changes to take effect."
}

# Cleanup
Remove-Item -Recurse -Force $tempDir

Write-Host "`neksctl installation complete!"
Write-Host "Verify with: eksctl version"
