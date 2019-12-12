﻿<#Author       : Dean Cefola
# Creation Date: 09-15-2019
# Usage        : Windows Virtual Desktop Scripted Install

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 09/15/2019                     1.0        Intial Version
# 09/16/2019                     2.0        Add FSLogix installer
# 09/16/2019                     2.1        Add FSLogix Reg Keys 
# 09/16/2019                     2.2        Add Input Parameters 
# 09/16/2019                     2.3        Add TLS 1.2 settings
# 09/17/2019                     3.0        Chang download locations to dynamic
# 09/17/2019                     3.1        Add code to disable IESEC for admins
# 09/20/2019                     3.2        Add code to discover OS (Server / Client)
# 09/20/2019                     4.0        Add code for servers to add RDS Host role
# 10/01/2019                     4.2        Add all FSLogix Profile Container Reg entries for easier management
# 10/07/2019                     4.3        Add FSLogix Office Container Reg entries for easier management
# 10/16/2019                     5.0        Add Windows 7 Support
# 12/05/2019                     6.0        Add Azure NetApp Files Support (Author: Kirk Ryan)
#*********************************************************************************
#
#>


######################
#    WVD Variables   #
######################
$Localpath = "c:\temp\wvd\"
$WVDBootURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$FSLogixURI = 'https://go.microsoft.com/fwlink/?linkid=2084562'
$FSInstaller = 'FSLogixAppsSetup.zip'
$ANFEnabled = $true # Refer to https://kirkryan.co.uk/2019/12/04/windows-virtual-desktop-(and-citrix)-with-fslogix for full deployment instructions
$ANFSMBPath = "" # Insert your Azure NetApp Files SMB volume path here
$WVDAgentInstaller = 'WVD-Agent.msi'
$WVDBootInstaller = 'WVD-Bootloader.msi'
$Win7x64_UpdateURI = 'https://download.microsoft.com/download/A/F/5/AF5C565C-9771-4BFB-973B-4094C1F58646/Windows6.1-KB2592687-x64.msu'                                        
$Win7x64_WMI5URI = 'https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/Win7AndW2K8R2-KB3191566-x64.zip'
$Win7x64_UpdateInstaller = 'Win7-KB2592687-x64.msu'
$Win7x64_WMI5Installer = 'Win7-KB3191566-WMI5-x64.zip'
$Win7x64_WVDAgentURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE3JZCm'
$Win7x64_WVDBootMgrURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RE3K2e3'

#############################
WVD Script Parameters   #
#############################
if (($ANFEnabled) -eq $false) {
    Param (        
        [Parameter(Mandatory = $true)]
        [string]$ProfilePath,
        [Parameter(Mandatory = $true)]
        [string]$RegistrationToken
    )
}
else {
    Param (        
        [Parameter(Mandatory = $true)]
        [string]$RegistrationToken
    )
}
####################################
#    Test/Create Temp Directory    #
####################################
if ((Test-Path $Localpath) -eq $false) {
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "creating temp directory"
    New-Item -Path $Localpath -ItemType Directory
}
else {
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "temp directory already exists"
}


#################################
#    Download WVD Componants    #
#################################
Invoke-WebRequest -Uri $WVDBootURI -OutFile "$Localpath$WVDBootInstaller"
Invoke-WebRequest -Uri $WVDAgentURI -OutFile "$Localpath$WVDAgentInstaller"
Invoke-WebRequest -Uri $FSLogixURI -OutFile "$Localpath$FSInstaller"


##############################
#    Prep for WVD Install    #
##############################
Expand-Archive `
    -LiteralPath "C:\temp\wvd\$FSInstaller" `
    -DestinationPath "$Localpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $Localpath 


