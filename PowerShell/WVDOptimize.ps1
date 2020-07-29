<#Author       : Dean Cefola
# Creation Date: 07-09-2020
# Usage        : Windows Virtual Desktop Optimization Script
# All code that this script executes is created and provided by THE VDI GUYS
# You can download the code here  --  https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 07/09/2020                     1.0        Intial Version
#

#*********************************************************************************
#
#>


################################
#    Download WVD Optimizer    #
################################
New-Item -Path C:\ -Name Optimize -ItemType Directory -ErrorAction SilentlyContinue
$LocalPath = "C:\Optimize\"
$WVDOptimizeURL = 'https://github.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/archive/master.zip'
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
Set-Location -Path C:\Optimize\Virtual-Desktop-Optimization-Tool-master


#################################
#    Run WVD Optimize Script    #
#################################
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
.\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Restart -Verbose

