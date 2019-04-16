<#Author       : Dean Cefola
# Creation Date: 03-28-2019
# Usage        : Windows Virtual Desktop Functions

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 03/28/2019                     1.0        Intial Version
# 04/01/2019                     1.1        Add Set-AzureWVDLBType
# 04/04/2019                     1.2        Change Add-RDSAccount to IF/Else
# 04/16/2019                     1.3        Add TenantAdmin Creds variable for Authentication

#*********************************************************************************
#
#>


########################
#     WVD Functions    #
########################
Function Add-AzureWVDAppGroupUsers {
<# 
 .Synopsis
    Add all Synced Users in Azure AD to WVD Remote App Group

 .Description
    Discover all synced Azure AD users except the WVD Tenant Admin into the remote app group
         
 .Parameter TenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter HostPoolName
    Name of the Windows Virtual Desktop Host Pool

.Parameter RemoteAppGroup   
    Provide the .exe name of the Application(s) you have installed on the SessionHost

.Parameter TenantAdmin
    User Account that is the Tenant Admin, who has permissions to add users to App groups

 .Example    
     # Map Windows Virtual Desktop Apps to your Start Menu
    Add-AzureWVDAppGroupUsers `        
        -TenantName MSAA-Tenant `        
        -HostPoolName MSAA-HostPool `
        -RemoteAppGroup RemoteAppGroup `
        -TenantAdmin WVD@Contoso.com

#>
[Cmdletbinding()]
Param (    
    [Parameter(Mandatory=$true)]
        [string]$TenantAdmin,
    [Parameter(Mandatory=$true)]
        [string]$TenantName,    
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName,
    [Parameter(Mandatory=$true)]
        [string]$RemoteAppGroup
)

Begin {
    ###########################################
    #    Install PowerShell Module for WVD    #
    ###########################################
    $Module = 'Microsoft.RDInfra.RDPowerShell'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose
            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }
    ""
    $RDSContext = Get-RdsContext -ErrorAction SilentlyContinue
    IF(($RDSContext) -eq $null) {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Beginning RDS Authentication"
        Wait-Event -Timeout 2
        $creds = Get-Credential `
            -UserName $TenantAdmin `
            -Message "Enter Password for WVD Tenant Credentials"
        Add-RdsAccount "https://rdbroker.wvd.microsoft.com" `
            -Credential $creds
        Set-RdsContext `
            -TenantGroupName 'Default Tenant Group'
    }
    Else {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "RDS Authentication was alreay complete "
        ""
        Write-Host "Beginning WVD Start Menu process" -NoNewline
    }
    ""
    $Module = 'AzureAD'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\AzureAD" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Azure AD Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose
            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Azure AD Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }
    ""
    $AzureAD = Get-AzureADDomain -ErrorAction SilentlyContinue
    IF(($AzureAD) -eq $null) {
        Write-Host `
            -ForegroundColor Red `
            -BackgroundColor Black `
            "Authentication required for Azure AD"
        Wait-Event -Timeout 2
        ""
        $Credential = Get-Credential
        Connect-AzureAD -Credential $Credential        
    }
    Else {
        Write-Host `
            -ForegroundColor Green `
            -BackgroundColor Black `
            "Azure AD authentication complete...processing request"

    }
    ""


    $AzureADGlobalAdmin =$TenantAdmin.Split('@')[0]
    $AzureADDomainName = $TenantAdmin.Split('@')[1]
}

Process {   
    ########################################################
    #    Get Azure AD Users and Populate RemoteAppGroup    # 
    ########################################################
   $Users = Get-AzureADUser `
        | Where-Object -Property UserPrincipalName -Match $AzureADDomainName `
        | Where-Object -Property UserPrincipalName -NotMatch $AzureADGlobalAdmin
    foreach ($u in $Users) {
        Add-RdsAppGroupUser `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -AppGroupName $RemoteAppGroup `
            -UserPrincipalName $U.UserPrincipalName `
            -ErrorAction SilentlyContinue `
            -Verbose 
}

}

