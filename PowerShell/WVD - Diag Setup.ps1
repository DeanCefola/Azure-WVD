<#Author       : Dean Cefola
# Creation Date: 08-15-2019
# Usage        : Windows Virtual Desktop Diagnostics Tool

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 08/15/2019                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


#######################
#    WVD Variables    #
#######################
$TenantName =  'AzureAcademy-Tenant'


################################
#    WVD Diags--The old way    #
################################
Get-RdsDiagnosticActivities `
    -TenantName $TenantName `
    -StartTime 8/10/2019 `
    -EndTime 8/11/2019 `
    | Sort-Object -Property ActivityType, UserName `
    |ft -AutoSize

Get-RdsDiagnosticActivities `
    -TenantName $TenantName `
    -ActivityId 2aa93ef8-d33f-4b0c-aaa5-e160014f0000


################################
#    Setup WVD Diag Scripts    #
################################
& 'C:\temp\Create AD App Registration for Diagnostics.ps1'
& 'C:\temp\Create LogAnalyticsWorkspace for Diagnostics.ps1'


##################################
#    WVD Diag Prereqs Outputs    #
##################################
# Service Principal Name:       AA--WVD--Diags
# Log Analytics workspace Name: AA-WVD-LogAnalytics-00
# 
# Client Id :                   dd93276a-a17a-4377-ba9e-b7e42fd15ac4
# Client Secret Key:            N2JmYWZmMmUtNGY1Ni00OWQzLTk5ZGYtZDc3YTNkY2M1YTEz=
# Log Analytics workspace Id:   2fa4da7e-dcb5-4040-8fd5-b850019da872


