/*##################
#    Parameters    #
##################*/
param HPName string
param DesktopGroupName string
param AppGroupName string
param WorkspaceName string
param ScalingPlanName string
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
      expirationTime: dateTimeAdd('2025-02-12 00:00:00Z', 'P30D')
      registrationTokenOperation: 'Update'
    }
    customRdpProperty: 'networkautodetect:i:1;audiomode:i:0;videoplaybackmode:i:1;bandwidthautodetect:i:1;autoreconnection enabled:i:1;devicestoredirect:s:*;redirectcomports:i:0;redirectsmartcards:i:0;enablerdsaadauth:i:1;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:0;compression:i:1;audiocapturemode:i:1;encode redirected video capture:i:1;redirected video capture encoding quality:i:1;camerastoredirect:s:*;redirectlocation:i:1;screen mode id:i:2;smart sizing:i:1;dynamic resolution:i:1;'
    agentUpdate: {
       maintenanceWindows: [
         {
          dayOfWeek:'Saturday'
          hour: 2
         }
       ]
       maintenanceWindowTimeZone: 'EST'
       type: 'Scheduled'
       useSessionHostLocalTime: true
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

resource ScalingPlan 'Microsoft.DesktopVirtualization/scalingplans@2024-04-08-preview' = {
  name: ScalingPlanName
  location: Location  
  properties: {
    friendlyName: 'AVD Scaling Plan'
    timeZone: 'Eastern Standard Time'
    hostPoolType: 'Pooled'
    schedules: [
      {
        rampUpStartTime: {
          hour: 9
          minute: 0
        }
        peakStartTime: {
          hour: 9
          minute: 30
        }
        rampDownStartTime: {
          hour: 18
          minute: 0
        }
        offPeakStartTime: {
          hour: 22
          minute: 0
        }
        name: 'weekdays_schedule'
        daysOfWeek: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        rampUpLoadBalancingAlgorithm: 'BreadthFirst'
        rampUpMinimumHostsPct: 100
        rampUpCapacityThresholdPct: 60
        peakLoadBalancingAlgorithm: 'DepthFirst'
        rampDownLoadBalancingAlgorithm: 'DepthFirst'
        rampDownMinimumHostsPct: 100
        rampDownCapacityThresholdPct: 90
        rampDownForceLogoffUsers: true
        rampDownWaitTimeMinutes: 30
        rampDownNotificationMessage: 'You will be logged off in 30 min. Make sure to save your work.'
        rampDownStopHostsWhen: 'ZeroSessions'
        offPeakLoadBalancingAlgorithm: 'DepthFirst'
      }
    ]
    hostPoolReferences: [
      {
        hostPoolArmPath: HostPool.id
        scalingPlanEnabled: true
      }
    ]
  }
}


/*################
#    Outputs    #
################*/
output HostPoolName string = HostPool.name
output HostPoolToken string = HostPool.listRegistrationTokens().value[0].token