End {
   
}

}

Function New-AzureWVDPrep {
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

 .Parameter TenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter TenantGroup
    Tenant Group name, by default the first group is called ''

 .Parameter HostPoolName
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
        -TenantName My-Tenant `
        -TenantGroup 'Default Tenant Group' `
        -HostPoolName My-HostPool `
        -FirstAppGroupName MyRemoteApps `

#>
[Cmdletbinding()]
Param (
    [Parameter(Mandatory=$true)]
        [string]$AADTenantID,
    [Parameter(Mandatory=$true)]
        [string]$SubscriptionID,
    [Parameter(Mandatory=$true)]
        [string]$TenantAdmin,
    [Parameter(Mandatory=$false)]
        [string]$TenantGroup = 'Default Tenant Group',
    [Parameter(Mandatory=$true)]
        [string]$TenantName,
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName,
    [Parameter(Mandatory=$true)]
        [string]$FirstAppGroupName
)

Begin {
    ###########################################
    #    Install PowerShell Module for WVD    #
    ###########################################
    $Module = 'Microsoft.RDInfra.RDPowerShell'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose                

            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }
    ""
    $RDSContext = Get-RdsContext -ErrorAction SilentlyContinue
    IF(($RDSContext) -eq $null) {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Beginning RDS Authentication"
        Wait-Event -Timeout 2
        $creds = Get-Credential `
            -UserName $TenantAdmin `
            -Message "Enter Password for WVD Tenant Credentials"
        Add-RdsAccount "https://rdbroker.wvd.microsoft.com" `
            -Credential $creds
        Set-RdsContext `
            -TenantGroupName 'Default Tenant Group'
    }
    Else {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "RDS Authentication was alreay complete "
        ""
        Write-Host "Beginning WVD Creation of " -NoNewline
        Write-Host -ForegroundColor Cyan -BackgroundColor Black $TenantName -NoNewline
    }

}

