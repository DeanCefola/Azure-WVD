# --- Configuration ---
$clientId = "d045db27-d460-4cd2-a377-44f688236973"  # Managed Identity Client ID
$storageAccountName = "wvdfslogixeast02"           # Storage Account Name
$containerName = "recast"                          # Blob Container Name
# Files to download
$blobFiles = @(
    "Agent.exe",
    "Agent.json",
    "AgentBootstrapper-Win-2.1.0.2.exe",
    "AgentRegistration.cer",
    "ImageAgentDeploy.ps1"
)
$DestinationPath = "C:\InstallFiles"               # Target path in the AIB VM
$InstallerPath = "C:\InstallFiles\AgentBootstrapper-Win-2.1.0.2.exe" 
$InstallerArguments = "/certificate=C:\InstallFiles\AgentRegistration.cer /startDeployment /waitForDeployment /logPath=C:\Windows\Temp"         # Optional: Add any command-line arguments for the installer

# =============================
# DOWNLOAD FILES TO DESTINATION
# =============================
# Create destination directory
if (!(Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

foreach ($blobName in $blobFiles) {
    $blobUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"                
    $localFilePath = Join-Path $DestinationPath $blobName

    Write-Output "Downloading $blobName to $localFilePath..."
    try {
        Invoke-RestMethod -Uri $blobUrl -Headers $headers -OutFile $localFilePath
        Write-Output "$blobName downloaded successfully."
    } catch {
        Write-Output "Failed to download $blobName $_"
    }
}

Write-Output "All downloads completed."


# ===============================
set-location $DestinationPath 

# Start the install process

Write-Host "Starting the installation process..."

if (Test-Path -Path $InstallerPath) {

   try {

       Start-Process -FilePath $InstallerPath -ArgumentList $InstallerArguments -Wait

       Write-Host "Installation process completed."

   } catch {

       Write-Error "Error starting the installer '$InstallerPath': $($_.Exception.Message)"

       exit 1

   }

} else {

   Write-Warning "Installer executable not found: '$InstallerPath'"

}
 