<#Author       : Dean Cefola
# Creation Date: 12-15-2019
# Usage        : Windows Virtual Desktop Scaling Script Setup

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 12/15/2019                     1.0        Intial Version
# 02/07/2020                     1.1        Add more variables for all data 
# 02/27/2020                     1.2        Clean up variables for public use
# 03/17/2020                     1.3        fix mismatched variables
#*********************************************************************************
#
#>


###########################
#    General Variables    #
###########################
$AADTenantID           = '<Enter AzureAD Tenant ID>'
$SubscriptionID        = '<Enter Azure Subscription ID>'
$TenantName            = '<Enter WVD Tenant Name>'
$HostPoolName          = '<Enter WVD HostPool Name>'
$ResourceGroupName     = '<Enter Azure Resource Group Name to create the automation resources>'
$RecurrenceInterval    = 15
$BeginPeakTime         = '9:00'
$EndPeakTime           = '18:00'
$TimeDifference        = '+5:00'
$SessionThresholdPerCPU= 2
$MinimumNumberOfRdsh   = 1
$LimitSecondsToForceLogOffUser = 30
$LogOffMessageTitle    = '<Enter Log Off Message Title>'
$LogOffMessageBody     = '<Enter Log Off Message>'
$Location              = '<Enter AzureAD region to deploy automation resources>'
$AutomationAccountName = '<Enter Azure Automation Account Name>'
$ConnectionAssetName   = '<Enter Azure Automation RunAs Account Name>'
$MaintenanceTagName    = '<Enter Azure TAG to exclude resources from scaling automation>'
$WorkspaceName         = '<Enter Azure Log Analytics Workspace ID>'
$Workspace             = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -eq $WorkspaceName }
$WorkspaceID           = ($Workspace).CustomerId.guid
$WorkspaceKey          = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $Workspace.ResourceGroupName -Name $WorkspaceName).PrimarySharedKey
$LocalPath             = '<Enter local path on computer where you downloaded the Scaling Automation Power Shell Script Files i.e. c:\temp>'
cd $LocalPath


##########################################
#    Download Scripts for WVD Scaling    #
##########################################
Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script/createazureautomationaccount.ps1" `
    -OutFile "$LocalPath\createazureautomationaccount.ps1"
Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/Azure/RDS-Templates/master/wvd-templates/wvd-scaling-script/createazurelogicapp.ps1" `
    -OutFile "$LocalPath\createazurelogicapp.ps1"


########################################
#    Create Azure Automation Account   #
########################################
& .\createazureautomationaccount.ps1 `
    -SubscriptionId $SubscriptionID `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -Location $Location `
    -WorkspaceName $WorkspaceName `
    -Verbose
$WebhookURI = (Get-AzAutomationVariable `
    -Name "WebhookURI" `
    -ResourceGroupName $ResourceGroupName `
    -AutomationAccountName $AutomationAccountName `
    -ErrorAction SilentlyContinue).Value
$WebhookURI

##############################################
#    Create Azure Automation RunAS Account   #
##############################################
#    Follow Doc to create Azure Automation RunAS Account    #


########################################################
#    Grant RunAS Account WVD Contribute Permissions    #
########################################################
$AARunAsID = Read-Host -Prompt "Enter Azure Automation RunAS Account ID"
New-RdsRoleAssignment `
    -ApplicationId $AARunAsID `
    -TenantName $TenantName `
    -RoleDefinitionName 'RDS Contributor'


##########################
#    Create Logic App    #
##########################
& .\createazurelogicapp.ps1 `
    -ResourceGroupName $ResourceGroupName `
    -AADTenantID $AADTenantID `
    -SubscriptionID $SubscriptionID `
    -TenantName $TenantName `
    -HostPoolName $HostPoolName `
    -RecurrenceInterval $RecurrenceInterval `
    -BeginPeakTime $BeginPeakTime `
    -EndPeakTime $EndPeakTime `
    -TimeDifference $TimeDifference `
    -SessionThresholdPerCPU $SessionThresholdPerCPU `
    -MinimumNumberOfRDSH $MinimumNumberOfRdsh `
    -LimitSecondsToForceLogOffUser $LimitSecondsToForceLogOffUser `
    -LogOffMessageTitle $LogOffMessageTitle `
    -LogOffMessageBody $LogOffMessageBody `
    -Location $Location `
    -ConnectionAssetName $ConnectionAssetName `
    -WebHookURI $WebhookURI `
    -AutomationAccountName $AutomationAccountName `
    -MaintenanceTagName $MaintenanceTagName `
    -Verbose