Process {   
    ###############################
    #    Create New WVD Tenant    #
    ###############################
    New-RDSTenant `
        -Name $TenantName `
        -AadTenantId $AADTenantID `
        -AzureSubscriptionId $SubscriptionID 
    New-RdsHostPool `
        -TenantName $TenantName `
        -Name $HostPoolName `
        -FriendlyName $HostPoolName
    New-RdsRoleAssignment `
        -RoleDefinitionName 'RDS Owner' `
        -SignInName $TenantAdmin `
        -TenantGroupName $TenantGroup `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -AADTenantId $AADTenantID `
        -AppGroupName 'Desktop Application Group' `
        -Verbose
    $User = Get-RdsAppGroupUser -TenantName $TenantName -HostPoolName $HostPoolName -AppGroupName 'Desktop Application Group'
    foreach ($U in $User) {
        If(($U)-match $TenantAdmin) {            
            Write-Host "User " -NoNewline; `
            Write-Host $TenantAdmin -ForegroundColor Red -NoNewline; `
            Write-Host " is already present in the 'Desktop Application Group'" -NoNewline;   
        }
        Else {
            write "Adding User $TenantAdmin"
            Add-RdsAppGroupUser `
                -TenantName $TenantName `
                -HostPoolName $HostPoolName `
                -UserPrincipalName $TenantAdmin `
                -AppGroupName 'Desktop Application Group'  
        }
        
    }


    #######################################
    #    Create New Application Groups    #
    #######################################
    New-RdsAppGroup `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -Name $FirstAppGroupName `
        -ResourceType RemoteApp `
        -Verbose
    Wait-Event -Timeout 5
    Add-RdsAppGroupUser `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -UserPrincipalName $TenantAdmin `
        -AppGroupName $FirstAppGroupName  
}

End {   
    $AppGroup = Get-RdsAppGroup `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -ErrorAction SilentlyContinue
    $Names = $AppGroup.AppgroupName    
    foreach ($Name in $Names) {
        Write-Host `
            -ForegroundColor Cyan `
            -BackgroundColor Black `
            "AppGroup - $Name Created"
    }

}

}
    
Function New-AzureWVDApps {
<# 
 .Synopsis
    Create Start Menu Applications for WVD

 .Description
    Take Apps installed on the Session Host Servers & map them to your Start Menu
         
 .Parameter TenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter HostPoolName
    Name of the Windows Virtual Desktop Host Pool

.Parameter RemoteApps    
    Provide the .exe name of the Application(s) you have installed on the SessionHost

 .Example    
     # Map Windows Virtual Desktop Apps to your Start Menu
    New-AzureWVDApps `        
        -TenantName MSAA-Tenant `        
        -HostPoolName MSAA-HostPool `
        -RemoteApps $RemoteApps

#>
[Cmdletbinding()]
Param (    
    [Parameter(Mandatory=$true)]
        [string]$TenantAdmin,
    [Parameter(Mandatory=$true)]
        [string]$TenantName,    
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName,
    [Parameter(Mandatory=$true)]
        [string]$RemoteApps
    
)

Begin {
    ###########################################
    #    Install PowerShell Module for WVD    #
    ###########################################
    $Module = 'Microsoft.RDInfra.RDPowerShell'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose
            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }
    ""
    $RDSContext = Get-RdsContext -ErrorAction SilentlyContinue
    IF(($RDSContext) -eq $null) {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Beginning RDS Authentication"
        Wait-Event -Timeout 2
        $creds = Get-Credential `
            -UserName $TenantAdmin `
            -Message "Enter Password for WVD Tenant Credentials"
        Add-RdsAccount "https://rdbroker.wvd.microsoft.com" `
            -Credential $creds
        Set-RdsContext `
            -TenantGroupName 'Default Tenant Group'
    }
    Else {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "RDS Authentication was alreay complete "
        ""
        Write-Host "Beginning WVD Start Menu process" -NoNewline
    }
    ""
}

Process {   
    ########################################################
    #   Get Install App Data to create Start Menu Items    # 
    ########################################################
    $RemoteApps = @(
        @{AppGroupName = 'MSAA-WVD'; FilePath = '7zFM.exe'}    
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'Calc.exe'}    
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'Code.exe'}
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'FoxITReader.exe'}
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'HandBrake.exe'}
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'Paint.net'}
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'Putty.exe'}
       # @{AppGroupName = 'MSAA-WVD'; FilePath = 'VLC.exe'}
        @{AppGroupName = 'MSAA-WVD'; FilePath = 'WinRar'}
    )        
    foreach ($App in $RemoteApps) {
        Get-RdsStartMenuApp `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -AppGroupName $App.AppGroupName `
                | ? FilePath -Match $App.FilePath `
                -OutVariable NewApp
           
        New-RdsRemoteApp `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -AppGroupName $App.AppGroupName `
            -Name $NewApp.FriendlyName `
            -Filepath $NewApp.filepath  `
            -IconPath $NewApp.iconpath `
            -IconIndex $NewApp.iconindex
    }

}

End {
   
}

}

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
         
 .Parameter TenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter HostPoolName
    Name of the Windows Virtual Desktop Host Pool

 .Example    
     # Clean up WVD
    Remove-AzureWVD `        
        -TenantName MSAA-Tenant `        
        -HostPoolName MSAA-HostPool

#>
[Cmdletbinding()]
Param (    
    [Parameter(Mandatory=$true)]
        [string]$TenantAdmin,
    [Parameter(Mandatory=$true)]
        [string]$TenantName,    
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName
    
)

