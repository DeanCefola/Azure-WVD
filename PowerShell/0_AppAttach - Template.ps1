<#Author       : Dean Cefola
# Creation Date: 10-23-2023
# Usage        : Azure Virtual Desktop App Attach - Create App Images

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 10/23/2023                     1.0        Initial Version
#
#*********************************************************************************
#
#>

#####################################
#    MSIX App Attach - Variables    #
#####################################
$App = '<APP NAME>'
$MSIXPackageName = '<APP PACKAGE NAME>'
$MSIXPath = 'C:\temp\AVD App Attach\MSIX Packages\'
$PackagePath = "$MSIXPath$MSIXPackageName"
$CimDestinationPath = "C:\temp\AVD App Attach\AppAttach\$App\$App.cim"
$VhdxDestinationPath = "C:\temp\AVD App Attach\AppAttach\$App\$App.vhdx"


##############################
#    Create Cim Directory    #
##############################
$CimDirectory = "C:\temp\AVD App Attach\AppAttach\$App"
if ((Test-Path -path $CimDirectory) -ne $True) {
    New-Item -ItemType Directory $CimDirectory
} 

########################################
#    MSIX App Attach - CIMfs Format    #
########################################
& 'C:\temp\AVD App Attach\MSIXMgr\msixmgr.exe' `
    -Unpack `
    -packagePath $PackagePath `
    -destination $CimDestinationPath `
    -applyACLs `
    -create `
    -fileType cim `
    -rootDirectory apps


#######################################
#    MSIX App Attach - VHDX Format    #
#######################################
& 'C:\temp\AVD App Attach\MSIXMgr\msixmgr.exe' `
    -Unpack `
    -packagePath $PackagePath `
    -destination $VhdxDestinationPath `
    -applyACLs `
    -create `
    -fileType vhdx `
    -rootDirectory apps


