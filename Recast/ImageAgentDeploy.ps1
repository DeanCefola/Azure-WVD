# --- Configuration ---

$SourceShare = "\\wvdfslogixeast00.file.core.windows.net\recast"  # Replace with the actual network share path

$DestinationPath = "C:\InstallFiles"        # Replace with the desired local destination path

$FilesToCopy = @("AgentRegistration.cer", "Agent.json", "Agent.exe", "AgentBootstrapper-Win-2.1.0.2.exe") # Replace with the actual file names

$InstallerPath = "C:\InstallFiles\AgentBootstrapper-Win-2.1.0.2.exe" # Replace with the path to the installer executable

$InstallerArguments = "/certificate=C:\InstallFiles\AgentRegistration.cer /startDeployment /waitForDeployment /logPath=C:\Windows\Temp"         # Optional: Add any command-line arguments for the installer

# --- Script Start ---

# 1. Create the local destination directory if it doesn't exist

Write-Host "Creating destination directory: '$DestinationPath'"

if (-not (Test-Path -Path $DestinationPath -PathType Container)) {

   try {

       New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null

       Write-Host "Destination directory created successfully."

   } catch {

       Write-Error "Error creating directory '$DestinationPath': $($_.Exception.Message)"

       exit 1

   }

}

# 2. Copy the specified files from the network share to the local directory

Write-Host "Copying files from '$SourceShare' to '$DestinationPath'..."

foreach ($File in $FilesToCopy) {

   $SourceFile = Join-Path -Path $SourceShare -ChildPath $File

   $DestinationFile = Join-Path -Path $DestinationPath -ChildPath $File

   if (Test-Path -Path $SourceFile) {

       try {

           Copy-Item -Path $SourceFile -Destination $DestinationFile -Force

           Write-Host "Successfully copied: '$File'"

       } catch {

           Write-Error "Error copying '$File': $($_.Exception.Message)"

       }

   } else {

       Write-Warning "Source file not found: '$SourceFile'"

   }

}
set-location $DestinationPath 

# 3. Start the install process

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
 