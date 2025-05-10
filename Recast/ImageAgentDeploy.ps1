# --- Configuration ---
$clientId = "d045db27-d460-4cd2-a377-44f688236973"  # Managed Identity Client ID
$storageAccountName = "wvdfslogixeast00"           # Storage Account Name
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

# --- Script Start ---
# ===============================
# 1. INSTALL AZURE CLI
# ===============================
Write-Output "Installing Azure CLI..."
Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi
Start-Process msiexec.exe -ArgumentList "/i AzureCLI.msi /quiet" -Wait

# Add Azure CLI to path for current session
$env:PATH += ";C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin"

# ===============================
# 2. LOGIN WITH MANAGED IDENTITY
# ===============================
Write-Output "Logging in with user-assigned managed identity..."
az login --identity --username $clientId | Out-Null

# ===============================
# 3. GET BLOB STORAGE ACCESS TOKEN
# ===============================
Write-Output "Getting access token for blob storage..."
$accessToken = az account get-access-token `
  --resource https://storage.azure.com/ `
  --query accessToken -o tsv `
  --identity --username $clientId

# Set Authorization header with bearer token
$headers = @{
  Authorization = "Bearer $accessToken"
}

# ===============================
# 4. DOWNLOAD FILES TO DESTINATION
# ===============================
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
 