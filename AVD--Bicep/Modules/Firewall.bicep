/*##################
#    Parameters    #
##################*/
param FWName string
param Location string
param FirewallSubnet string

/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2019-11-01' = {
  name: '${FWName}-PIP'
  location: Location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: 'dnsname'
    }
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-05-01' = {  
  name: FWName
  location: Location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }    
    firewallPolicy: {
      id: 'firewallPolicy.id'
    }
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          subnet: {
            id: FirewallSubnet
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddress
  ]
}



/*################
#    Outputs    #
################*/
