###################
#    Variables    #
###################
$profileShare = "\\kbdxaz0t1asofc13n4m2xkqd.file.core.windows.net\fslogix"


################
#    Profile   #
################
write-host "Configuring FSLogix"
New-Item -Path "HKLM:\SOFTWARE" -Name "FSLogix" -ErrorAction Ignore
New-Item -Path "HKLM:\SOFTWARE\FSLogix" -Name "Profiles" -ErrorAction Ignore
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "Enabled" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VHDLocations" -Value $profileShare -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ConcurrentUserSessions" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "DeleteLocalProfileWhenVHDShouldApply" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "FlipFlopProfileDirectoryName" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "IsDynamic" -Value 1 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "KeepLocalDir" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "ProfileType" -Value 0 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "SizeInMBs" -Value 40000 -force
New-ItemProperty -Path "HKLM:\SOFTWARE\FSLogix\Profiles" -Name "VolumeType" -Value "VHDX" -force


###############################
#  Entra Kerberos + CredKeys  #
###############################

# Enable Cloud Kerberos ticket retrieval (equivalent to the GPO / CSP)
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos" -Name "Parameters" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters" `
  -Name "CloudKerberosTicketRetrievalEnabled" -PropertyType DWord -Value 1 -Force | Out-Null

# Ensure Credential Manager keys are taken from the currently loading profile (FSLogix roaming)
New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft" -Name "AzureADAccount" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\AzureADAccount" `
  -Name "LoadCredKeyFromProfile" -PropertyType DWord -Value 1 -Force | Out-Null

# Map .file.core.windows.net to the Entra ID Kerberos realm
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\HostToRealm\KERBEROS.MICROSOFTONLINE.COM" -Force | Out-Null

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\HostToRealm\KERBEROS.MICROSOFTONLINE.COM" `
    -Name "SpnMappings" `
    -PropertyType MultiString `
    -Value ".file.core.windows.net" `
    -Force | Out-Null

Write-Host "Entra Kerberos enabled and Credential Manager profile binding configured."

write-host "Configuration Complete"
