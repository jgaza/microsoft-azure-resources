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
@description('The OS disk tier.')
param osDiskType string = 'StandardSSD_LRS'
param virtualMachineName string
param virtualNetworkName string = ''
param subnetName string = ''
param virtualMachineSize string
param adminUsername string = 'azureuser'
@secure()
param adminPublicKey string = ''
param isVTpmEnabled bool = true
param isSecureBootEnabled bool = true
param isHibernationEnabled bool = true
param securityType string = 'TrustedLaunch'
param pipDeleteOption string = 'Delete'
param nicDeleteOption string = 'Delete'
param osDiskDeleteOption string = 'Delete'
param linuxImageReference object = {
  publisher: 'canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server-arm64'
  version: 'latest'
}
param tags object

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2024-01-01' = {
  name: '${virtualMachineName}-ip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2024-01-01' = {
  name: '${virtualMachineName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${virtualNetworkName}_${subnetName}_config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(
              resourceGroup().name,
              'Microsoft.Network/virtualNetworks/subnets',
              virtualNetworkName,
              subnetName
            )
          }
          publicIPAddress: {
            id: publicIPAddress.id
            properties: {
              deleteOption: pipDeleteOption
            }
          }
        }
      }
    ]
  }
  tags: tags
}

resource linuxVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: virtualMachineName
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
        name: '${virtualMachineName}-os-disk'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        deleteOption: osDiskDeleteOption
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: nicDeleteOption
          }
        }
      ]
    }
    securityProfile: {
      securityType: securityType
      uefiSettings: {
        secureBootEnabled: isSecureBootEnabled
        vTpmEnabled: isVTpmEnabled
      }
    }
    additionalCapabilities: {
      hibernationEnabled: isHibernationEnabled
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  tags: tags
}
