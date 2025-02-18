param storageAccounts_wvdfslogixeast00_name string = 'wvdfslogixeast00'
param scalingplans_Scaling_Cloud_VDI_name string = 'Scaling-Cloud-VDI'

resource scalingplans_Scaling_Cloud_VDI_name_resource 'Microsoft.DesktopVirtualization/scalingplans@2024-04-08-preview' = {
  name: scalingplans_Scaling_Cloud_VDI_name
  location: 'eastus2'
  tags: {
    Application: 'Cloud VDI'
    'cost center': 'AA-Money'
    Environment: 'Dev'
    Owner: 'AVD Admin'
    'Support Contact': 'x1234'
  }
  properties: {
    friendlyName: scalingplans_Scaling_Cloud_VDI_name
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
    hostPoolReferences: []
  }
}

resource scalingplans_Scaling_Cloud_VDI_name_weekdays_schedule 'Microsoft.DesktopVirtualization/scalingplans/pooledSchedules@2024-04-08-preview' = {
  parent: scalingplans_Scaling_Cloud_VDI_name_resource
  name: 'weekdays_schedule'
  properties: {
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
}

resource storageAccounts_wvdfslogixeast00_name_default_appattach 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: '${storageAccounts_wvdfslogixeast00_name}/default/appattach'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 1024
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    resourceId('Microsoft.Storage/storageAccounts/fileServices', storageAccounts_wvdfslogixeast00_name, 'default')
    resourceId('Microsoft.Storage/storageAccounts', storageAccounts_wvdfslogixeast00_name)
  ]
}

resource storageAccounts_wvdfslogixeast00_name_default_fslogix 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-05-01' = {
  name: '${storageAccounts_wvdfslogixeast00_name}/default/fslogix'
  properties: {
    accessTier: 'TransactionOptimized'
    shareQuota: 1024
    enabledProtocols: 'SMB'
  }
  dependsOn: [
    resourceId('Microsoft.Storage/storageAccounts/fileServices', storageAccounts_wvdfslogixeast00_name, 'default')
    resourceId('Microsoft.Storage/storageAccounts', storageAccounts_wvdfslogixeast00_name)
  ]
}
