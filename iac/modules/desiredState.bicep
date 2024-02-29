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
    typeHandlerVersion: '2.9'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      Items: {
        registrationKeyPrivate: automationAccount.listKeys().keys[0].Value
      }
    }
    settings: {
      advancedOptions: {
        forcePullAndApply: true
      }
      properties: [
        {
          Name: 'RegistrationKey'
          Value: {
            UserName: 'PLACEHOLDER_DONOTUSE'
            Password: 'PrivateSettingsRef:registrationKeyPrivate'
          }
          TypeName: 'System.Management.Automation.PSCredential'
        }
        {
          Name: 'RegistrationUrl'
          Value: reference('Microsoft.Automation/automationAccounts/${automationAccount.name}', '2023-11-01').registrationUrl
          TypeName: 'System.String'
        }
        {
          Name: 'NodeConfigurationName'
          Value: 'ServerConfiguration.localhost'
          TypeName: 'System.String'
        }
        {
          Name: 'ConfigurationMode'
          Value: 'ApplyandMonitor'
          TypeName: 'System.String'
        }
        {
          Name: 'RebootNodeIfNeeded'
          Value: true
          TypeName: 'System.Boolean'
        }
        {
          Name: 'ActionAfterReboot'
          Value: 'ContinueConfiguration'
          TypeName: 'System.String'
        }
        {
          Name: 'RefreshFrequencyMins'
          Value: '30'
          TypeName: 'System.Int32'
        }
        {
          Name: 'ConfigurationModeFrequencyMins'
          Value: '15'
          TypeName: 'System.Int32'
        }
      ]
    }
  }
}

