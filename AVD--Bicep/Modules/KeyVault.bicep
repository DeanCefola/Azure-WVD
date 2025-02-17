/*##################
#    Parameters    #
##################*/
param KVName string
param Location string
@secure()
param AdminPassword string

/*#################
#    Variables    #
#################*/
var KVURL = 'https://${KVName}.vault.azure.net/'


/*##################
#    Resources    #
##################*/
resource KVName_resource 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: KVName
  location: Location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    vaultUri: KVURL
    provisioningState: 'Succeeded'
    publicNetworkAccess: 'Enabled'
  }
}

resource KVName_DomainJoin_Password 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: KVName_resource
  name: 'DomainJoin--Password'    
  properties: {
    attributes: {
      enabled: true
    }
    value:AdminPassword
  }
}

resource KVName_DomainJoin_User 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: KVName_resource
  name: 'DomainJoin--UserName'
  properties: {
    attributes: {
      enabled: true
    }
    value:'adjoin@MSAzureAcademy.com'
  }
}

resource KVName_LocalAdmin_Password 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: KVName_resource
  name: 'LocalAdmin--Password'  
  properties: {
    attributes: {
      enabled: true
    }
    value:AdminPassword
  }
}

resource KVName_LocalAdmin_User 'Microsoft.KeyVault/vaults/secrets@2024-04-01-preview' = {
  parent: KVName_resource
  name: 'LocalAdmin--UserName'
  properties: {
    attributes: {
      enabled: true
    }
    value: 'lntad'
  }
}

/*################
#    Outputs    #
################*/
