<#Author       : Dean Cefola
# Creation Date: 09-15-2019
# Usage        : Windows Virtual Desktop Scripted Install

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 09/15/2019                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


##############################
#    WVD Script Parameters   #
##############################
Param (    
    [Parameter(Mandatory=$true)]
        [string]$ProfilePath,
    [Parameter(Mandatory=$true)]
        [string]$RegistrationToken
)


######################
#    WVD Variables   #
######################
$WVDBootURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrxrH'
$WVDAgentURI = 'https://query.prod.cms.rt.microsoft.com/cms/api/am/binary/RWrmXv'
$FSLogixURI = 'https://go.microsoft.com/fwlink/?linkid=2084562'
$WVDAgentInstaller = 'WVD-Agent.msi'
$WVDBootInstaller = 'WVD-Bootloader.msi'
$FSInstaller = 'FSLogixAppsSetup.zip'
$Localpath = "c:\temp\wvd\"


####################################
#    Test/Create Temp Directory    #
####################################
if((Test-Path $Localpath) -eq $false) {
    write "creating temp directory"
    New-Item -Path $Localpath -ItemType Directory
}
else {
    write "temp directory already exists"
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
    -LiteralPath C:\temp\wvd\FSLogixAppsSetup.zip `
    -DestinationPath "$Localpath\FSLogix" `
    -Force `
    -Verbose
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
cd $Localpath 


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


##############################
#    FSLogix Reg Settings    #
##############################
Push-Location 
Set-Location HKLM:\SOFTWARE\FSLogix
New-Item `
    -Path HKLM:\SOFTWARE\FSLogix `
    -Name Profiles `
    -Value "" `
    -Force 
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "DeleteLocalProfileWhenVHDShouldApply" `
    -PropertyType "DWord" `
    -Value 1
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "Enabled" `
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
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "FoldersToRemove" `
    -PropertyType "MultiString" `
    -Value ""
New-ItemProperty `
    -Path HKLM:\SOFTWARE\FSLogix\Profiles `
    -Name "VHDLocations" `
    -PropertyType "MultiString" `
    -Value $ProfilePath
Pop-Location
 

