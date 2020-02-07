<#Author       : Dean Cefola
# Creation Date: 12-15-2019
# Usage        : Windows Virtual Desktop Scaling Script Setup

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 12/15/2019                     1.0        Intial Version
#
#*********************************************************************************
#
#>


###########################
#    General Variables    #
###########################
$AADTenantID        = '10c5dfa7-b5c3-4cf2-9265-f0e32a960967'
$SubscriptionID     = 'c82ad9b5-1009-44fd-abdc-2b30f8e55ba0'
$TenantGroup        = 'Default Tenant Group'
$TenantName         = 'WVD-Tenant-AzureAcademy'
$HostPoolName       = 'WVD-Scaling'
$RGName             = 'WVDMgmt'
$AAName             = 'AA-WVD-Automation'
$AARunAsName        = 'AzureRunAsConnection'
$Location           = 'eastus'
$WorkspaceName      = 'AA-WVD-LogAnalytics-00'                    
$Workspace          = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -eq $WorkspaceName }
$WorkspaceID        = ($Workspace).CustomerId.guid
$WorkspaceKey       = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $WorkspaceRGName -Name $WorkspaceName).PrimarySharedKey
$localPath          = 'C:\temp\'
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
    -AADTenantId $AADTenantID `
    -SubscriptionId $SubscriptionID `
    -TenantGroupName $TenantGroup `
    -TenantName $TenantName `
    -HostpoolName $HostPoolName `
    -Location $Location `
    -ResourcegroupName $RGName `
    -AutomationAccountName $AAName `
    -ConnectionAssetName $AARunAsName `
    -WebhookURI $WebhookURI `
    -LogAnalyticsWorkspaceId $WorkspaceID `
    -LogAnalyticsPrimaryKey $WorkspaceKey `
    -RecurrenceInterval 15 `
    -BeginPeakTime '9:00' `
    -EndPeakTime '18:00' `
    -TimeDifference '+5:00' `
    -SessionThresholdPerCPU 2 `
    -MinimumNumberOfRDSH 1 `
    -MaintenanceTagName 'vm' `
    -LimitSecondsToForceLogOffUser 30 `
    -LogOffMessageTitle 'Scaling Down - Please Log Off' `
    -LogOffMessageBody 'We are scaling down, Please log off at this time so you do not lose any work' `
    -Verbose


