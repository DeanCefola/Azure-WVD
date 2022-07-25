<#Author       : Dean Cefola
# Creation Date: 07-09-2020
# Usage        : Get AVD App Group Assignment
# 
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 07/09/2020                     1.0        Intial Version
#

#*********************************************************************************
#
#>
###################
#    Variables    #
###################
$RGName = 'GPU'
$AppGroupName = 'HP-GPU-DAG'
$AVDGroup = Get-AzWvdApplicationGroup `
    -Name $AppGroupName `
    -ResourceGroupName $RGName


#################################
#    Get AVD Role Assignment    #
#################################
Get-AzRoleAssignment `
    -Scope $AVDGroup.Id | `
    Where-Object `
        -Property RoleDefinitionName `
        -match 'Desktop Virtualization User'


