
<# 
 .Synopsis
    Prepare to deploy Windows Virtual Desktop Environment

 .Description
    Install WVD PowerShell Modules, 
    Create WVD Resourceses:
        WVD Tenant, 
        HostPool, 
        WVD Permissions,
        First App Group,
        App Group Permissions

 .Parameter AADTenantID
    Azure Active Directory Tenant ID
        AAD Portal, Properties Copy ID

 .Parameter SubscriptionID
    Azure Subscription ID 

 .Parameter AzureADGlobalAdmin
    Azure AD Global Admin user name

 .Parameter AzureADDomainName
    Azure AD Domain Name, i.e. MSAzureAcademy.com

 .Parameter WVDTenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter WVDTenantGroup
    Tenant Group name, by default the first group is called ''

 .Parameter WVDHostPoolName
    Name of the Windows Virtual Desktop Host Pool

 .Parameter FirstAppGroupName
    Enter the name of the App Group for your Remote Applications

 .Example    
     # Create new Windows Virtual Desktop Deployment
    New-AzureWVDPrep `
        -AADTenantID xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx `
        -SubscriptionID 00000000-0000-0000-0000-000000000000 `
        -AzureADGlobalAdmin WVDAdmin `
        -AzureADDomainName MSAzureAcademy.com `
        -WVDTenantName MSAA-Tenant `
        -WVDTenantGroup 'Default Tenant Group' `
        -WVDHostPoolName MSAA-HostPool

#>


###########################
#    General Variables    #
###########################                 
$AADTenantID = 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'
$SubscriptionID = 'yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy'
$WVDTenantName = 'MSAA-Tenant'
$WVDTenantGroup = 'Default Tenant Group'
$WVDHostPoolName = 'MSAA-HostPool'
$FirstAppGroupName = 'MSAA-WVD'
$AzureADGlobalAdmin = 'WVD'
$AzureADDomainName = 'MSAzureAcademy.com'
$FQDN = "$AzureADGlobalAdmin@$AzureADDomainName"


###########################################
#    Install PowerShell Module for WVD    #
###########################################
$Module = 'Microsoft.RDInfra.RDPowerShell'
if((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        if((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"        
            Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue

        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
    }
else {
        Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
    }
Add-RdsAccount `
    -DeploymentUrl “https://rdbroker.wvd.microsoft.com”


###############################
#    Create New WVD Tenant    #
###############################
New-RDSTenant `
    -Name $WVDTenantName `
    -AadTenantId $AADTenantID `
    -AzureSubscriptionId $SubscriptionID 
New-RdsHostPool `
    -TenantName $WVDTenantName `
    -Name $WVDHostPoolName `
    -FriendlyName $WVDHostPoolName
New-RdsRoleAssignment `
    -RoleDefinitionName 'RDS Owner' `
    -SignInName $FQDN `
    -TenantGroupName $WVDTenantGroup `
    -TenantName $WVDTenantName `
    -HostPoolName $WVDHostPoolName `
    -AADTenantId $AADTenantID `
    -AppGroupName 'Desktop Application Group' `
    -Verbose


