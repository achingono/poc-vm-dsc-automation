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
var packageName = 'WebDeploy.zip'

var sasProperties = {
  canonicalizedResource: '/blob/${storageAccount.name}'
  signedResourceTypes: 'sco'
  signedPermission: 'rltf'
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

resource uploadScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: 'ds-upload-configuration'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: loadTextContent('../../dsc/${configurationName}.ps1')
      }
    ]
    scriptContent: 'echo "$CONTENT" > ${bundleName} && az storage blob upload -f ${bundleName} -c ${configContainer.name} -n ${bundleName} --overwrite'
  }
}

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' = {
  name: 'aa-${name}'
  location: location
  properties: {
    sku: {
      name: skuName
      family: skuFamily
      capacity: skuCapacity
    }
  }
}

resource configuration 'Microsoft.Automation/automationAccounts/configurations@2023-11-01' = {
  parent: automationAccount
  dependsOn: [ uploadScript ]
  name: configurationName
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
    incrementNodeConfigurationBuild: true
  }
}

resource compilationJob 'Microsoft.Automation/automationAccounts/compilationjobs@2019-06-01' = {
  parent: automationAccount
  name: guid(automationAccount.id)
  properties: {
    configuration: {
      name: nodeConfiguration.name
    }
    parameters: {
      siteName: name
      applicationPool: replace(name, '-', '')
      packageUrl: '${storageAccount.properties.primaryEndpoints.blob}${deployContainer.name}/${packageName}'
      packageName: packageName
      decryptionKey: decryptionKey
      validationKey: validationKey
    }
  }
}