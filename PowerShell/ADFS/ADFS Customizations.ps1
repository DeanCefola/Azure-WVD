
########################
#    ADFS Meta Data    #
########################
$creds = Get-Credential
Connect-MsolService -Credential $creds
Get-MsolDomainFederationSettings -DomainName MSAzureAcademy.com


#####################################
#    ADFS Customization Examples    #
#####################################
Set-AdfsGlobalWebContent `
    –CompanyName "MSAzureAcademy" 
Set-AdfsWebTheme `
    -TargetName default `
    -Logo @{path="Z:\AD Scripts\__FINAL_ME_Small.png"}
Set-AdfsWebTheme `
    -TargetName default `
    -Illustration @{path="Z:\AD Scripts\ADFS_Illustration.png"}
Set-AdfsGlobalWebContent `
    -SignInPageDescriptionText "<p>Azure Academy Watch.Learn.Do!</p>"


##################################
#    ADFS Help - Claims X-Ray    #
##################################
$authzRules = "=>issue(Type = `"http://schemas.microsoft.com/authorization/claims/permit`", Value = `"true`"); "
$issuanceRules = "@RuleName = `"Issue all claims`"`nx:[]=>issue(claim = x); "
$redirectUrl = "https://adfshelp.microsoft.com/ClaimsXray/TokenResponse"
$samlEndpoint = New-AdfsSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $redirectUrl
Add-ADFSRelyingPartyTrust `
    -Name "ClaimsXray" `
    -Identifier "urn:microsoft:adfs:claimsxray" `
    -IssuanceAuthorizationRules $authzRules `
    -IssuanceTransformRules $issuanceRules `
    -WSFedEndpoint $redirectUrl `
    -SamlEndpoint $samlEndpoint
Add-AdfsClient `
    -Name "ClaimsXrayClient" `
    -ClientId "claimsxrayclient" `
    -RedirectUri https://adfshelp.microsoft.com/ClaimsXray/TokenResponse
if ([System.Environment]::OSVersion.Version.major -gt 6) { 
    Grant-AdfsApplicationPermission `
        -ServerRoleIdentifier urn:microsoft:adfs:claimsxray `
        -AllowAllRegisteredClients `
        -ScopeNames "openid","profile" 
    }
