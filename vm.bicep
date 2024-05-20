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

param nsgName string

var virtualNetworkName = '${toLower(vmName)}-vnet'
var subnetName = '${toLower(vmName)}-subnet'
var OSDiskName = '${vmName}-OSDisk'
var networkInterfaceName = '${vmName}-nic'
var publicIpAddressName = '${vmName}-ip'
//var networkSecurityGroupName = '${subnetName}-nsg'

var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var publicIPAddressType = 'Dynamic'

targetScope='resourceGroup'

//param resourceGroupName string
//param resourceGroup'eastus' string



resource pip 'Microsoft.Network/publicIPAddresses@2021-03-01' = {
  sku: {
    name: 'Basic'
  }
  name: publicIpAddressName
  location: 'eastus'
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: publicIPAddressType
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-03-01' = {
  name: nsgName
  location: 'eastus'
  properties: {}
}

resource nsgRuleRDP 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  parent: nsg
  name: 'test-allow-remote'
  properties: {
    priority: 1000
    access: 'Allow'
    direction: 'Inbound'
    destinationPortRange: '3389'
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
  }
}

resource nsgRuleHTTP 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  parent: nsg
  name: 'test-allow-http'
  properties: {
    priority: 2000
    access: 'Allow'
    direction: 'Inbound'
    destinationPortRange: '80'
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
  }
}

resource nsgRuleHTTPS 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  parent: nsg
  name: 'test-allow-https'
  properties: {
    priority: 3000
    access: 'Allow'
    direction: 'Inbound'
    destinationPortRange: '443'
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
  }
}

resource nsgRuleSQL 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  parent: nsg
  name: 'test-allow-sql'
  properties: {
    priority: 4000
    access: 'Allow'
    direction: 'Inbound'
    destinationPortRanges: ['1433', '1434']
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
    destinationAddressPrefix: '*'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-03-01' = {
 name: virtualNetworkName
 location: 'eastus'
 properties: {
   addressSpace: {
     addressPrefixes: [
       addressPrefix
     ]
   }
   subnets: [
     {
       name: subnetName
       properties: {
         addressPrefix: subnetPrefix
         networkSecurityGroup: {
           id: nsg.id
         }
       }
     }
   ]
 }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: networkInterfaceName
  location: 'eastus'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, subnetName)
          }
        }
      }
    ]
  }
}

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
   networkProfile: {
     networkInterfaces: [
       {
         id: nic.id
       }
     ]
   }
  }
}
