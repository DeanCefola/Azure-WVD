/*##################
#    Parameters    #
##################*/
param Location string
param Name string
param AddressSpace string


/*#################
#    Variables    #
#################*/
var addressParts = split(AddressSpace, '.')
var baseAddress = '${addressParts[0]}.${addressParts[1]}' 
var sharedServicesSubnet = '${baseAddress}.1.0/24'
var azureFirewallManagementSubnet = '${baseAddress}.2.0/24'
var azureFirewallSubnet = '${baseAddress}.3.0/24'
var azureBastionSubnet = '${baseAddress}.4.0/24'
var avdSubnet = '${baseAddress}.5.0/24'
var win365Subnet = '${baseAddress}.6.0/24'


/*##################
#    Resources    #
##################*/
resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: Name
  location: Location 
  properties: {
    addressSpace: {
      addressPrefixes: [
        AddressSpace
      ]
    }
    subnets: [
      {name: 'SharedServicesSubnet'
        properties: {
          addressPrefix: sharedServicesSubnet
        }
      }
      {
        name: 'AzureFirewallManagementSubnet'
        properties: {
          addressPrefix: azureFirewallManagementSubnet
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: azureFirewallSubnet
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: azureBastionSubnet
        }
      }
      {
        name: 'AVDSubnet'
        properties: {
          addressPrefix: avdSubnet
        }
      }
      {   
        name: 'Win365Subnet'
        properties: {
          addressPrefix: win365Subnet
        }
      }      
    ]
  }
}


/*################
#    Outputs    #
################*/
output SharedSubnetID string = '${VNET.id}/subnets/SharedServicesSubnet'
output FirewallMgtSubnetID string = '${VNET.id}/subnets/AzureFirewallManagementSubnet'
output FirewallSubnetID string = '${VNET.id}/subnets/AzureFirewallSubnet'
output BastionSubnetID string = '${VNET.id}/subnets/AzureBastionSubnet'
output AVDSubnetID string = '${VNET.id}/subnets/AVDSubnet'
output Win365SubnetID string = '${VNET.id}/subnets/Win365Subnet'

