########################################
#    1 MSIX to App Attach Migration    #
########################################
$parameters = @{
    HostPoolName = '<HostPoolName>'
    ResourceGroupName = '<ResourceGroupName>'
}

$msixPackage = Get-AzWvdMsixPackage @parameters | ? Name -Match 'MSIX-HP/NotePadPlus_8.5.8.0_x64__gyjvz5nnfka48'
$hostPoolId = (Get-AzWvdHostPool @parameters).Id


$parameters = @{
    PermissionSource = 'RAG'
    HostPoolsForNewPackage = $hostPoolId
    PassThru = $true
}

$msixPackage | .\Migrate-MsixPackagesToAppAttach.ps1 @parameters




##########################################
#    All MSIX to App Attach Migration    #
##########################################
$parameters = @{
    HostPoolName = 'MSIX-HP'
    ResourceGroupName = 'Cloud-VDI'
}

$msixPackages = Get-AzWvdMsixPackage @parameters
$hostPoolId = (Get-AzWvdHostPool @parameters).Id
$logFilePath = "$HOME/MsixToAppAttach.log"

$parameters = @{
    IsActive = $true
    DeactivateOrigin = $true
    PermissionSource = 'DAG'
    HostPoolsForNewPackage = $hostPoolId
    PassThru = $true
    LogInJSON = $true
    LogFilePath = $LogFilePath
}

$msixPackages | .\Migrate-MsixPackagesToAppAttach.ps1 @parameters