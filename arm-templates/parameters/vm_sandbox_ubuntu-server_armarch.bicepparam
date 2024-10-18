using '../linux-vm.bicep'

param osDiskType = 'StandardSSD_LRS'
param virtualMachineName = 'sandbox-ubuntu-server-vm'
param virtualMachineSize = 'Standard_D2ps_v6'
param isVTpmEnabled = true
param isSecureBootEnabled = true
param isHibernationEnabled = false
param linuxImageReference = {
  publisher: 'canonical'
  offer: 'ubuntu-24_04-lts'
  sku: 'server-arm64'
  version: 'latest'
}
param tags = {
  environment: 'sandbox'
}
