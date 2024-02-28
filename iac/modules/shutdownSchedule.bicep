param name string
param location string = resourceGroup().location
param shutdownTime string = '0000'
param timeZoneId string = 'Eastern Standard Time'
param emailRecipient string = 'admin@contoso.com'

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' existing = {
  name: 'vm-${name}'
}

resource shutdownSchedule 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-vm-${name}'
  location: location
  properties: {
    status: 'Enabled'
    notificationSettings: {
      status: 'Enabled'
      timeInMinutes: 60
      notificationLocale: 'en'
      emailRecipient: emailRecipient
    }
    dailyRecurrence: {
       time: shutdownTime
    }
     timeZoneId: timeZoneId
     taskType: 'ComputeVmShutdownTask'
     targetResourceId: vm.id
  }
}
