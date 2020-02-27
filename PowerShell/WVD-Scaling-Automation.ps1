<#Author       : Dean Cefola
# Creation Date: 12-15-2019
# Usage        : Windows Virtual Desktop Scaling Script Setup

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 12/15/2019                     1.0        Intial Version
# 02/07/2020                     1.1        Add more variables for all data 
# 02/27/2020                     1.2        Clean up variables for public use
#
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
$resourceGroupName     = '<Enter Azure Resource Group Name to create the automation resources>'
$recurrenceInterval    = 15
$beginPeakTime         = '9:00'
$endPeakTime           = '18:00'
$timeDifference        = '+5:00'
$sessionThresholdPerCPU= 2
$minimumNumberOfRdsh   = 1
$limitSecondsToForceLogOffUser = 30
$logOffMessageTitle    = '<Enter Log Off Message Title>'
$logOffMessageBody     = '<Enter Log Off Message>'
$location              = '<Enter AzureAD region to deploy automation resources>'
$automationAccountName = '<Enter Azure Automation Account Name>'
$connectionAssetName   = '<Enter Azure Automation RunAs Account Name>'
$maintenanceTagName    = '<Enter Azure TAG to exclude resources from scaling automation>'
$WorkspaceName         = '<Enter Azure Log Analytics Workspace ID>'
$Workspace             = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -eq $WorkspaceName }
$WorkspaceID           = ($Workspace).CustomerId.guid
$WorkspaceKey          = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $Workspace.ResourceGroupName -Name $WorkspaceName).PrimarySharedKey
$localPath             = '<Enter local path on computer where you downloaded the Scaling Automation Power Shell Script Files i.e. c:\temp>'
cd $localPath


##########################################
#    Download Scripts for WVD Scaling    #
##########################################
Invoke-WebRequest `
    -Uri “https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-wvdautoscaling-automation/wvd-templates/wvd-scaling-script/wvdscaling-automation/createazureautomationaccount.ps1" `
    -OutFile 'C:\temp\createazureautomationaccount.ps1'
Invoke-WebRequest `
    -Uri “https://raw.githubusercontent.com/Azure/RDS-Templates/ptg-wvdautoscaling-automation/wvd-templates/wvd-scaling-script/wvdscaling-automation/createazurelogicapp.ps1" `
    -OutFile 'C:\temp\createazurelogicapp.ps1'



########################################
#    Create Azure Automation Account   #
########################################
& .\createazureautomationaccount.ps1 `
    -SubscriptionId $SubscriptionID `
    -ResourceGroupName $RGName `
    -AutomationAccountName $AAName `
    -Location $Location `
    -WorkspaceName $Workspace `
    -Verbose
$WebhookURI = (Get-AzAutomationVariable `
    -Name "WebhookURI" `
    -ResourceGroupName $RGName `
    -AutomationAccountName $AAName `
    -ErrorAction SilentlyContinue).Value
$WebhookURI

##############################################
#    Create Azure Automation RunAS Account   #
##############################################
#    Follow Doc to create Azure Automation RunAS Account


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
    -ResourceGroupName $resourceGroupName `
    -AADTenantID $aadTenantId `
    -SubscriptionID $subscriptionId `
    -TenantName $tenantName `
    -HostPoolName $hostPoolName `
    -RecurrenceInterval $recurrenceInterval `
    -BeginPeakTime $beginPeakTime `
    -EndPeakTime $endPeakTime `
    -TimeDifference $timeDifference `
    -SessionThresholdPerCPU $sessionThresholdPerCPU `
    -MinimumNumberOfRDSH $minimumNumberOfRdsh `
    -LimitSecondsToForceLogOffUser $limitSecondsToForceLogOffUser `
    -LogOffMessageTitle $logOffMessageTitle `
    -LogOffMessageBody $logOffMessageBody `
    -Location $location `
    -ConnectionAssetName $connectionAssetName `
    -WebHookURI $webHookURI `
    -AutomationAccountName $automationAccountName `
    -MaintenanceTagName $maintenanceTagName `
    -Verbose


