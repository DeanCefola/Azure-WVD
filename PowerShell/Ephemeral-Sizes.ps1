[CmdletBinding()]
param([Parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [string]$Location,
      [Parameter(Mandatory=$true)]
      [long]$OSImageSizeInGB
      )
 
Function HasSupportEphemeralOSDisk([object[]] $capability)
{
    return $capability | where { $_.Name -eq "EphemeralOSDiskSupported" -and $_.Value -eq "True"}
}
 
Function Get-MaxTempDiskAndCacheSize([object[]] $capabilities)
{
    $MaxResourceVolumeGB = 0;
    $CachedDiskGB = 0;
    $NvmeDiskGB = 0;
 
    foreach($capability in $capabilities)
    {
        if ($capability.Name -eq "MaxResourceVolumeMB")
        { $MaxResourceVolumeGB = [int]($capability.Value / 1024) }
 
        if ($capability.Name -eq "CachedDiskBytes")
        { $CachedDiskGB = [int]($capability.Value / (1024 * 1024 * 1024)) }

if ($capability.Name -eq "NvmeDiskSizeInMiB")
        { $NvmeDiskGB = [int]($capability.Value / (1024)) }

if ($capability.Name -eq "SupportedEphemeralOSDiskPlacements")
        { $NvmeSupported = [bool]($capability.Value -contains "NvmeDisk") }
    
    }
    
    if (!$NvmeSupported)
    { $NvmeDiskGB = 0; }
    return ($MaxResourceVolumeGB, $CachedDiskGB, $NvmeDiskGB)
}
 
Function Get-EphemeralSupportedVMSku
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true)]
        [long]$OSImageSizeInGB,
        [Parameter(Mandatory=$true)]
        [string]$Location
    )
 
    $VmSkus = Get-AzComputeResourceSku $Location | Where-Object { $_.ResourceType -eq "virtualMachines" -and (HasSupportEphemeralOSDisk $_.Capabilities) -ne $null }
 
    $Response = @()
    foreach ($sku in $VmSkus)
    {
        ($MaxResourceVolumeGB, $CachedDiskGB, $NvmeDiskGB) = Get-MaxTempDiskAndCacheSize $sku.Capabilities
 
        $Response += New-Object PSObject -Property @{
            ResourceSKU = $sku.Size
            NvmeDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$NvmeDiskGB -lt $OSImageSizeInGB]
            TempDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$MaxResourceVolumeGB -lt $OSImageSizeInGB]
            CacheDiskPlacement = @{ $true = "NOT SUPPORTED"; $false = "SUPPORTED"}[$CachedDiskGB -lt $OSImageSizeInGB]
         };
    }
 
    return $Response
}
 
Get-EphemeralSupportedVMSku -OSImageSizeInGB $OSImageSizeInGB -Location $Location | Format-Table