#######################################
#    Create New Application Groups    #
#######################################
New-RdsAppGroup `
    -TenantName $WVDTenantName `
    -HostPoolName $WVDHostPoolName `
    -Name $FirstAppGroupName `
    -ResourceType RemoteApp `
    -Verbose
Add-RdsAppGroupUser `
    -TenantName $WVDTenantName `
    -HostPoolName $WVDHostPoolName `
    -UserPrincipalName $FQDN `
    -AppGroupName $FirstAppGroupName   





#######################
#    Setup WVD Apps   #
#######################   
$RemoteApps = @(
    @{AppGroupName = 'MSAA-WVD'; FilePath = '7zFM.exe'}    
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'Calc.exe'}    
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'Code.exe'}
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'FoxITReader.exe'}
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'HandBrake.exe'}
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'Paint.net'}
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'Putty.exe'}       
    @{AppGroupName = 'MSAA-WVD'; FilePath = 'WinRar'}
)        
foreach ($App in $RemoteApps) {
    Get-RdsStartMenuApp `
        -TenantName $WVDTenantName `
        -HostPoolName $WVDHostPoolName `
        -AppGroupName $App.AppGroupName `
            | ? FilePath -Match $App.FilePath `
            -OutVariable NewApp
           
    New-RdsRemoteApp `
        -TenantName $WVDTenantName `
        -HostPoolName $WVDHostPoolName `
        -AppGroupName $App.AppGroupName `
        -Name $NewApp.FriendlyName `
        -Filepath $NewApp.filepath  `
        -IconPath $NewApp.iconpath `
        -IconIndex $NewApp.iconindex
}


######################
#    WVD Clean Up    #
######################   
Function Remove-AzureWVD {
<# 
 .Synopsis
    Clean up and remove WVD

 .Description
    Remove in order 
        Applications,
        App users,
        App Group,
        Session Hosts,
        Host Pools
        Tenant
         
 .Parameter WVDTenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter WVDHostPoolName
    Name of the Windows Virtual Desktop Host Pool

 .Example    
     # Clean up WVD
    Remove-AzureWVD `        
        -WVDTenantName MSAA-Tenant `        
        -WVDHostPoolName MSAA-HostPool

#>
[Cmdletbinding()]
Param (    
    [Parameter(Mandatory=$true)]
        [string]$WVDTenantName,    
    [Parameter(Mandatory=$true)]
        [string]$WVDHostPoolName
)

Begin {
    Write-Host `
        -ForegroundColor Magenta `
        -BackgroundColor Black `
        "Preparing to DELETE WVD in 5 Seconds"
    Wait-Event -Timeout 2
    Write-Host -ForegroundColor Red -BackgroundColor Black "5"
    Wait-Event -Timeout 1
    Write-Host -ForegroundColor Red -BackgroundColor Black "4"
    Wait-Event -Timeout 1
    Write-Host -ForegroundColor Red -BackgroundColor Black "3"
    Wait-Event -Timeout 1
    Write-Host -ForegroundColor Red -BackgroundColor Black "2"
    Wait-Event -Timeout 1
    Write-Host -ForegroundColor Red -BackgroundColor Black "1"
    Wait-Event -Timeout 1
    Write-Host -ForegroundColor Red -BackgroundColor Black "Now Removing WVD..."
}

Process {
    $AppGroup = Get-RdsAppGroup `
        -TenantName $WVDTenantName `
        -HostPoolName $WVDHostPoolName `
        | ? -Property AppGroupName `
            -NE 'Desktop Application Group' `
            -ErrorAction SilentlyContinue
    foreach ($APG in $AppGroup) {        
        Get-RdsRemoteApp `
            -TenantName $WVDTenantName `
            -HostPoolName $WVDHostPoolName `
            -AppGroupName $APG.AppGroupName `
            | Remove-RdsRemoteApp
        Get-RdsAppGroupUser `
            -TenantName $WVDTenantName `
            -HostPoolName $WVDHostPoolName `
            -AppGroupName $APG.AppGroupName `
            | Remove-RdsAppGroupUser        
        $APG | Remove-RdsAppGroup 
        Remove-RdsAppGroup `
            -TenantName $WVDTenantName `
            -HostPoolName $WVDHostPoolName `
            -Name 'Desktop Application Group'
    }     
    Get-RdsSessionHost `
        -TenantName $WVDTenantName `
        -HostPoolName $WVDHostPoolName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsSessionHost
    Get-RdsHostPool `
        -TenantName $WVDTenantName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsHostPool
    Get-RdsTenant `
        -Name $WVDTenantName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsTenant 

}

End {    
    Write-Host "Tenant " -NoNewline; `
    Write-Host $WVDTenantName -ForegroundColor Red -NoNewline; `
    Write-Host " has been removed" -NoNewline;   
   
}

}

<#
Remove-AzureWVD `
    -WVDTenantName $WVDTenantName `
    -WVDHostPoolName $WVDHostPoolName `
    -Verbose

    #>