Begin {
    ###########################################
    #    Install PowerShell Module for WVD    #
    ###########################################
    $Module = 'Microsoft.RDInfra.RDPowerShell'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose
            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }
    ""
    $RDSContext = Get-RdsContext -ErrorAction SilentlyContinue
    IF(($RDSContext) -eq $null) {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Beginning RDS Authentication"
        Wait-Event -Timeout 2
        $creds = Get-Credential `
            -UserName $TenantName `
            -Message "Enter Password for WVD Tenant Credentials"
        Add-RdsAccount "https://rdbroker.wvd.microsoft.com" `
            -Credential $creds
        Set-RdsContext `
            -TenantGroupName 'Default Tenant Group'
    }
    Else {
        Write-Host `
            -ForegroundColor Yellow `
            -BackgroundColor Black `
            "RDS Authentication was alreay complete "
        ""
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
        ""
    }
}

Process {
    $AppGroup = Get-RdsAppGroup `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        | ? -Property AppGroupName `
            -NE 'Desktop Application Group' `
            -ErrorAction SilentlyContinue
    foreach ($APG in $AppGroup) {        
        Get-RdsRemoteApp `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -AppGroupName $APG.AppGroupName `
            | Remove-RdsRemoteApp
        Get-RdsAppGroupUser `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -AppGroupName $APG.AppGroupName `
            | Remove-RdsAppGroupUser        
        $APG | Remove-RdsAppGroup 
        Remove-RdsAppGroup `
            -TenantName $TenantName `
            -HostPoolName $HostPoolName `
            -Name 'Desktop Application Group'
    }     
    Get-RdsSessionHost `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsSessionHost
    Get-RdsHostPool `
        -TenantName $TenantName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsHostPool
    Get-RdsTenant `
        -Name $TenantName `
        -ErrorAction SilentlyContinue `
        | Remove-RdsTenant 

}

End {    
    Write-Host "Tenant " -NoNewline; `
    Write-Host $TenantName -ForegroundColor Red -NoNewline; `
    Write-Host " has been removed" -NoNewline;   
   
}

}

