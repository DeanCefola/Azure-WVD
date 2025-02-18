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
resource FWPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${FWName}-PIP'
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewallPolicy 'Microsoft.Network/firewallPolicies@2024-05-01' = {
  name: '${FWName}-FWP'
  location: Location
  properties: {
    sku: {
      tier: 'Basic'
    }
    dnsSettings: {
      enableProxy: true
    }
    threatIntelMode: 'Alert'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2021-05-01' = {    
  name: FWName
  location: Location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Basic'
    }    
    firewallPolicy: {
      id: firewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'name'
        properties: {
          subnet: {
            id: FirewallSubnet
          }
          publicIPAddress: {
            id: FWPIP.id
          }
        }
      }
    ]
  }  
}



/*################
#    Outputs    #
################*/
