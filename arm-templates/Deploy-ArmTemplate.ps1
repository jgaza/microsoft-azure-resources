
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
