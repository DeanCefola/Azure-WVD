<#Author       : Dean Cefola
# Creation Date: 2-05-2020
# Usage        : OneDrive for AVD (Pooled) Installation
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 02/05/2020                     1.0        Intial Version
# 02/07/2020                     1.1        Add Uninstall
# 04/27/2020                     1.2        Add SilentConfig

#*********************************************************************************
#
#>


######################
#    Prerequisites   #
######################
$OneDriveURL = 'https://go.microsoft.com/fwlink/?linkid=844652'
$OutputPath = 'C:\temp\OneDrive\'
$OneDriveEXE = 'OneDriveSetup.exe'


#############################
#    Download Setup Files   #
#############################
if((Test-Path $OutputPath) -eq $false) {
    write-host `
    -ForegroundColor Red `
    -BackgroundColor Black 'Creating OneDrive Setup Directory'
    New-Item -Path $OutputPath -ItemType Directory    
    Invoke-WebRequest -Uri $OneDriveURL -OutFile $OutputPath$OneDriveEXE
}
else {
    write-host `
        -ForegroundColor Cyan `
        -BackgroundColor Black 'Output Directory already exists, Downloading OneDrive'    
    Invoke-WebRequest -Uri $OneDriveURL -OutFile $OutputPath$OneDriveEXE
}


#########################
#    Remove OneDrive    #
#########################
write-host 'Removing OneDrive for clean install'
Start-Process -FilePath "$OutputPath\OneDriveSetup.exe" /uninstall

##########################
#    Install OneDrive    #
##########################
write-host 'installing OneDrive'
REG ADD "HKLM\Software\Microsoft\OneDrive" /v "AllUsersInstall" /t REG_DWORD /d 1 /reg:64
Start-Process -FilePath "$OutputPath\OneDriveSetup.exe" /allusers
Wait-Event -Timeout 5
write-host 'OneDrive installation complete'
Wait-Event -Timeout 5
write-host 'Configuring OneDrive for AVD'
REG ADD "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "C:\Program Files (x86)\Microsoft OneDrive\OneDrive.exe /background" /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "SilentAccountConfig" /t REG_DWORD /d 1 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v "KFMSilentOptIn" /t REG_SZ /d "10c5dfa7-b5c3-4cf2-9265-f0e32a960967" /f


