/*##################
#    Parameters    #
##################*/
param Location string
param NamePrefix string
param AddressPrefix string


/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
module VNET 'Modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    Name: '${NamePrefix}-VNET'
    Location: Location
    AddressPrefix: AddressPrefix
  }
}

module AVDCore 'Modules/AVDCore.bicep' = {
  name: 'AVDCore'
  params: {
    HPName: '${NamePrefix}-HP'
    DesktopGroupName: '${NamePrefix}-DAG'
    AppGroupName: '${NamePrefix}-RAG'
    WorkspaceName: '${NamePrefix}-WS'
    Location: Location    
  }
}

/*################
#    Outputs    #
################*/
