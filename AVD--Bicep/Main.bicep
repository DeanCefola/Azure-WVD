/*##################
#    Parameters    #
##################*/
param AdminUserName string = 'lntad'
@description('Please enter the admin password')
@secure()
param AdminPassword string
param Location string
param NamePrefix string
param AddressSpace string
@minValue(1)
@maxValue(99)
param NumberOfHosts int
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


/*#################
#    Variables    #
#################*/
var randomString = substring(uniqueString(RGShared.name), 0, 4)


/*##################  
#    Resources    #
##################*/
targetScope = 'subscription'

resource RGShared 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'RG-${NamePrefix}-Shared'
  location: Location
}

resource RGAVD 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'RG-${NamePrefix}-AVD'
  location: Location
}

//Virtual Networks
module VNET 'Modules/vnet.bicep' = {
  scope: resourceGroup(RGShared.name)
  name: 'Deploy-VNet'
  params: {
    Name: '${NamePrefix}-VNET'
    Location: Location
    AddressSpace: AddressSpace
  }
}

//Network Security
module Firewall 'Modules/Firewall.bicep' = {
  scope: resourceGroup(RGShared.name)
  name: 'Deploy-Firewall'
  params: {
    FWName: '${NamePrefix}-FW'
    Location: Location
    FWMgtSubnet: VNET.outputs.FirewallMgtSubnetID
    FirewallSubnet: VNET.outputs.FirewallSubnetID
  }
}

module Bastion 'Modules/Bastian.bicep' = {
  scope: resourceGroup(RGShared.name)
  name: 'Deploy-Bastion'
  params: {
    BastionName: '${NamePrefix}-Bastion'
    Location: Location
    BastionSubnet: VNET.outputs.BastionSubnetID
  }
}

module KeyVault 'Modules/KeyVault.bicep' = {
  scope: resourceGroup(RGShared.name)
  name: 'Deploy-KeyVault'
  params: {
    KVName: '${NamePrefix}-KV-${randomString}'
    Location: Location
    AdminPassword: AdminPassword
  }
}

//Azure Virtual Desktop
module AVDCore 'Modules/AVDCore.bicep' = {
  scope: resourceGroup(RGAVD.name)
  name: 'Deploy-AVDCore'
  params: {
    HPName: '${NamePrefix}-HP'
    DesktopGroupName: '${NamePrefix}-DAG'
    AppGroupName: '${NamePrefix}-RAG'
    WorkspaceName: '${NamePrefix}-WS'
    ScalingPlanName: '${NamePrefix}-SP'
    Location: Location    
  }
}

module AVDHost 'Modules/AVDHost.bicep' = {
  scope: resourceGroup(RGAVD.name)
  name: 'Deploy-AVDHosts'
  params: {
    HostPoolName: AVDCore.outputs.HostPoolName
    NamePrefix: NamePrefix
    Subnet: VNET.outputs.AVDSubnetID
    NumberOfHosts: NumberOfHosts
    Location: Location
    RegistrationToken: AVDCore.outputs.HostPoolToken
    AdminUserName: AdminUserName
    AdminPassword: AdminPassword
    HostOS: HostOS
    VMSize: VMSize
  }
}

/*################
#    Outputs    #
################*/
