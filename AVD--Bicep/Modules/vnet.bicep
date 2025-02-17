/*##################
#    Parameters    #
##################*/
param Location string
param Name string
param AddressSpace string


/*#################
#    Variables    #
#################*/
// Split the AddressPrefix into its components
  var addressParts = split(AddressSpace, '.')
// Increment the third octet
  var incrementedThirdOctet = string(int(addressParts[2]) + 1)
// Construct the new AddressPrefix for Win365Subnet
  var win365AddressPrefix = '${addressParts[0]}.${addressParts[1]}.${incrementedThirdOctet}.0/24'
// Increment the Firewall octet
  var FirewallOctet = string(int(addressParts[2]) + 2)
// Construct the new AddressPrefix for FirewallSubnet
  var FirewallAddressPrefix = '${addressParts[0]}.${addressParts[1]}.${FirewallOctet}.0/24'  
// Increment the Bastion octet
  var BastionOctet = string(int(addressParts[2]) + 3)
// Construct the new AddressPrefix for BastionSubnet
  var BastionAddressPrefix = '${addressParts[0]}.${addressParts[1]}.${BastionOctet}.0/24'
/*##################
#    Resources    #
##################*/
resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: Name
  location: Location 
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${AddressSpace}/16'
      ]
    }
    subnets: [
      {
        name: 'AVDSubnet'
        properties: {
          addressPrefix: '${AddressSpace}/24'
        }
      }
      {   
        name: 'Win365Subnet'
        properties: {
          addressPrefix: win365AddressPrefix
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: FirewallAddressPrefix
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: BastionAddressPrefix
        }
      }
    ]
  }
}


/*################
#    Outputs    #
################*/
output AVDSubnetID string = '${VNET.id}/subnets/AVDSubnet'
output Win365SubnetID string = '${VNET.id}/subnets/Win365Subnet'
output FirewallSubnetID string = '${VNET.id}/subnets/AzureFirewallSubnet'
output BastionSubnetID string = '${VNET.id}/subnets/AzureBastionSubnet'
