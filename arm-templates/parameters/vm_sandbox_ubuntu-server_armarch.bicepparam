using '../linux-vm.bicep'

param osDiskTier = 'StandardSSD_LRS'
param vmName = 'sandbox-ubuntu-server-vm'
param vmSize = 'Standard_D2ps_v6'
param vTpmEnabled = true
param secureBootEnabled = true
param hibernationEnabled = false
param linuxImageReference = {
  publisher: 'canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server-arm64'
  version: 'latest'
}
param tags = {
  environment: 'sandbox'
}
