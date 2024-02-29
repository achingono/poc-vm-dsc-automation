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

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' = {
  name: 'default'
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
