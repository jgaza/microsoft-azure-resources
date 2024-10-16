$resourceGroupName = Read-Host -Prompt 'Please enter the name of the resource group to which the VM should be assigned'
$vNetName = Read-Host -Prompt 'Please enter the name of the VNet to which the VM should be connected'
$subNetName = Read-Host -Prompt 'Please enter the name of the subnet to which the VM should be connected'
$adminPublicKey = Read-Host -Prompt 'Please enter the public key to use for VM authentication' -AsSecureString

New-AzResourceGroupDeployment `
	-Name SandboxDeployment `
	-ResourceGroupName $resourceGroupName `
	-TemplateFile .\vm.json `
	-TemplateParameterFile .\parameters\vm_sandbox_ubuntu-server_armarch.json `
	-virtualNetworkName $vNetName `
	-subnetName $subNetName `
	-adminPublicKey $adminPublicKey
