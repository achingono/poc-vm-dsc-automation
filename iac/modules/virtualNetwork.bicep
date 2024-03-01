param name string
param location string

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: 'vnet-${name}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    enableDdosProtection: false
  }
}

resource serviceSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  name: 'services'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.1.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          location
        ]
      }
    ]
  }
}

resource scriptSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  name: 'scripts'
  parent: virtualNetwork
  properties: {
    addressPrefix: '10.0.2.0/24'
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        service: 'Microsoft.Storage'
        locations: [
          location
        ]
      }
    ]
    delegations: [
      {
        name: 'Microsoft.ContainerInstance.containerGroups'
        properties: {
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}
