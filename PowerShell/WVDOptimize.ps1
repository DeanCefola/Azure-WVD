# Author       : Dean Cefola
# Creation Date: 07-09-2020
# Usage        : Windows Virtual Desktop Optimization Script
# All code that this script executes is created and provided by THE VDI GUYS
# You can download the code here  --  https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
#******************************************************************************************************************
# Date                         Version      Changes
#-----------------------------------------------------------------------------------------------------------------
# 05/20/2021 (Jason Masten)     1.1         Removed WindowsVersion parameter since the value is auto collected
#                                           Added parameter to Accept EULA
#                                           Added parameter & param block to allow Optimization choices
#                                           Fixed zip file changes
#
# 07/09/2020                     1.0        Intial Version
#******************************************************************************************************************

[Cmdletbinding()]
Param (
    [ValidateSet('All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup')] 
    [String[]]
    $Optimizations = "All"
)

################################
#    Download WVD Optimizer    #
################################
New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = "C:\Optimize\"
$WVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/refs/heads/main.zip'
$WVDOptimizeInstaller = "Windows_10_VDI_Optimize-master.zip"
Invoke-WebRequest `
    -Uri $WVDOptimizeURL `
    -OutFile "$Localpath$WVDOptimizeInstaller"


###############################
#    Prep for WVD Optimize    #
###############################
Expand-Archive `
    -LiteralPath "C:\Optimize\Windows_10_VDI_Optimize-master.zip" `
    -DestinationPath "$Localpath" `
    -Force `
    -Verbose


#################################
#    Run WVD Optimize Script    #
#################################
New-Item -Path C:\Optimize\ -Name install.log -ItemType File -Force
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
add-content c:\Optimize\install.log "Starting Optimizations"  
& C:\Optimize\Virtual-Desktop-Optimization-Tool-main\Win10_VirtualDesktop_Optimize.ps1 -Optimizations $Optimizations -Restart -AcceptEULA -Verbose
