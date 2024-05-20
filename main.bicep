targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'LeonardZuluagaRG'
  location: 'eastus'
}

module vm './vm.bicep' = {
  name: 'vm_Leo'
  scope: rg
  params: {
    vmName: 'vm_leonardZuluaga'
    adminPassword: 'DrAnOeL1!'
    vmSize: 'Standard_D2s_v3'
    diskType: 'StandardSSD_LRS'
    OSpublisher: 'MicrosoftWindowsServer'
    OSoffer: 'WindowsServer'
    OSsku: '2022-Datacenter'  
    OSversion: 'latest'
    dataDisksCount: 1
    nsgName: 'leoNSG'
  }
}
