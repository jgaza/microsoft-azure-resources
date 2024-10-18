<#
.SYNOPSIS
    A script for deploying ARM templates to Azure.

.DESCRIPTION
    This script enables deploying Azure resources through the Azure Reource Manager (ARM) by using valid template files in either the JSON or Bicep format.
	It also accepts parameters passed using a paramater file, or inline (or both simultaneously).

	The script uses either the native 'New-AzResourceGroupDeployment' cmdlet (default), or the Azure CLI to initiate the deployment.

.PARAMETER ResourceGroupName
    The name of the target Resource Group to which the resources described by the ARM template should be deployed.

.PARAMETER TemplateFilePath
    The relative or absolute path to the '.json' or '.bicep' template file (JSON or Bicep format).

.PARAMETER TemplateParameterFilePath
    Optional. The relative or absolute path to the '.json' or '.bicepparam' parameter file.

.PARAMETER AzCli
    Optional switch parameter. If specified, invokes the Azure CLI for parsing the ARM template and initiating the deployment.

.PARAMETER InlineParameter
    Optional. An ordered dictionary containing additional parameters to be passed to the ARM template and not already specified in a parameter file.

.EXAMPLE
	$inlineParameters = [ordered] @{
		AdditionalParam1 = 'value1';
		AdditionalParam2 = 'value2';
		SecretParam = Read-Host -AsSecureString
	}

	& .\Deploy-SandboxUbuntuVM.ps1 `
		-ResourceGroupName my-rg-name `
		-TemplateFilePath <path-to-template-file> `
		-TemplateParameterFilePath <path-to-parameter-file>  `
		-InlineParameter $inlineParameters `
		-AzCli

.NOTES
    This script is designed to work with PowerShell 7. Compatibility with PowerShell 5.1 is not guaranteed.

.LINK
	https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/
	https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-powershell
    https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deploy-cli
#>

[CmdletBinding()]
Param(
	$ResourceGroupName,
	$TemplateFilePath,
	[Parameter(Mandatory = $false)]
	$TemplateParameterFilePath,
	[Parameter(Mandatory = $false)]
	[switch] $AzCli,
	[Parameter(Mandatory = $False)]
	[hashtable] $InlineParameter
)

$date = Get-Date -Format 'MM-dd-yyyy_HHmm'
$templateFileName = (Get-ChildItem $TemplateFilePath).Name
$deploymentName = "$($date)_$($templateFileName)_template-deployment"

Write-Information "Deploying resource to Resource Group '$ResourceGroupName' using template '$templateFileName'"

if ($AzCli) {

	Write-Information 'Using Azure CLI...'

	$azCliCommand = "az deployment group create --name $deploymentName --resource-group $ResourceGroupName --template-file $TemplateFilePath"

	[string[]] $parameterArray = @()

	if	($TemplateParameterFilePath) {
		$parameterArray += $TemplateParameterFilePath
	}

	if ($InlineParameter -and 0 -lt $InlineParameter.Count) {

		$InlineParameter.GetEnumerator() | ForEach-Object {

			$parameterValue = ([System.Security.SecureString] -eq $_.Value.GetType()) ? (ConvertFrom-SecureString -AsPlainText -SecureString $_.Value) : $_.Value
			$parameterArray += "$($_.Key)=$parameterValue"

		}
	}

	if (0 -lt $parameterArray.Count) {
		$azCliCommand  += " --parameters $($parameterArray -join ' ' )"
	}

	Invoke-Expression $azCliCommand

} else {

	Write-Information 'Using PowerShell...'

	$psArguments = [ordered]  @{
		Name              = $deploymentName;
		ResourceGroupName = $ResourceGroupName;
		TemplateFile      = $TemplateFilePath
	}

	if	($TemplateParameterFilePath) {
		$psArguments.TemplateParameterFile = $TemplateParameterFilePath
	}

	$psArguments = ($InlineParameter -and 0 -lt $InlineParameter.Count) ? ($psArguments += $InlineParameter) : $psArguments

	New-AzResourceGroupDeployment @psArguments
}

Write-Information 'Resource deployment complete.'
