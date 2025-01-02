param AdminUserName string = 'lntad'

@description('Please enter the admin password')
@secure()
param AdminPassword string

var modulesUrl = 'https://wvdportalstorageblob.blob.${environment().suffixes.storage}/galleryartifacts/Configuration_1.0.02797.442.zip'

resource HostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: 'Bicep-HP'
  location: 'eastus2'
  properties: {
    friendlyName: 'hostpoolFriendlyName'
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'RailApplications'
    maxSessionLimit: 10
    validationEnvironment: true
    startVMOnConnect: true
    registrationInfo: {
      expirationTime: dateTimeAdd('2025-01-19 00:00:00Z', 'P2D')
      registrationTokenOperation: 'Update'
    }
  }
}

resource AppDesktop 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'Bicep-App-Desktop'
  location: 'eastus2'
  properties: {
    friendlyName: 'Desktop'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: HostPool.id
  }
}

resource AppRemote 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: 'Bicep-App-RemoteApps'
  location: 'eastus2'
  properties: {
    friendlyName: 'RemoteApps'
    applicationGroupType:'RemoteApp'
    hostPoolArmPath: HostPool.id
  }
}

resource Workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: 'Bicep-WS'
  location: 'eastus2'
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

resource NIC 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: 'Bicep-SH-1-Nic'
  location: 'eastus2'
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

resource VM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'Bicep-SH-1'
  location: 'eastus2'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B4ms'
    }
    osProfile: {
      computerName: 'SH-1'
      adminUsername: AdminUserName
      adminPassword: AdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'office-365'
        sku: 'win11-24h2-avd-m365'
        version: 'latest'
      }
      osDisk: {
        name: 'Bicep-SH-1-OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: NIC.id
        }
      ]
    }    
  }
}

resource entraIdJoin 'Microsoft.Compute/virtualMachines/extensions@2024-03-01' = {
  parent: VM
  name: 'AADLoginForWindows'
  location: 'eastus2'
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
  }
}

resource AVDDsc 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = {
  parent: VM
  name: 'Bicep-SH-1-DSC'
  location: 'eastus2'
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

