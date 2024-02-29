@minLength(1)
@maxLength(20)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param name string
param location string
param uniqueSuffix string
@secure()
param adminUsername string
@secure()
param adminPassword string
param version string = ''
param decryptionKey string
param validationKey string

var resourceName = '${name}-${uniqueSuffix}'

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: 'rg-${resourceName}-${location}'
  location: location
  tags: {
    'azd-env-name': name
  }
}

module publicIPAddress 'modules/publicIPAddress.bicep' = {
  name: '${deployment().name}--publicIPAddress'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module virtualNetwork 'modules/virtualNetwork.bicep' = {
  name: '${deployment().name}--virtualNetwork'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module networkSecurityGroup 'modules/networkSecurityGroup.bicep' = {
  name: '${deployment().name}--networkSecurityGroup'
  scope: resourceGroup
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module networkInterface 'modules/networkInterface.bicep' = {
  name: '${deployment().name}--networkInterface'
  scope: resourceGroup
  dependsOn: [
    publicIPAddress
    virtualNetwork
    networkSecurityGroup
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
  }
}

module storage 'modules/storageAccount.bicep' = {
  name: '${deployment().name}--storage'
  scope: resourceGroup
  dependsOn:[
    virtualNetwork
  ]
  params: {
    name: resourceName
    location: location
  }
}

module virtualMachine 'modules/virtualMachine.bicep' = {
  name: '${deployment().name}--vm'
  scope: resourceGroup
  dependsOn: [
    networkInterface
    storage
  ]
  params:{
    name: resourceName
    location: resourceGroup.location
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}

module blob 'modules/storageBlob.bicep' = {
  name: '${deployment().name}--blob'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
    storage
  ]
  params: {
    name: resourceName
  }
}

module share 'modules/storageFile.bicep' = {
  name: '${deployment().name}--share'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
    storage
  ]
  params: {
    name: resourceName
    shareName: name
  }
}

module shutdown 'modules/shutdownSchedule.bicep' = {
  name: '${deployment().name}--shutdown'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
  ]
  params: {
    name: resourceName
    location: location
  }
}

module automationAccount 'modules/automationAccount.bicep' = {
  name: '${deployment().name}--automationAccount'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
    storage
  ]
  params: {
    name: resourceName
    location: location
    version: version
    decryptionKey: decryptionKey
    validationKey: validationKey
  }
}

module desiredState 'modules/desiredState.bicep' = {
  name: '${deployment().name}--desiredState'
  scope: resourceGroup
  dependsOn: [
    virtualMachine
    automationAccount
  ]
  params: {
    name: resourceName
    location: location
  }
}
