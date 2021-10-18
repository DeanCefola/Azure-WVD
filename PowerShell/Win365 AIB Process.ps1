#################################################
#    Windows 365 Azure Image Builder Process    #
#################################################
$rgName = 'CPC-RG'
$location = "EastUS"
$snapshotName = "Win11-365-SnapShot"
$imageName = "Win11-365-Image"
$diskname = "Win11-tempDisk"

$sourceImgVer = Get-AzGalleryImageVersion `
    -GalleryImageDefinitionName Win11Gen2 `
    -GalleryName Win365Gallery `
    -ResourceGroupName $rgName `
    -Name 11.0.0

$diskConfig = New-AzDiskConfig `
    -Location EastUS `
    -CreateOption FromImage `
    -GalleryImageReference @{Id = $sourceImgVer.Id} `
    -HyperVGeneration V2

$TempDisk = New-AzDisk -Disk $diskConfig `
    -ResourceGroupName $rgName `
    -DiskName $diskname

$NewSnapName = $snapshotName
$SnapShotCfg = New-AzSnapshotConfig `
    -SkuName Premium_LRS `
    -OsType Windows `
    -Location $location `
    -CreateOption  Copy `
    -SourceResourceId $TempDisk.Id `
    -HyperVGeneration V2

$Snap = New-AzSnapshot `
    -ResourceGroupName $rgName `
    -SnapshotName $NewSnapName `
    -Snapshot $SnapShotCfg `
    -Verbose

$imageConfig = New-AzImageConfig `
    -Location $location `
    -HyperVGeneration V2
$imageConfig = Set-AzImageOsDisk `
    -Image $imageConfig `
    -OsState Generalized `
    -OsType Windows `
    -SnapshotId $Snap.Id
New-AzImage `
    -ImageName $imageName `
    -ResourceGroupName $rgName `
    -Image $imageConfig


    