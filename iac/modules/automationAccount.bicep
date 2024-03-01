param name string
param location string
param skuName string = 'Basic'
param skuFamily string = 'B'
param skuCapacity int = 2
param version string = ''
param decryptionKey string
param validationKey string

param baseTime string = utcNow()

var configurationName = 'ServerConfiguration'
var bundleName = '${configurationName}${empty(version) ? '' : '-v${version}'}.ps1'
var packageName = 'WebDeploy${empty(version) ? '' : '-v${version}'}.zip'

var sasProperties = {
  canonicalizedResource: '/blob/${storageAccount.name}'
  signedResourceTypes: 'sco'
  signedPermission: 'rl'
  signedExpiry: dateTimeAdd(baseTime, 'PT1H')
  signedProtocol: 'https'
  signedServices: 'b'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: 'stg${replace(name, '-', '')}'
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource configContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'configurations'
  parent: blobService
}

resource deployContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' existing = {
  name: 'deployments'
  parent: blobService
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: 'aa-${name}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
  }
}

resource webAdministration 'Microsoft.Automation/automationAccounts/modules@2023-11-01' = {
  name: 'xWebAdministration'
  parent: automationAccount
  properties: {
    contentLink: {
      uri: 'https://www.powershellgallery.com/api/v2/package/xWebAdministration/3.3.0'
    }
  }
}

resource configuration 'Microsoft.Automation/automationAccounts/configurations@2023-11-01' = {
  parent: automationAccount
  name: configurationName
  location: location
  properties: {
    source: {
      type: 'uri'
      value: '${storageAccount.properties.primaryEndpoints.blob}${configContainer.name}/${bundleName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
      version: version
    }
  }
}

resource nodeConfiguration 'Microsoft.Automation/automationAccounts/nodeConfigurations@2023-11-01' = {
  parent: automationAccount
  name: '${configuration.name}.localhost'
  properties: {
    configuration: {
      name: configuration.name
    }
    source: {
      type: 'uri'
      value: '${storageAccount.properties.primaryEndpoints.blob}${configContainer.name}/${bundleName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
      version: version
    }
    incrementNodeConfigurationBuild: true
  }
}

resource compilationJob 'Microsoft.Automation/automationAccounts/compilationjobs@2019-06-01' = {
  parent: automationAccount
  name: guid(automationAccount.id, configuration.name, version)
  dependsOn: [
    webAdministration
  ]
  properties: {
    configuration: {
      name: configuration.name
    }
    parameters: {
      siteName: name
      applicationPool: replace(name, '-', '')
      packageUrl: '${storageAccount.properties.primaryEndpoints.blob}${deployContainer.name}/${packageName}?${storageAccount.listAccountSas('2021-04-01', sasProperties).accountSasToken}'
      packageName: packageName
      decryptionKey: decryptionKey
      validationKey: validationKey
    }
  }
}
