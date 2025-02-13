/*##################
#    Parameters    #
##################*/
param Location string
param NamePrefix string
param Subnet string
param NumberOfHosts int
param HostPoolName string
param RegistrationToken string
param AdminUserName string
@secure()
param AdminPassword string
param HostOS string
param VMSize string

/*#################
#    Variables    #
#################*/
var VMSizes = {
  Small: {
    vmSize: 'Standard_B4ms'
  }
  Medium: {
    vmSize: 'Standard_DS3_v2'
  }
  Large: {
    vmSize: 'Standard_DS14_v2'
  }
}
var VMImage ={
  Win11: {
    publisher: 'microsoftwindowsdesktop'
    offer: 'office-365'
    sku: 'win11-24h2-avd-m365'
    version: 'latest'
  }
  Win10: {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: 'win10-22h2-avd-g2'
    version: 'latest'
    }
}
var modulesUrl = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_1.0.02797.442.zip'


/*##################
#    Resources    #
##################*/
resource NIC 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(0, NumberOfHosts): {
  name: '${NamePrefix}-SH-${i+1}-Nic'
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: Subnet
          }
        }
      }
    ]
  }
}
]

resource VM 'Microsoft.Compute/virtualMachines@2024-07-01' = [ for i in range(0, NumberOfHosts): {
  name: '${NamePrefix}-SH-${i+1}'
  location: Location
  properties: {
    hardwareProfile: {
      vmSize: VMSizes[VMSize].vmSize
    }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: {
        secureBootEnabled: true
        vTpmEnabled: true
      }
    }
    additionalCapabilities: {
      hibernationEnabled: false
    }
    osProfile: {
      computerName: '${NamePrefix}-SH-${i+1}'
      adminUsername: AdminUserName
      adminPassword: AdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: VMImage[HostOS].publisher
        offer: VMImage[HostOS].offer
        sku: VMImage[HostOS].sku
        version: VMImage[HostOS].version
      }
      osDisk: {
        name: '${NamePrefix}-SH-${i+1}-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC[i].id
        }
      ]
    }    
  }
}
]

resource entraIdJoin 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = [ for i in range(0, NumberOfHosts):{
  parent: VM[i]
  name: 'AADLoginForWindows'
  location: Location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
  }  
}
]

resource AVDDsc 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [ for i in range(0, NumberOfHosts):{
  parent: VM[i]
  name: 'MicrosoftPowershellDSC'
  location: Location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    settings: {
      modulesUrl: modulesUrl
      configurationFunction: 'Configuration.ps1\\AddSessionHost'
      properties: {
        hostPoolName: HostPoolName
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: RegistrationToken
      }
    }
  }
  dependsOn: [
    entraIdJoin
  ]
}
]

/*################
#    Outputs    #
################*/

