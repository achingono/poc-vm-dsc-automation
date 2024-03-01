param name string
param location string
param version string = ''

var configurationName = 'ServerConfiguration'
var bundleName = '${configurationName}${empty(version) ? '' : '-v${version}'}.ps1'

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
    scriptContent: 'echo "$CONTENT" > ${bundleName} && az storage blob upload --file ${bundleName} --container-name ${configContainer.name} --name ${bundleName}'
  }
}
