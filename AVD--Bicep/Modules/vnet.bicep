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
    ]
  }
}


/*################
#    Outputs    #
################*/
output AVDSubnetID string = '${VNET.id}/subnets/AVDSubnet'
output Win365SubnetID string = '${VNET.id}/subnets/Win365Subnet'

