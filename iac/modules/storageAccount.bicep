param name string
param location string
param kind string = 'StorageV2'
param sku string = 'Standard_LRS'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource serviceSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'services'
  parent: virtualNetwork
}

resource scriptSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: 'scripts'
  parent: virtualNetwork
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
  name: 'stg${replace(name,'-','')}'
  location: location
  kind: kind
  sku: {
    name: sku
  }
  properties: {
    networkAcls: {
      bypass: 'Logging, Metrics, AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: [
        {
          action: 'Allow'
          id: serviceSubnet.id
        }
        {
          action: 'Allow'
          id: scriptSubnet.id
        }
      ]
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource configContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'configurations'
  parent: blobService
}

resource deployContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'deployments'
  parent: blobService
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = {
  name: 'pe-${name}'
  location: location
  properties: {
    subnet: {
      id: serviceSubnet.id
    }
    privateLinkServiceConnections: [
      {
        name: 'pls-${name}'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${environment().suffixes.storage}'
  location: 'global'
}

resource zoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: 'link-${privateDnsZone.name}'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.id
    }
  }
}


resource zoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: 'zg-${name}'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}
