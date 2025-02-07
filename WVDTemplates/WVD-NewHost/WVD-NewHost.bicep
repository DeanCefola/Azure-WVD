param Prefix string = 'wvd'

param AdminUserName string

@secure()
param AdminPassword string
param DomainFQDN string

@minValue(1)
@maxValue(99)
param Instance int = 1

@allowed([
  'Server'
  'Client'
])
param OperatingSystem string = 'Client'

@allowed([
  'Small'
  'Medium'
  'Large'
])
param VMSize string = 'Small'
param VnetRgName string
param VnetName string
param SubnetName string
param ProfilePath string
param RegistrationToken string

@allowed([
  true
  false
])
param Optimize bool

var VM_Images = {
  Server: {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-Datacenter-smalldisk'
    version: 'latest'
  }
  Client: {
    publisher: 'microsoftwindowsdesktop'
    offer: 'office-365'
    sku: '20h1-evd-o365pp'
    version: 'latest'
  }
}
var VM_SIZES = {
  Small: {
    WVDsize: 'Standard_B2ms'
  }
  Medium: {
    WVDsize: 'Standard_DS3_v2'
  }
  Large: {
    WVDsize: 'Standard_DS14_v2'
  }
}
var License = {
  Server: {
    License: 'Windows_Server'
  }
  Client: {
    License: 'Windows_Client'
  }
  Multi: {
    License: 'Windows_Client'
  }
}
var VMName = '${Prefix}-VM-'
var subnetRef = '${subscription().id}/resourceGroups/${VnetRgName}/providers/Microsoft.Network/virtualNetworks/${VnetName}/subnets/${SubnetName}'
var JoinUser = '${AdminUserName}@${DomainFQDN}'
var fileUris = 'https://raw.githubusercontent.com/DeanCefola/Azure-WVD/master/PowerShell/New-WVDSessionHost.ps1'
var UriFileNamePieces = split(fileUris, '/')
var firstFileNameString = UriFileNamePieces[(length(UriFileNamePieces) - 1)]
var firstFileNameBreakString = split(firstFileNameString, '?')
var firstFileName = firstFileNameBreakString[0]
var Arguments = string('-ProfilePath ${ProfilePath} -RegistrationToken ${RegistrationToken} -Optimize ${Optimize}')

resource VMName_nic 'Microsoft.Network/networkInterfaces@2018-10-01' = [for i in range(0, Instance): {
    name: '${VMName}${i}-nic'
    location: resourceGroup().location
    tags: {
      costcode: 'AA-Money'
      displayName: 'WVD-Nic'
    }
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Dynamic'
          }
        }
      ]
    }
    dependsOn: []
  }
]

resource VM 'Microsoft.Compute/virtualMachines@2019-03-01' = [
  for i in range(0, Instance): {
    name: concat(VMName, i)
    location: resourceGroup().location
    tags: {
      costcode: 'AA-Money'
      displayName: 'WVD-VM'
    }
    properties: {
      hardwareProfile: {
        vmSize: VM_SIZES[VMSize].WVDsize
      }
      storageProfile: {
        osDisk: {
          name: '${VMName}${i}-OSDisk'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
        imageReference: {
          publisher: VM_Images[OperatingSystem].publisher
          offer: VM_Images[OperatingSystem].offer
          sku: VM_Images[OperatingSystem].sku
          version: VM_Images[OperatingSystem].version
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: resourceId('Microsoft.Network/networkInterfaces', '${VMName}${i}-nic')
          }
        ]
      }
      osProfile: {
        computerName: concat(VMName, i)
        adminUsername: AdminUserName
        adminPassword: AdminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          provisionVMAgent: true
        }
      }
      licenseType: License[OperatingSystem].License
    }
    zones: [
      1
    ]
    dependsOn: [
      VMName_nic
    ]
  }
]

resource VMName_joinDomain 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [
  for i in range(0, Instance): {
    name: '${VMName}${i}/joinDomain'
    location: resourceGroup().location
    tags: {
      displayName: 'Join Domain'
    }
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'JsonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: true
      settings: {
        Name: DomainFQDN
        User: JoinUser
        Restart: 'true'
        Options: '3'
      }
      protectedSettings: {
        Password: AdminPassword
      }
    }
    dependsOn: [
      VM
    ]
  }
]

resource VMName_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [
  for i in range(0, Instance): {
    name: '${VMName}${i}/CustomScriptExtension'
    location: resourceGroup().location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.9'
      autoUpgradeMinorVersion: true
      settings: {
        fileUris: [
          fileUris
        ]
      }
      protectedSettings: {
        commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${firstFileName} ${Arguments}'
      }
    }
    dependsOn: [
      VMName_joinDomain
    ]
  }
]
