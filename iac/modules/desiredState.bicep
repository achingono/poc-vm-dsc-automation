param name string
param location string 

resource automationAccount 'Microsoft.Automation/automationAccounts@2023-11-01' existing = {
  name: 'aa-${name}'
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: 'vm-${name}'
}

resource dscExtension 'Microsoft.Compute/virtualMachines/extensions@2018-10-01' = {
  location: location
  parent: virtualMachine
  name: 'Microsoft.Powershell.DSC'
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      registrationKey: automationAccount.listKeys().keys[0].Value
      registrationUrl: automationAccount.properties.automationHybridServiceUrl
    }
  }
}
