##########################
#    Script Parameters   #
##########################
Param (
        [Parameter(Mandatory=$false)] 
        [String]  $AzureCredentialAssetName = 'AzureCredential',
        [Parameter(Mandatory=$false)]
        [String] $AzureSubscriptionIdAssetName = 'AzureSubscriptionId',
        [Parameter(Mandatory=$true)]
        [String] $TagName,
        [Parameter(Mandatory=$true)]
        [String] $TagValue, 
        [Parameter(Mandatory=$true)]
        [String] $LocalAdminUser,
        [Parameter(Mandatory=$true)]
        [SecureString] $LocalAdminSecurePassword,        
        [Parameter(Mandatory=$true)]
        [String] $DomainFQDN = 'MSAzureAcademy.com',        
        [Parameter(Mandatory=$true)]
        [String] $FSLogixProfilePath = '\\MSAzureAcademy.com\CorpShares\FSLogix',
        [Parameter(Mandatory=$true)]
        [validateset('Personal','Pooled','Both')]
        [String] $PoolType
        [Parameter(Mandatory=$true)]
        [validateset('Delete','Save')]
        [String] $DeleteOption
)


################
#    Log in    #
################
[OutputType([String])]
$Cred = Get-AutomationPSCredential -Name $AzureCredentialAssetName -ErrorAction Stop
$null = Add-AzAccount -Credential $cred -ErrorAction Stop -ErrorVariable err
if($err) {
	throw $err
}
$SubId = Get-AutomationVariable -Name $AzureSubscriptionIdAssetName -ErrorAction Stop
$ContextID = (get-azcontext).Subscription.id
Set-AzContext $ContextID


##################
#    Variables   #
##################
$Alls = Get-AzResource -TagName $TagName -TagValue $TagValue
$VMs = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Compute/virtualMachines
$Disks = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Compute/disks
$Nics = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Network/networkInterfaces
IF(($PoolType) -eq 'Personal') {
    Write-Host `
    -BackgroundColor Black `
    -ForegroundColor Cyan `
    "Gathering PERSONAL Host Pools"
    $HPs = Get-AzWvdHostPool | Where-Object -Property HostPoolType -EQ $PoolType

}
IF(($PoolType) -eq 'Pooled') {
    Write-Host `
    -BackgroundColor Black `
    -ForegroundColor Cyan `
    "Gathering POOLED Host Pools"
    $HPs = Get-AzWvdHostPool | Where-Object -Property HostPoolType -EQ $PoolType
    
}
IF(($PoolType) -eq 'both') {
    Write-Host `
    -BackgroundColor Black `
    -ForegroundColor Cyan `
    "Gathering BOTH types of Pools"
    $HPs = Get-AzWvdHostPool
    
}


###############################################
#    Provision New Hosts from Updated Image   #
###############################################
foreach ($Nic in $Nics) {
    $NicName = $Nic.Name
    $NicRG = $Nic.ResourceGroupName
    $NicData = Get-AzNetworkInterface `
        -Name $NicName `
        -ResourceGroupName $NicRG `
        -Verbose
    $VnetRgName = $NicData.IpConfigurations.subnet.id.split('/')[4]
    $VnetName = $NicData.IpConfigurations.subnet.id.split('/')[8]
    $SubnetName = $NicData.IpConfigurations.subnet.id.split('/')[10]
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Cyan `
        "NIC Data for $NicName
            VNET RG     = $VnetRgName
            VNET Name   = $VnetName
            Subnet Name = $SubnetName
        "
}
#Generate NEW Pool Registration Token(s)
$Count = $VMs.Count
$TokenTime = $((get-date).ToUniversalTime().AddDays(1).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))
foreach ($HP in $HPs) {
    $HPName = $HP.Name
    $HPRG = ($HP.id).Split('/')[4]
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Magenta `
        "Generate New Registration Token for Pool - $HPName"    
    Update-AzWvdHostPool `
        -name $HPName `
        -ResourceGroupName $HPRG `
        -RegistrationInfoExpirationTime $TokenTime  `
        -RegistrationInfoRegistrationTokenOperation Update 
    $NewVMToken = (Get-AzWvdHostPool -Name $HPName -ResourceGroupName $HPRG).RegistrationInfoToken
<#
    $NewVMs = @{
        Prefix            = 'AVD'
        AdminUserName     = $LocalAdminUser
        AdminPassword     = $LocalAdminSecurePassword
        DomainFQDN        = $DomainFQDN
        Instance          = $Count
        OperatingSystem   = 'Client'
        VMSize            = 'Small'
        VnetRgName        = $VnetRgName
        VnetName          = $VnetName
        SubnetName        = $SubnetName
        ProfilePath       = $FSLogixProfilePath
        RegistrationToken = $NewVMToken
        Optimize          = 'true'
    }
    $ThisMonth = (get-date).datetime.split(',')[1]
    New-AzResourceGroupDeployment `
        -Name 'AVD New VMs'  `
        -ResourceGroupName $HPRG `
        -Mode Incremental `        
        -Tag @{Image=$ThisMonth} `
        -Verbose `
        -TemplateUri 'https://raw.githubusercontent.com/DeanCefola/Azure-WVD/master/WVDTemplates/WVD-NewHost/WVD-NewHost.json'
#>      
}
$VMTemplate = ((Get-AzWvdHostPool -Name $HPName -ResourceGroupName $HPRG).VMTemplate).replace(':'," = ").replace('"','')
$NewVMs = @{
    Domain = $VMtemplate.split(',')[0].split('=')[1]
    Offer = $VMtemplate.split(',')[1].split('=')[1]
    Publisher = $VMtemplate.split(',')[2].split('=')[1]
    SKU = $VMtemplate.split(',')[3].split('=')[1]
    customImageId = $VMtemplate.split(',')[6].split('=')[1]
    Prefix = $VMtemplate.split(',')[7].split('=')[1]
    osDiskType = $VMtemplate.split(',')[8].split('=')[1]    
    vmSize = $VMtemplate.split(',')[10].split('=')[2]
}