##############################
#    OS Specific Settings    #
##############################
$OS = (Get-WmiObject win32_operatingsystem).name
If (($OS) -match 'server') {
    write-host -ForegroundColor Cyan -BackgroundColor Black "Windows Server OS Detected"
    If (((Get-WindowsFeature -Name RDS-RD-Server).installstate) -eq 'Installed') {
        "Session Host Role is already installed"
    }
    Else {
        "Installing Session Host Role"
        Install-WindowsFeature `
            -Name RDS-RD-Server `
            -Verbose `
            -LogPath "$Localpath\RdsServerRoleInstall.txt"
    }
    $AdminsKey = "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UsersKey = "SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey("LocalMachine", "Default")
    $SubKey = $BaseKey.OpenSubkey($AdminsKey, $true)
    $SubKey.SetValue("IsInstalled", 0, [Microsoft.Win32.RegistryValueKind]::DWORD)
    $SubKey = $BaseKey.OpenSubKey($UsersKey, $true)
    $SubKey.SetValue("IsInstalled", 0, [Microsoft.Win32.RegistryValueKind]::DWORD)    
}
Else {
    write-host -ForegroundColor Cyan -BackgroundColor Black "Windows Client OS Detected"
    if (($OS) -match 'Windows 10') {
        write-host `
            -ForegroundColor Yellow `
            -BackgroundColor Black  `
            "Windows 10 detected...skipping to next step"     
    }    
    else {
        $OSArch = (Get-WmiObject win32_operatingsystem).OSArchitecture
        If (($OSArch) -match '64-bit') {
            write-host `
                -ForegroundColor Magenta  `
                -BackgroundColor Black `
                "Windows 7 x64 detected"


            #################################
            #    Begin Win7x64 downloads    #
            #################################
            $Win7x64_WinUpdateRequest = [System.Net.WebRequest]::Create($Win7x64_UpdateURI)
            $Win7x64_WMI5Request = [System.Net.WebRequest]::Create($Win7x64_WMI5URI)            
            $Win7x64_WVDAgentRequest = [System.Net.WebRequest]::Create($Win7x64_WVDAgentURI)
            $Win7x64_WVDBootRequest = [System.Net.WebRequest]::Create($Win7x64_WVDBootMgrURI)


            ################################
            #    Begin Win7x64 Installs    #
            ################################
            write-host `
                -ForegroundColor Magenta `
                -BackgroundColor Black `
                "...installing Update KB2592687 for x64"
            Expand-Archive `
                -LiteralPath "C:\temp\wvd\$Win7x64_WMI5Installer" `
                -DestinationPath "$Localpath\Win7Wmi5x64" `
                -Force `
                -Verbose
            $packageName = 'Win7AndW2K8R2-KB3191566-x64.msu'
            $packagePath = 'C:\temp\wvd\Win7Wmi5x64'
            $wusaExe = "$env:windir\system32\wusa.exe"
            $wusaParameters += @("/quiet", "/promptrestart")
            $wusaParameterString = $wusaParameters -join " "
            & $wusaExe $wusaParameterString
        }        
    }
}


################################
#    Install WVD Componants    #
################################
$bootloader_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDBootInstaller", `
    "/quiet", `
    "/qn", `
    "/norestart", `
    "/passive", `
    "/l* $Localpath\AgentBootLoaderInstall.txt" `
    -Wait `
    -Passthru
$sts = $bootloader_deploy_status.ExitCode
Write-Output "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
Wait-Event -Timeout 5
Write-Output "Installing RD Infra Agent on VM $AgentInstaller`n"
$agent_deploy_status = Start-Process `
    -FilePath "msiexec.exe" `
    -ArgumentList "/i $WVDAgentInstaller", `
    "/quiet", `
    "/qn", `
    "/norestart", `
    "/passive", `
    "REGISTRATIONTOKEN=$RegistrationToken", "/l* $Localpath\AgentInstall.txt" `
    -Wait `
    -Passthru
Wait-Event -Timeout 5


#########################
#    FSLogix Install    #
#########################
$fslogix_deploy_status = Start-Process `
    -FilePath "$Localpath\FSLogix\x64\Release\FSLogixAppsSetup.exe" `
    -ArgumentList "/install /quiet" `
    -Wait `
    -Passthru


#######################################
#    FSLogix User Profile Settings    #
#######################################
Push-Location 
Set-Location HKLM:\SOFTWARE\FSLogix
New-Item `
    -Path HKLM:\SOFTWARE\FSLogix `
    -Name Profiles `
    -Value "" `
    -Force
if (($ANFEnabled) -eq $false) {
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        "using CCD location"
    New-ItemProperty `
        -Path HKLM:\SOFTWARE\FSLogix\Profiles `
        -Name "CCDLocations" `
        -PropertyType "MultiString" `
        -Value "type=smb,connectionString=$ProfilePath;type=smb,connectionString=\\msdean.file.core.windows.net\fslogix"
}
else {
    Write-Host `
        -ForegroundColor Yellow `
        -BackgroundColor Black `
        "setting VHDLocation for Azure NetApp Files"
    New-ItemProperty `
        -Path HKLM:\SOFTWARE\FSLogix\Profiles `
        -Name "VHDLocations" `
        -PropertyType "MultiString" `
        -Value $ANFSMBPath
}


