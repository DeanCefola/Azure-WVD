<#Author       : Dean Cefola
# Creation Date: 05-26-2021
# Usage        : WVD SSO with ADFS 
# 
# WVD Doc can be found here - https://docs.microsoft.com/en-us/azure/virtual-desktop/configure-adfs-sso#configure-the-ad-fs-servers
#********************************************************************************
# Date                         Version      Changes
#------------------------------------------------------------------------
# 05/26/2021                     1.0        Intial Version
#
#
#*********************************************************************************
#
#>


###################################
#    ADFS Certificate Templates   #
###################################
Set-AdfsCertificateAuthority `
    -EnrollmentAgentCertificateTemplate "ADFSEnrollmentAgent" `
    -LogonCertificateTemplate "ADFS Cert" `
    -EnrollmentAgent


###################################
#    Download PSGallery Script    #
###################################
Install-Script -Name ConfigureWVDSSO 


############################################
#    ADFS Relying-Party Trust Shared Key   #
############################################
$Config = ConfigureWVDSSO.ps1 `
    -ADFSAuthority "https://adfs.<FQDN>/adfs"

$hp = Get-AzWvdHostPool `
    -Name "<Host Pool Name>" `
    -ResourceGroupName "<Host Pool Resource Group Name>" 

$secret = Set-AzKeyVaultSecret `
    -VaultName "<Key Vault Name>" `
    -Name "adfsssosecret" `
    -SecretValue (ConvertTo-SecureString `
        -String $config.SSOClientSecret  `
        -AsPlainText -Force) `
        -Tag @{ 'AllowedWVDSubscriptions' = $hp.Id.Split('/')[2]}



######################################
#    ADFS Relying-Party Trust CERT   #
######################################
$config = ConfigureWVDSSO.ps1 `
    -ADFSAuthority "https://adfs.<FQDN>/adfs" `
    -UseCert `
    -CertPath "C:\temp\ADFSCert.pfx" `
    -CertPassword "<Password to the pfx file>"

$hp = Get-AzWvdHostPool `
    -Name "<Host Pool Name>" `
    -ResourceGroupName "<Host Pool Resource Group Name>" 

$secret = Import-AzKeyVaultCertificate `
    -VaultName "<Key Vault Name>" `
    -Name "adfsssosecret" `
    -Tag @{ 'AllowedWVDSubscriptions' = $hp.Id.Split('/')[2]} `
    -FilePath "<Path to pfx>" `
    -Password (ConvertTo-SecureString `
        -String "<pfx password>"  `
        -AsPlainText `
        -Force
    )
    

# ADFS SSO Docs
# https://docs.microsoft.com/en-us/windows-server/identity/ad-fs/operations/ad-fs-single-sign-on-settings

########################
#    ADFS Setup SSO    #
########################
Set-AdfsProperties –EnablePersistentSso $true
Set-AdfsProperties -DeviceUsageWindowInDays 2
Set-AdfsProperties -PersistentSsoLifetimeMins 172800


#################################
#    unauthenticated devices    #
#################################
Set-AdfsProperties -EnableKmsi $true
Set-AdfsProperties –SsoLifetime 28
Set-AdfsProperties –KmsiLifetimeMins 172800

