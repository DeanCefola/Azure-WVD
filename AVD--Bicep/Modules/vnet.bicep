param Location string

param Name string

param AddressPrefix string

// Split the AddressPrefix into its components
var addressParts = split(AddressPrefix, '.')

// Increment the third octet
var incrementedThirdOctet = string(int(addressParts[2]) + 1)

// Construct the new AddressPrefix for Win365Subnet
var win365AddressPrefix = '${addressParts[0]}.${addressParts[1]}.${incrementedThirdOctet}.0/24'

resource VNET 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: Name
  location: Location 
  properties: {
    addressSpace: {
      addressPrefixes: [
        '${AddressPrefix}/16'
      ]
    }
    subnets: [
      {
        name: 'AVDSubnet'
        properties: {
          addressPrefix: '${AddressPrefix}/24'
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
