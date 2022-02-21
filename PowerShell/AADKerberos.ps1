#################
#    Prereqs    #
#################
$resourceGroupName = "AADJoin"
$storageAccountName = "avdaadjoineus2"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force
Install-Module -Name AzureAD -Force
Install-Module -Name Az.Accounts -Force
Install-Module -Name Az.Storage -Force
Connect-AzureAD
Connect-AzAccount


###########################################################
#    Enable Azure AD authentication on storage account    #
###########################################################
$Subscription =  $(Get-AzContext).Subscription.Id;
$ApiVersion = '2021-04-01'
$Uri = ('https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}?api-version={3}' -f $Subscription, $ResourceGroupName, $StorageAccountName, $ApiVersion);
$json = 
   @{properties=@{azureFilesIdentityBasedAuthentication=@{directoryServiceOptions="AADKERB"}}};
$json = $json | ConvertTo-Json -Depth 99
$token = $(Get-AzAccessToken).Token
$headers = @{ Authorization="Bearer $token" }
try {
    Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method PATCH -Headers $Headers -Body $json;
} catch {
    Write-Host $_.Exception.ToString()
    Write-Error -Message "Caught exception setting Storage Account directoryServiceOptions=AADKERB: $_" -ErrorAction Stop
}


#######################################################################
#    Generate the kerberos storage account key for storage account    #
#######################################################################
New-AzStorageAccountKey `
  -ResourceGroupName $resourceGroupName `
  -Name $storageAccountName `
  -KeyName kerb1 `
  -ErrorAction Stop


##########################################
#    Set the service principal secret    #
##########################################
$kerbKey1 = Get-AzStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName -ListKerbKey | Where-Object { $_.KeyName -like "kerb1" }
$aadPasswordBuffer = [System.Linq.Enumerable]::Take([System.Convert]::FromBase64String($kerbKey1.Value), 32);
$password = "kk:" + [System.Convert]::ToBase64String($aadPasswordBuffer);


#####################################
#    Retrieve tenant information    #
#####################################
$azureAdTenantDetail = Get-AzureADTenantDetail;
$azureAdTenantId = $azureAdTenantDetail.ObjectId
$azureAdPrimaryDomain = ($azureAdTenantDetail.VerifiedDomains | Where-Object {$_._Default -eq $true}).Name


#################################################################################
#    Generate the service principal names for the Azure AD service principal    #
#################################################################################
$servicePrincipalNames = New-Object string[] 3
$servicePrincipalNames[0] = 'HTTP/{0}.file.core.windows.net' -f $storageAccountName
$servicePrincipalNames[1] = 'CIFS/{0}.file.core.windows.net' -f $storageAccountName
$servicePrincipalNames[2] = 'HOST/{0}.file.core.windows.net' -f $storageAccountName


#######################################################
#    Create an application for the storage account    #
#######################################################
$application = New-AzureADApplication `
  -DisplayName $storageAccountName `
  -IdentifierUris $servicePrincipalNames `
  -GroupMembershipClaims "All";


############################################################
#    Create a service principal for the storage account    #
############################################################
$servicePrincipal = New-AzureADServicePrincipal `
  -AccountEnabled $true `
  -AppId $application.AppId `
  -ServicePrincipalType "Application";


######################################################################
#    Set the password for the storage account's service principal    #
######################################################################
$Token = ([Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AccessTokens['AccessToken']).AccessToken
$apiVersion = '1.6'
$Uri = ('https://graph.windows.net/{0}/{1}/{2}?api-version={3}' -f $azureAdPrimaryDomain, 'servicePrincipals', $servicePrincipal.ObjectId, $apiVersion)
$json = @'
{
  "passwordCredentials": [
  {
    "customKeyIdentifier": null,
    "endDate": "<STORAGEACCOUNTENDDATE>",
    "value": "<STORAGEACCOUNTPASSWORD>",
    "startDate": "<STORAGEACCOUNTSTARTDATE>"
  }]
}
'@
$now = [DateTime]::UtcNow
$json = $json -replace "<STORAGEACCOUNTSTARTDATE>", $now.AddDays(-1).ToString("s")
  $json = $json -replace "<STORAGEACCOUNTENDDATE>", $now.AddMonths(12).ToString("s")
$json = $json -replace "<STORAGEACCOUNTPASSWORD>", $password
$Headers = @{'authorization' = "Bearer $($Token)"}
try {
  Invoke-RestMethod -Uri $Uri -ContentType 'application/json' -Method Patch -Headers $Headers -Body $json 
  Write-Host "Success: Password is set for $storageAccountName"
} catch {
  Write-Host $_.Exception.ToString()
  Write-Host "StatusCode: " $_.Exception.Response.StatusCode.value
  Write-Host "StatusDescription: " $_.Exception.Response.StatusDescription
}
