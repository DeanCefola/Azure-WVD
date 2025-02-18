/*##################
#    Parameters    #
##################*/
param BastionName string
param Location string
param BastionSubnet string

/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
resource BastionPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${BastionName}-PIP'
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2021-02-01' = {
  name: BastionName
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: BastionSubnet
          }
          publicIPAddress: {
            id: BastionPIP.id
          }
        }
      }
    ]
  }
}


/*################
#    Outputs    #
################*/
