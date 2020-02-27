<#Author       : Dean Cefola
# Creation Date: 07-28-2019
# Usage        : Windows Virtual Desktop Add New Host to Existing Pool

#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 07/28/2019                     1.0        Intial Version
#
#

#*********************************************************************************
#
#>


###########################
#    General Variables    #
###########################
$TenantName = 'AzureAcademy-Tenant'
$HostPoolName = 'AA-WVD-Servers'


#######################
#    Register Host    #
#######################
#  If you have already done this step you will get an error 
#  Because you already generated a token...
#  go to Export step
#  After 72 hours you can run this again
$NewToken = New-RdsRegistrationInfo `
    -TenantName $TenantName `
    -HostPoolName $HostPoolName `
    -Verbose 
$NewToken.Token


#############################
#    Export Registration    #
#############################
$ExportToken = Export-RdsRegistrationInfo `
    -TenantName $TenantName `
    -HostPoolName $HostPoolName `
    -Verbose
$ExportToken.Token


Get-RdsSessionHost `
    -TenantName $TenantName `
    -HostPoolName $HostPoolName