New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "Enabled" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "DeleteLocalProfileWhenVHDShouldApply" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "FlipFlopProfileDirectoryName" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "PreventLoginWithFailure" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "PreventLoginWithTempProfile" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "RebootOnUserLogoff" `
    -PropertyType "DWord" `
    -Value 0
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "ShutdownOnUserLogoff" `
    -PropertyType "DWord" `
    -Value 0
Pop-Location


#########################################
#    FSLogix Office Profile Settings    #
#########################################
Push-Location 
Set-Location HKLM:\SOFTWARE\Policies
New-Item `
    -Name FSLogix `
    -Value "" `
    -Force 
New-Item `
    -Path .\FSLogix `
    -Name ODFC `
    -Value "" `
    -Force
if (($ANFEnabled) -eq $false) {
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "CCDLocations" `
        -PropertyType "MultiString" `
        -Value "type=smb,connectionString=$ProfilePath;type=smb,connectionString=\\msdean.file.core.windows.net\fslogix"
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "Enabled" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "DeleteLocalProfileWhenVHDShouldApply" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "FlipFlopProfileDirectoryName" `
        -PropertyType "DWord" `
        -Value 0
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "PreventLoginWithFailure" `
        -PropertyType "DWord" `
        -Value 0
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "PreventLoginWithTempProfile" `
        -PropertyType "DWord" `
        -Value 0
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeOneDrive" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeOneNote" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeOneNote_UWP" `
        -PropertyType "DWord" `
        -Value 0
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeOutlook" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeOutlookPersonalization" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeSharepoint" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeSkype" `
        -PropertyType "DWord" `
        -Value 1
    New-ItemProperty `
        -Path .\FSLogix\ODFC `
        -Name "IncludeTeams" `
        -PropertyType "DWord" `
        -Value 1
    Pop-Location
}


#############
#    END    #
#############
Restart-Computer -Force


<######################
#    App Creation    #
######################
$AppPath = '\\MSAzureAcademy.com\CorpShares\AppAttach'
$Apps = Get-ChildItem -Path $AppPath | Where-Object -Property Name -Match .msix
foreach ($App in $Apps){
    $MSISource = "$AppPath\$App"
    $Package = $app.Name
    $VHDSource = $Package.Replace('.msix','.vhd')
    $PackageName = $Package.Replace('.msix','')
    $MSIXDestination = "C:\Program Files\WindowsApps\"+$PackageName
    Write-Host `
        -ForegroundColor Cyan `
        -BackgroundColor Black `
        $App
}


############################
#    Enable Sideloading    #
############################
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$Name1 = "AllowAllTrustedApps"
$value1 = "1"
$Name2 = "AllowDevelopmentWithoutDevLicense"
$value2 = "0"
New-ItemProperty `
    -Path $registryPath `
    -Name $name1 `
    -Value $value1 `
    -PropertyType DWORD `
    -Force
New-ItemProperty `
    -Path $registryPath `
    -Name $name2 `
    -Value $value2 `
    -PropertyType DWORD `
    -Force


####################
#    App Attach    #
####################
New-RdsRemoteApp `
    -TenantName $tenantname `
    -HostPoolName $hostpoolname `
    -AppGroupName $AppGroupName `
    -Name "VLC" `
    -FilePath "C:\Program Files\WindowsApps\VLC_1.0.4.0_x64__s11z9dr7vpbt2\VFS\ProgramFilesX86\VideoLAN\VLC\vlc.exe" 

#>
