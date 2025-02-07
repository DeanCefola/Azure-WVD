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


/*################
#    Outputs    #
################*/
