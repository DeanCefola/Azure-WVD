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
resource BastionPIP 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: '${BastionName}-PIP'
  location: Location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'dnsname'
    }
  }
}

resource BastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: BastionName
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'name'
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
