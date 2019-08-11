<#Author       : Dean Cefola
# Creation Date: 03-28-2019
# Usage        : Windows Virtual Desktop Functions

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 03/28/2019                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


#######################################
#     Create WVD Service Principal    #
#######################################
$myTenantName = Read-Host -Prompt "Enter Tenant Name"
Import-Module AzureAD
$aadContext = Connect-AzureAD
$svcPrincipal = New-AzureADApplication `
    -AvailableToOtherTenants $true `
    -DisplayName "Windows Virtual Desktop Svc Principal"
$svcPrincipalCreds = New-AzureADApplicationPasswordCredential `
    -ObjectId $svcPrincipal.ObjectId


#################################
#     Connect to WVD Service    #
#################################
$creds = New-Object System.Management.Automation.PSCredential($svcPrincipal.AppId, `
    (ConvertTo-SecureString $svcPrincipalCreds.Value -AsPlainText -Force))
Add-RdsAccount `
    -DeploymentUrl "https://rdbroker.wvd.microsoft.com" `
    -Credential $creds `
    -ServicePrincipal `
    -AadTenantId $aadContext.TenantId.Guid


#########################################
#     Create New WVD Role Assignment    #
#########################################
New-RdsRoleAssignment `
    -RoleDefinitionName "RDS Owner" `
    -ApplicationId $svcPrincipal.AppId `
    -TenantName $myTenantName


################################
#     Service Principal Info   #
################################
 Write-host `
    -BackgroundColor Black `
    -ForegroundColor Cyan "AzureAD Directory ID - " `
    -NoNewline $aadContext.TenantId.Guid
""
""
 Write-host `
    -BackgroundColor Black `
    -ForegroundColor Cyan "WVD SvcPrin ID - " `
    -NoNewline $svcPrincipal.AppId 
""
""
Write-host `
    -BackgroundColor Black `
    -ForegroundColor Cyan "WVD SvcPrin Pwd - " `
    -NoNewline $svcPrincipalCreds.Value
""
""