Function Set-AzureWVDLBType {
<# 
 .Synopsis
    Change Load Balancing Pattern & Session Limit

 .Description
    Configure Load Balancing Pattern & Number of connections per session host
         
 .Parameter TenantName
    Name of the Windows Virtual Desktop Tenant

 .Parameter HostPoolName
    Name of the Windows Virtual Desktop Host Pool

 .Parameter LoadBalancerType
    Switch for Depth or Breadth

 .Parameter MaxSessionLimit
    Number of connections to enable

 .Example    
    # Change WVD Load Balancing Config
    Set-AzureWVDLoadBalancing  `
        -TenantName $TenantName `
        -HostPoolName $HostPoolName `
        -LoadBalancerType Depth `
        -MaxSessionLimit 10


#>
[Cmdletbinding()]
Param (    
    [Parameter(Mandatory=$true)]
        [string]$TenantAdmin,
    [Parameter(Mandatory=$true)]
        [string]$TenantName,    
    [Parameter(Mandatory=$true)]
        [string]$HostPoolName,
     [Parameter(Mandatory=$true)]
        [validateset('Breadth','Depth')]
        [string]$LoadBalancerType,
     [Parameter(Mandatory=$true)]
        [int]$MaxSessionLimit
    
)

Begin {
    ###########################################
    #    Install PowerShell Module for WVD    #
    ###########################################
    $Module = 'Microsoft.RDInfra.RDPowerShell'
    IF((Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\$Module" -ErrorAction SilentlyContinue)-eq $true) {
        IF((Get-Module -Name $Module -ErrorAction SilentlyContinue) -eq $false) {
            Write-Host `
                -ForegroundColor Cyan `
                -BackgroundColor Black `
                "Importing Module"
            $NUget = Get-PackageProvider | Where-Object -Property Name -EQ NuGet
            If(($Nuget) -eq $null) {
                Write-Host "Installing Package Provider - " -NoNewline
                Write-Host -ForegroundColor Yellow -BackgroundColor Black "NuGet" -NoNewline
                install-packageprovider -Name NuGet -MinimumVersion 2.8.5.208 -Force -Verbose
            }
            Else {
                Import-Module -Name $Module -Verbose -ErrorAction SilentlyContinue
            }
        }
        Else {
            Write-Host `
                -ForegroundColor Yellow `
                -BackgroundColor Black `
                "Module already imported"        
        }
        }
    Else {
            Install-Module -Name $Module -Force -Verbose -ErrorAction Stop    
        }    
    $RDSContext = Get-RdsContext -ErrorAction SilentlyContinue
    IF(($RDSContext) -eq $null) {
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "Beginning RDS Authentication"
        Wait-Event -Timeout 2
        $creds = Get-Credential `
            -UserName $TenantAdmin `
            -Message "Enter Password for WVD Tenant Credentials"
        Add-RdsAccount "https://rdbroker.wvd.microsoft.com" `
            -Credential $creds
        Set-RdsContext `
            -TenantGroupName 'Default Tenant Group'
    }
    Else {
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "RDS Authentication was alreay complete "               
    }
    ""       
    $Array = @(
        @{input = 'Breadth' ; type = '-BreadthFirstLoadBalancer'}
        @{input = 'Depth' ; type = '-DepthFirstLoadBalancer'}
    )    
    $LBType = $Array | ? input -EQ $LoadBalancerType
    $Context = Get-RdsContext -ErrorAction SilentlyContinue
    $ContextUser = $Context.UserName
    IF(($Context.DeploymentUrl) -match 'https://rdbroker.wvd.microsoft.com') {
        Write-Host `
            "logged in as " -NoNewline
        Write-Host -ForegroundColor Cyan -BackgroundColor Black "$ContextUser"
        ""
        Write-Host -ForegroundColor Yellow -BackgroundColor Black "Beginning LB ModIFications"         
        Wait-Event -Timeout 1
        ""
   }
    Else {
        Write-Host `
            -ForegroundColor Red -BackgroundColor Black "You are not logged in..."  
        ""        
        Write-Host `
            -ForegroundColor Magenta -BackgroundColor Black "Starting Authentication"
        ""
        Wait-Event -Timeout 1
        Add-RdsAccount `
            -DeploymentUrl “https://rdbroker.wvd.microsoft.com”
    }

}

Process {    
    IF(($LBType.type) -match 'Depth') {
        Write-Host "LBType: " -NoNewline
        Write-Host -ForegroundColor Magenta -BackgroundColor Black "Depth First " -NoNewline
        Write-Host "Selected" -NoNewline
        ""        
        Wait-Event -Timeout 1
        Set-RdsHostPool `
            -TenantName $TenantName `
            -Name $HostPoolName `
            -DepthFirstLoadBalancer `
            -MaxSessionLimit $MaxSessionLimit
    }
    Else {
        Write-Host "LBType: " -NoNewline
        Write-Host -ForegroundColor Magenta -BackgroundColor Black "Breadth First " -NoNewline
        Write-Host "Selected" -NoNewline
        ""        
        Wait-Event -Timeout 1
        Set-RdsHostPool `
            -TenantName $TenantName `
            -Name $HostPoolName `
            -BreadthFirstLoadBalancer `
            -MaxSessionLimit $MaxSessionLimit
    }
            
}

End {    
    ""
    Write-Host "Host Pool " -NoNewline; `
    Write-Host $HostPoolName -ForegroundColor Green -NoNewline; `
    Write-Host " has been updated" -NoNewline;  
    ""
    Write-Host "Max Session count is now - " -NoNewline;  
    Write-Host "$MaxSessionLimit" -ForegroundColor Green -NoNewline;
        
}

}


##########################
#    Export Functions    #
##########################
Export-ModuleMember `
    -Function `
        Add-AzureWVDAppGroupUsers,
        New-AzureWVDApps,
        New-AzureWVDPrep,
        Remove-AzureWVD,
        Set-AzureWVDLBType

