################
#    Prereqs   #
################
<#
    Tags
    Image Version (Shared Image Gallery)
    Host Pools
    Automation Account
        Az modules: Az.Accounts, Az.Automation, Az.ManagedServiceIdentity, Az.Compute, and Az.DesktopVirtualization 
        imported into the Automation account
        Manage identity for automation account
        Set fx variables    
    (Logic App)
    (DevOps Pipeline)    
        check you are registered for the providers, ensure RegistrationState is set to 'Registered'.
        Get-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
        Get-AzResourceProvider -ProviderNamespace Microsoft.Storage
        Get-AzResourceProvider -ProviderNamespace Microsoft.Compute
        Get-AzResourceProvider -ProviderNamespace Microsoft.KeyVault# If they do not show as registered, run the commented out code below.## Register-AzResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
        ## Register-AzResourceProvider -ProviderNamespace Microsoft.Storage
        ## Register-AzResourceProvider -ProviderNamespace Microsoft.Compute
        ## Register-AzResourceProvider -ProviderNamespace Microsoft.KeyVault
#>

##########################
#    Script Parameters   #
##########################
Param (
        [Parameter(Mandatory=$true)]
        [String] $TagName,
        [Parameter(Mandatory=$true)]
        [String] $TagValue, 
        [Parameter(Mandatory=$true)]
        [validateset('Personal','Pooled','Both','Single')]
        [String] $PoolType,
        [Parameter(Mandatory=$false)]        
        [String] $SinglePoolName,
        [Parameter(Mandatory=$false)]        
        [String] $PoolResourceGroupName,
        [Parameter(Mandatory=$true)]        
        [String] $AAResourceGroup =  'MSAA-WVDMgt',
        [Parameter(Mandatory=$true)]        
        [String] $AAName = 'MSAA-WVDAutoScale',
        [Parameter(Mandatory=$true)]        
        [String] $ImageID = '/subscriptions/17a60df3-f02e-43a2-b52b-11abb3a53049/resourceGroups/CPC-RG/providers/Microsoft.Compute/galleries/Win365Gallery/images/W365-Ent/versions/21.1.0'        
)

################
#    Log in    #
################
[OutputType([String])]
$AzureContext = (Connect-AzAccount -Identity).context
$AzureContext = Set-AzContext -SubscriptionName $AzureContext.Subscription -DefaultProfile $AzureContext
Import-Module Orchestrator.AssetManagement.Cmdlets -ErrorAction SilentlyContinue


##################
#    Variables   #
##################
$DomainFQDN = (Get-AzAutomationVariable -Name DomainName -resourcegroupname $AAResourceGroup -AutomationAccountName $AAName).Value
$FSLogixProfilePath = (Get-AzAutomationVariable -Name FSLogixPath -resourcegroupname $AAResourceGroup -AutomationAccountName $AAName).Value
$AACreds = (Get-AutomationPSCredential -Name 'adjoin')
$DomainCreds = New-Object System.Management.Automation.PSCredential ($AACreds.UserName, $AACreds.GetNetworkCredentials().Password)


