param name string
param location string
param skuName string = 'Basic'
param skuTier string = 'Regional'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' existing = {
  name: 'ip-${name}'
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'vnet-${name}'
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-11-01' existing = {
  name: 'nsg-${name}'
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'nic-${name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'default'
        type: 'Microsoft.Network/networkInterfaces/ipConfigurations'
        properties: {
          publicIPAddress: {
            id: publicIPAddress.id
            properties: {
              deleteOption: 'Detach'
            }
            sku: {
              name: skuName
              tier: skuTier
            }
          }
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}
