/*##################
#    Parameters    #
##################*/
param HPName string
param DesktopGroupName string
param AppGroupName string
param WorkspaceName string
param Location string


/*#################
#    Variables    #
#################*/


/*##################
#    Resources    #
##################*/
resource HostPool 'Microsoft.DesktopVirtualization/hostPools@2024-08-08-preview' = {
  name: HPName
  location: Location
  properties: {
    friendlyName: HPName
    hostPoolType: 'Pooled'
    loadBalancerType: 'BreadthFirst'
    preferredAppGroupType: 'RailApplications'
    maxSessionLimit: 10
    validationEnvironment: true
    startVMOnConnect: true
    registrationInfo: {
      expirationTime: dateTimeAdd('2025-01-27 00:00:00Z', 'P31D')
      registrationTokenOperation: 'Update'
    }
  }
}

resource AppDesktop 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: DesktopGroupName
  location: Location
  properties: {
    friendlyName: 'Desktop'
    applicationGroupType: 'Desktop'
    hostPoolArmPath: HostPool.id
  }
}

resource AppRemote 'Microsoft.DesktopVirtualization/applicationGroups@2024-08-08-preview' = {
  name: AppGroupName
  location: Location
  properties: {
    friendlyName: 'RemoteApps'
    applicationGroupType:'RemoteApp'
    hostPoolArmPath: HostPool.id
  }
}

resource Workspace 'Microsoft.DesktopVirtualization/workspaces@2024-08-08-preview' = {
  name: WorkspaceName
  location: Location
  properties: {
    friendlyName: 'friendlyName'
    applicationGroupReferences: [
      AppDesktop.id
      AppRemote.id
    ]
  }
}


/*################
#    Outputs    #
################*/
output HostPoolID string = HostPool.id
output AppDesktopID string = AppDesktop.id
output AppRemoteID string = AppRemote.id
output WorkspaceID string = Workspace.id
output HostPoolName string = HostPool.listRegistrationTokens().value[0].token