################################
#    Discover TAG Resources    #
################################
$Alls = Get-AzResource -TagName $TagName -TagValue $TagValue
$VMs = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Compute/virtualMachines
$Disks = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Compute/disks
$Nics = Get-AzResource -TagName $TagName -TagValue $TagValue `
    | Where-Object -Property ResourceType -EQ Microsoft.Network/networkInterfaces


########################
#    Get Pools Info    #
########################
switch ($PoolType) {
    Personal {
        Write-Output "Gathering PERSONAL Host Pools"
        $HPs = Get-AzWvdHostPool | Where-Object -Property HostPoolType -EQ $PoolType
    }
    Pooled {
        Write-Output "Gathering POOLED Host Pools"
        $HPs = Get-AzWvdHostPool | Where-Object -Property HostPoolType -EQ $PoolType
    }
    Both {
        Write-Output "Gathering BOTH types of Pools"
        $HPs = Get-AzWvdHostPool
    }
    Single {
        Write-Output "Gathering Hosts from "$SinglePoolName
        $HPs = Get-AzWvdHostPool -name $SinglePoolName -ResourceGroupName $PoolResourceGroupName
    }
}


################################
#    Set Hosts to Drain Mode   #
################################
$InactiveHosts = @()
$ErrorActionPreference = 'SilentlyContinue'
foreach ($HP in $HPs) {
    $HPName = $HP.Name
    $HPRG = ($HP.id).Split('/')[4]
    Write-Output "Checking $HPName"
    $AllSessionHosts = Get-AzWvdSessionHost `
        -HostPoolName $HPName `
        -ResourceGroupName $HPRG
    foreach ($vm in $VMs) {
        foreach ($sessionHost in $AllSessionHosts | Where-Object {$_.ResourceId -eq $vm.Id}) {
            $userSessions = Get-AzWvdUserSession -ResourceGroupName $HPRG -HostPoolName $HP -SessionHostName $sessionHost.Name.Split('/')[1]
            if ($null -eq $userSessions)  {
                $InactiveHosts += $vm
            }
            if ($sessionHost.Name -match $HPName) {
            $sessionHostName = $sessionHost.Name
                Write-Output "Session Host $sessionHostName FOUND in $HPName"
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




################################
# Check for host with sessions #
################################

#Write Foreach Loop

#########################
#    Deallocate Hosts    #
#########################

foreach ($inactiveHost in $inactiveHosts) {
    Stop-AzVm -Name $inactiveHost.Name -ResourceGroupName $inactiveHost.ResourceGroupName -NoWait -Force 
    [string]$newDiskName = $inactiveHost.Name+"-OSDisk-"+(Get-Date -Format d-M-y)
    $newDiskCfg = New-AzDiskConfig -Location $inactiveHost.Location -CreateOption FromImage -GalleryImageReference @{Id = $ImageID}
    $newDisk = New-AzDisk -DiskName $newDiskName -Disk $newDiskCfg -ResourceGroupName $InactiveHost.StorageProfile.OsDisk.ManagedDisk.Id.Split("/")[4]
    
    $vmStatusCounter = 0
    while ($vmStatusCounter -lt 12)
    {
        $vmStatus = (Get-AzVM -Name $inactiveHost.Name -ResourceGroupName $inactiveHost.ResourceGroupName -Status).Statuses[1].Code.Split("/")[1]
        if ($vmStatus -eq "deallocated")
        {
            break
        }
        $vmStatusCounter++
        Start-Sleep -Seconds 5s
    }

    Set-AzVMOSDisk -VM $inactiveHost -ManagedDiskId $newDisk.Id
    Update-AzVM -ResourceGroupName $inactiveHost.ResourceGroupName -VM $inactiveHost
    Start-AzVM -ResourceGroupName $inactiveHost.ResourceGroupName $inactiveHost.ResourceGroupName -NoWait
}

##########################################
#    Provision New OSDisks from Image    #
##########################################
$diskConfig = New-AzDiskConfig `
   -Location EastUS `
   -CreateOption FromImage `
   -GalleryImageReference @{Id = $ImageID}

New-AzDisk -Disk $diskConfig `
   -ResourceGroupName $RGName `
   -DiskName $NewVMName


######################
#    OS Disk Swap    #
######################
$vm = Get-AzVM -ResourceGroupName $RGName -Name $VMName
$disk = Get-AzDisk -ResourceGroupName $RGName -Name $NewVMName
Set-AzVMOSDisk -VM $vm -ManagedDiskId $disk.Id -Name $disk.Name 
Update-AzVM -ResourceGroupName $RGName -VM $vm 


###################
#    Rename VMs    #
###################
Get-AZVM -name $VMName | Start-AzVM
Invoke-AzVMRunCommand `
    -ResourceGroupName $RGName `
    -Name $VMName `
    -CommandId 'RunPowerShellScript' `
    -ScriptPath 'https://raw.githubusercontent.com/DeanCefola/Azure-WVD/master/PowerShell/RenameComputer.ps1' `
    -Parameter @{"VMName" = "$VMName"}


######################################
#    Remove Join Domain Extension    #
######################################
(get-AzVMExtension `
    -ResourceGroupName $RGName `
    -VMName $VMName) | `
    Where-Object `
        -Property Name `
        -match domain | `
        Remove-AzVMExtension `
            -Force `
            -Verbose



########################################
#    Remove Custom Script Extension    #
########################################
(get-AzVMExtension `
    -ResourceGroupName $RGName `
    -VMName $VMName) | `
    Where-Object `
        -Property ExtensionType `
        -match CustomScriptExtension | `
        Remove-AzVMExtension `
            -Force `
            -Verbose


#####################
#    Join Domain    #
#####################
Set-AzVMADDomainExtension `
    -TypeHandlerVersion 1.3 `
    -DomainName $DomainFQDN `
    -VMName $VMName `
    -ResourceGroupName $RGName `
    -Location (get-azresourcegroup -name $RGName).location `
    -Credential $DomainCreds `
    -JoinOption "0x00000003" `
    -Restart `
    -Verbose


#######################
#    Join HostPool    #
#######################
Set-AzVMCustomScriptExtension `
    -ResourceGroupName $RGName `
    -VMName $VMName `
    -Location (get-azresourcegroup -name $RGName).location `
    -FileUri "https://raw.githubusercontent.com/DeanCefola/Azure-WVD/master/PowerShell/New-WVDSessionHost.ps1" `
    -Run "New-WVDSessionHost.ps1" `
    -Name AVDImageExtension `
    -Argument "$FSLogixProfilePath $Token"


    