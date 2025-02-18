/*##################
#    Parameters    #
##################*/
param FWName string
param Location string
param FirewallSubnet string
param FWMgtSubnet string

/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
resource FWMgtPIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: '${FWName}-MgtPIP'
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

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
    managementIpConfiguration: {
      name: 'ManagementIPConfig'
      properties: {
        publicIPAddress: {
          id: FWMgtPIP.id
        }
      subnet: {
        id: FWMgtSubnet        
      }
      }
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
