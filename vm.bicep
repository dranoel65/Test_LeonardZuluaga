param vmName string

@description('The virtual machine size. Enter a Premium capable VM size if DiskType is entered as Premium_LRS')
param vmSize string = 'Standard_D2s_v3'

@description('The admin user name of the VM')
param adminUsername string = 'testleonard'

@description('The admin password of the VM')
@secure()
param adminPassword string

@description('The Storage type of the data Disks')
@allowed([
  'StandardSSD_LRS'
  'Standard_LRS'
  'Premium_LRS'
])
param diskType string

param OSpublisher string
param OSoffer string 
param OSsku string            
param OSversion string

@description('The number of data disks to create')
param dataDisksCount int

var OSDiskName = '${vmName}-OSDisk'

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: vmName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      osDisk: {
        osType: 'Windows'
        name: OSDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: diskType
        }
        diskSizeGB: 128
      }
      imageReference: {
        publisher: OSpublisher
        offer: OSoffer
        sku: OSsku
        version: OSversion
      }
      dataDisks: [for j in range(0, dataDisksCount): {
        name: '${vmName}-DataDisk${j}'
        diskSizeGB: 256
        lun: j
        createOption: 'Empty'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }]
    }
//    networkProfile: {
//      networkInterfaces: [
//        {
//          id: nic.id
//        }
//      ]
//    }
  }
}
