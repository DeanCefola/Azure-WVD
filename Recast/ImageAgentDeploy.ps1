<#Author       : Dean Cefola
# Creation Date: 05-01-2025
# Usage        : Recast Agent Bootstrap - Dowload from Private Azure Blob Storage Container
#
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 05/01/2025                     1.0        Intial Version
#

#*********************************************************************************
#
#>

######################
#   Configuration    #
######################
$storageAccountName = "wvdfslogixeast02"           # Storage Account Name
$containerName = "recast"                          # Blob Container Name
# Files to download
$blobFiles = @(
    "Agent.exe",
    "Agent.json",
    "AgentBootstrapper-Win-2.1.0.2.exe",
    "AgentRegistration.cer"
)
$DestinationPath = "C:\InstallFiles"               # Target path in the AIB VM
$InstallerPath = "C:\InstallFiles\AgentBootstrapper-Win-2.1.0.2.exe" 
$InstallerArguments = "/certificate=C:\InstallFiles\AgentRegistration.cer /startDeployment /waitForDeployment /logPath=C:\Windows\Temp"         # Optional: Add any command-line arguments for the installer
<#$response = Invoke-WebRequest -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-01-01&resource=https://storage.azure.com" -Headers @{"Metadata"="true"}
$token = ($response.Content | ConvertFrom-Json).access_token
$headers = @{
    "Authorization" = "Bearer $token"
    "x-ms-version" = "2021-08-06"
}#>


#######################################
#    DOWNLOAD FILES TO DESTINATION    #
#######################################
# Create destination directory
if (!(Test-Path $DestinationPath)) {   
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
}

foreach ($blobName in $blobFiles) {
    $localFilePath = Join-Path $DestinationPath $blobName
    $blobUrl = "https://$storageAccountName.blob.core.windows.net/$containerName/$blobName"                
    #Invoke-WebRequest -Uri $blobUrl -Headers $headers -OutFile $localFilePath
    Invoke-WebRequest -Uri $blobUrl -OutFile $localFilePath

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
 