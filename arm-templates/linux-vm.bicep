// TODO - Modularise this template further using linked templates: https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/linked-templates
// TODO - Dynamically handle provisioning of VMs in multiple availability zones
// TODO - Implement retrieval of credentials from a secret store (e.g. Azure Key Vault): https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/key-vault-parameter?tabs=azure-cli

// @allowed([
//   'asia'
//   'asiapacific'
//   'australia'
//   'australiacentral'
//   'australiacentral2'
//   'australiaeast'
//   'australiasoutheast'
//   'brazil'
//   'brazilsouth'
//   'brazilsoutheast'
//   'canada'
//   'canadacentral'
//   'canadaeast'
//   'centralindia'
//   'centralus'
//   'centraluseuap'
//   'eastasia'
//   'eastus'
//   'eastus2'
//   'eastus2euap'
//   'europe'
//   'france'
//   'francecentral'
//   'francesouth'
//   'germany'
//   'germanynorth'
//   'germanywestcentral'
//   'global'
//   'india'
//   'israel'
//   'israelcentral'
//   'italy'
//   'italynorth'
//   'japan'
//   'japaneast'
//   'japanwest'
//   'korea'
//   'koreacentral'
//   'koreasouth'
//   'mexicocentral'
//   'newzealand'
//   'northcentralus'
//   'northeurope'
//   'norway'
//   'norwayeast'
//   'norwaywest'
//   'poland'
//   'polandcentral'
//   'qatar'
//   'qatarcentral'
//   'singapore'
//   'southafrica'
//   'southafricanorth'
//   'southafricawest'
//   'southcentralus'
//   'southeastasia'
//   'southindia'
//   'spaincentral'
//   'sweden'
//   'swedencentral'
//   'switzerland'
//   'switzerlandnorth'
//   'switzerlandwest'
//   'uaecentral'
//   'uaenorth'
//   'uksouth'
//   'ukwest'
//   'unitedstates'
//   'westcentralus'
//   'westeurope'
//   'westindia'
//   'westus'
//   'westus2'
//   'westus3'
// ])
param location string = resourceGroup().location
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
  'UltraSSD_LRS'
])
@metadata({
  description: 'The OS disk tier.'
})
param osDiskTier string = 'StandardSSD_LRS'
param vmName string
param vNetName string = ''
param subnetName string = ''
param vmSize string
param adminUsername string = 'azureuser'
@secure()
param adminPublicKey string = ''
param vTpmEnabled bool = true
param secureBootEnabled bool = true
param hibernationEnabled bool = true
param securityType string = 'TrustedLaunch'
param linuxImageReference object = {
  publisher: 'canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server-arm64'
  version: 'latest'
}
param tags object

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: '${vmName}-ip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vNetName}_${subnetName}_config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(resourceGroup().name, 'Microsoft.Network/virtualNetworks/subnets', vNetName, subnetName)
          }
          publicIPAddress: {
            id: publicIPAddress.id
            properties: {
              deleteOption: 'Delete'
            }
          }
        }
      }
    ]
  }
  tags: tags
}

resource linuxVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: adminPublicKey
            }
          ]
        }
      }
    }
    storageProfile: {
      imageReference: linuxImageReference
      osDisk: {
        name: '${vmName}-os-disk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskTier
        }
        deleteOption: 'Delete'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    securityProfile: {
      securityType: securityType
      uefiSettings: {
        secureBootEnabled: secureBootEnabled
        vTpmEnabled: vTpmEnabled
      }
    }
    additionalCapabilities: {
      hibernationEnabled: hibernationEnabled
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: tags
}
