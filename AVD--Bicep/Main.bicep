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
var randomString = substring(uniqueString(resourceGroup().id), 0, 4)

/*##################
#    Resources    #
##################*/
module VNET 'Modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    Name: '${NamePrefix}-VNET'
    Location: Location
    AddressSpace: AddressSpace
  }
}

module Firewall 'Modules/Firewall.bicep' = {
  name: 'Firewall'
  params: {
    FWName: '${NamePrefix}-FW'
    Location: Location
    FWMgtSubnet: VNET.outputs.FirewallMgtSubnetID
    FirewallSubnet: VNET.outputs.FirewallSubnetID
  }
}

module Bastion 'Modules/Bastian.bicep' = {
  name: 'Bastion'
  params: {
    BastionName: '${NamePrefix}-Bastion'
    Location: Location
    BastionSubnet: VNET.outputs.BastionSubnetID
  }
}

module KeyVault 'Modules/KeyVault.bicep' = {
  name: 'KeyVault'
  params: {
    KVName: '${NamePrefix}-KV-${randomString}'
    Location: Location
    AdminPassword: AdminPassword
  }
}

module AVDCore 'Modules/AVDCore.bicep' = {
  name: 'AVDCore'
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
  name: 'AVDHost'
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