###################################################
#    CREATE NEW VMS based on previous VMs data    #
###################################################
#Build with ARM Tempalte 
New-AzResourceGroupDeployment

New-AzSubscriptionDeployment -TemplateUri


################################
#    Set Hosts to Drain Mode   #
################################
$ErrorActionPreference = 'SilentlyContinue'
foreach ($HP in $HPs) {
    $HPName = $HP.Name
    $HPRG = ($HP.id).Split('/')[4]
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Magenta `
        "Checking $HPName"
    $AllSessionHosts = Get-AzWvdSessionHost `
        -HostPoolName $HPName `
        -ResourceGroupName $HPRG
    foreach ($vm in $VMs) {
        foreach ($sessionHost in $AllSessionHosts | Where-Object {$_.ResourceId -eq $vm.Id}) {                
            if ($sessionHost.Name -match $HPName) {
            $sessionHostName = $sessionHost.Name
                Write-Host `
                -BackgroundColor Black `
                -ForegroundColor Green `
                "Session Host $sessionHostName FOUND in $HPName"
                If (($SessionHost.AllowNewSession) -eq $true) {
                    Write-Output "Enabling Drain Mode $sessionHostName"
                    Update-AzWvdSessionHost `
                        -ResourceGroupName $HPRG `
                        -HostPoolName $HPName `
                        -Name $sessionHost.Name.Split('/')[1] `
                        -AllowNewSession:$false
                }
                else {
                    Write-Output "Drain Mode Already On for $sessionHostName"
                }
            }               
        }
    }
}
$ErrorActionPreference = 'Continue'


##################################################################################################
#    Pause to allow time for users to log off Hosts                                              #
#NOTE:  This pause should accomadate the users log out time                                      #
#       Consider your Group Policies as well for Idle, Disconnect, timeouts, screen locks etc.   #
##################################################################################################
#Track VMs with 2 lists 
#Those you have drained and completed and those in progress
#add Testing switch to force users to log off
$UserSessions = Get-AzWvdUserSession `
    -HostPoolName $HPName `
    -ResourceGroupName $HPRG `
    -SessionHostName $sessionHost.Name.Split('/')[1]
if (($UserSessions) -eq $true) {
    Wait-Event -Timeout 120
    Write-Output "Waiting"
}
else {
Write-Output "Doing"
}
$WaitTime = 120
do {
    $WaitTime
} until ($UserSessions -eq $true)


################################
#    Remove Hosts from Pool    #
################################
$ErrorActionPreference = 'SilentlyContinue'
foreach ($HP in $HPs) {
    $HPName = $HP.Name
    $HPRG = ($HP.id).Split('/')[4]
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Magenta `
        "Checking $HPName"
    $AllSessionHosts = Get-AzWvdSessionHost `
        -HostPoolName $HPName `
        -ResourceGroupName $HPRG
    foreach ($vm in $VMs) {
        foreach ($sessionHost in $AllSessionHosts | Where-Object {$_.ResourceId -eq $vm.Id}) {                
            if ($sessionHost.Name -match $HPName) {
            $sessionHostName = $sessionHost.Name
                Write-Host `
                -BackgroundColor Black `
                -ForegroundColor Green `
                "Removiing Session Host $sessionHostName from Pool - $HPName"
                Remove-AzWvdSessionHost `
                        -ResourceGroupName $HPRG `
                        -HostPoolName $HPName `
                        -Name $sessionHost.Name.Split('/')[1]                
            }
            else {
                Write-Host `
                -BackgroundColor Black `
                -ForegroundColor Green `
                "Session Host $sessionHostName NOT FOUND in Pool - $HPName"
            }               
        }
    }
}
$ErrorActionPreference = 'Continue'


##########################
#    Delete Resources    #
##########################
foreach ($VM in $VMs) {
    $RGName = $VM.ResourceGroupName
    $VMName = $VM.Name
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Red `
        "Deleting VM $VMName"
    Remove-AzVM `
        -ResourceGroupName $RGName `
        -Name  $VMName `
        -Force `
        -Verbose
}
foreach ($Nic in $Nics) {
    $RGName = $VM.ResourceGroupName
    $NicName = $Nic.Name
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Red `
        "Deleting Nic $NicName"   
    Remove-AzNetworkInterface `
        -ResourceGroupName $RGName `
        -Name  $NicName `
        -Force `
        -Verbose
}
foreach ($Disk in $Disks) {
    $RGName = $VM.ResourceGroupName
    $DiskName = $Disk.Name
    Write-Host `
        -BackgroundColor Black `
        -ForegroundColor Red `
        "Deleting Disk $DiskName"    
    Remove-AzDisk `
        -DiskName $DiskName `
        -ResourceGroupName $RGName `
        -Force `
        -Verbose
}


