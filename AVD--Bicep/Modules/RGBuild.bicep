/*##################
#    Parameters    #
##################*/
param Name string
param Location string


/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
targetScope = 'subscription'

resource RGShared 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: '${Name}-Shared'
  location: Location
}

resource RGAVD 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: '${Name}-AVD'
  location: Location
}


/*################
#    Outputs    #
################*/
output RGsharedName string = RGShared.name
output RGavdName string = RGAVD.name
