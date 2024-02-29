param name string
param location string
param version string = ''

var configurationName = 'ServerConfiguration'
var bundleName = '${configurationName}${empty(version) ? '' : '-v${version}'}.ps1'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'default'
  parent: virtualNetwork
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

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'uai-${name}'
  location: location
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-file-data-privileged-contributor
resource fileRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: '69566ab7-960f-475b-8e7c-b3118f30c6bd'
}

// https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
resource blobRole 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
}

resource fileAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  
  name: guid(fileRole.id, identity.id, storageAccount.id)
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: fileRole.id
    principalType: 'ServicePrincipal'
  }
}


resource blobAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storageAccount
  
  name: guid(blobRole.id, identity.id, storageAccount.id)
  properties: {
    principalId: identity.properties.principalId
    roleDefinitionId: blobRole.id
    principalType: 'ServicePrincipal'
  }
}

resource uploadScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'ds-upload-configuration'
  location: location
  kind: 'AzureCLI'
  // https://github.com/Azure/bicep/issues/6540#issuecomment-1751457986
  identity: {
    type: 'userAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.26.1'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    storageAccountSettings: {
      storageAccountName: storageAccount.name
    }
    containerSettings: {
      subnetIds: [
        {
          id: subnet.id
        }
      ]
    }
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
