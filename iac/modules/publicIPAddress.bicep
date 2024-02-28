param name string
param location string
param skuName string = 'Standard'
param skuTier string = 'Regional'

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-11-01' = {
  name: 'ip-${name}'
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
    dnsSettings: {
      domainNameLabel: name
    }
  }
}
