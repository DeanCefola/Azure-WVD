param AdminUserName string = 'lntad'

@description('Please enter the admin password')
@secure()
param AdminPassword string

param Location string

param prefix string

@allowed([
  'Win10'
  'Win11'
])
param HostOS string

@allowed([
  'Small'
  'Medium'
  'Large'
])
param VMSize string = 'Small'

@minValue(1)
@maxValue(99)
param NumberOfHosts int


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

resource HostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: '${prefix}-HP'
  location:  Location
  properties: {
    friendlyName: 'hostpoolFriendlyName'
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'RailApplications'
    maxSessionLimit: 10
    validationEnvironment: true
    startVMOnConnect: true
    registrationInfo: {
      expirationTime: dateTimeAdd('2025-01-27 00:00:00Z', 'P31D')
      registrationTokenOperation: 'Update'
    }
  }
}

resource AppDesktop 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: '${prefix}-App-Desktop'
  location: Location
  properties: {
    friendlyName: 'Desktop'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: HostPool.id
  }
}

resource AppRemote 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: '${prefix}-App-RemoteApps'
  location: Location
  properties: {
    friendlyName: 'RemoteApps'
    applicationGroupType:'RemoteApp'
    hostPoolArmPath: HostPool.id
  }
}

resource Workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: '${prefix}-WS'
  location: Location
  properties: {
    friendlyName: 'friendlyName'
    applicationGroupReferences: [
      AppDesktop.id
      AppRemote.id
    ]
  }
}

resource Subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: 'VNET-Cloud-VDI/AVD-1'
}

resource NIC 'Microsoft.Network/networkInterfaces@2024-05-01' = [for i in range(0, NumberOfHosts): {
  name: '${prefix}-SH-${i+1}-Nic'
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: Subnet.id
          }
        }
      }
    ]
  }
}
]

resource VM 'Microsoft.Compute/virtualMachines@2024-07-01' = [ for i in range(0, NumberOfHosts): {
  name: '${prefix}-SH-${i+1}'
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
      computerName: '${prefix}-SH-${i+1}'
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
        name: '${prefix}-SH-${i+1}-OSDisk'
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
        hostPoolName: HostPool.name
        aadJoin: true
      }
    }
    protectedSettings: {
      properties: {
        registrationInfoToken: HostPool.listRegistrationTokens().value[0].token
      }
    }
  }
  dependsOn: [
    entraIdJoin
  ]
}
]

