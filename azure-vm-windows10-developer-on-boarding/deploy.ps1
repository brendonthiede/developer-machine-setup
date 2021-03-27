[CmdletBinding()]
#Requires -Version 5
#Requires -Modules @{ ModuleName="AzureRM.Profile"; ModuleVersion="4.6.0" }
#Requires -Modules @{ ModuleName="AzureRM.Resources"; ModuleVersion="5.5.2" }

<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template

 .PARAMETER subscriptionName
    The subscription id where the template will be deployed.

 .PARAMETER resourceGroupName
    Optional, the resource group where the template will be deployed. Can be the name of an existing or a new resource group. Defaults to developer-onboarding-rg.

 .PARAMETER resourceGroupLocation
    Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.

 .PARAMETER windowsMachineName
    Optional, the name to give the Windows VM. Defaults to devmachine.

 .PARAMETER templateFilePath
    Optional, path to the template file. Defaults to template.json.

 .PARAMETER skipConfirmation
    Optional. If provided, user will not be prompted to confirm deployment.
#>

param(
  [Parameter(Mandatory = $False)]
  [string]
  $subscriptionName = "",

  [string]
  $resourceGroupName = "developer-onboarding-rg",

  [string]
  $resourceGroupLocation = "East US",

  [string]
  $windowsMachineName = "devmachine",

  [string]
  $templateFilePath = "$PSScriptRoot\template.json",

  [pscredential]
  $windowsAdminCredentials = (Get-Credential -Message "Provide credentials to use for the Windows Admin" -UserName "$($windowsMachineName)admin"),

  [switch]
  $SkipConfirmation
)

<#
.SYNOPSIS
    Registers RPs
#>
Function RegisterRP {
  Param(
    [string]$ResourceProviderNamespace
  )

  Write-Host "Registering resource provider '$ResourceProviderNamespace'";
  Register-AzureRmResourceProvider -ProviderNamespace $ResourceProviderNamespace;
}

#******************************************************************************
# Script body
# Execution begins here
#******************************************************************************
$ErrorActionPreference = "Stop"

if ($subscriptionName -eq "") {
  Write-Host "You must provide a subscrition name"
  Write-Host "To see a list of subscriptions for the current account, run`n Get-AzureRmSubscription | select -Property Name"
  exit 1
}
Try {
  # Try once to see if we're logged in
  Get-AzureRmContext | Out-Null;
  $loggedInSubscriptionName = (Get-AzureRmContext).Subscription.Name;
  if ($null -ne $loggedInSubscriptionName) {
    # Try switching subscriptions (to test the enrollment that you're logged into is correct)
    Write-Host "Attempting to switch to subscription '$subscriptionName' with your existing login.";
    Set-AzureRmContext -SubscriptionName $subscriptionName -ErrorAction SilentlyContinue | Out-Null;
    if (-not $?) {
      $loggedInSubscriptionName = "";
    }
    else {
      # Make sure that you really are logged in and grab the active subscription
      $loggedInSubscriptionName = (Get-AzureRmContext).Subscription.Name;
      Write-Host "You are already logged into $loggedInSubscriptionName";
    }
  }
}
Catch {
  $loggedInSubscriptionName = "";
}

if ($loggedInSubscriptionName -ne $subscriptionName) {
  Write-Host "Logging in...";
  Connect-AzureRmAccount -Environment $azureEnvironment -SubscriptionName $subscriptionName;
  if (-not $?) {
    Write-Host "Login was cancelled"
    exit 1
  }
  Write-Host "Selecting subscription '$subscriptionName'";
  Set-AzureRmContext -SubscriptionName $subscriptionName | Out-Null;
}

# Register RPs
$resourceProviders = @("microsoft.network", "microsoft.compute", "microsoft.storage", "microsoft.devtestlab");
if ($resourceProviders.length) {
  Write-Host "Registering resource providers"
  foreach ($resourceProvider in $resourceProviders) {
    RegisterRP($resourceProvider);
  }
}

#Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue
if (!$resourceGroup) {
  Write-Host "Resource group '$resourceGroupName' does not exist. To create a new resource group, please enter a location.";
  if (!$resourceGroupLocation) {
    $resourceGroupLocation = Read-Host "resourceGroupLocation";
  }
  Write-Host "Creating resource group '$resourceGroupName' in location '$resourceGroupLocation'";
  New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation -Verbose:$VerbosePreference
}
else {
  Write-Host "Using existing resource group '$resourceGroupName'";
}
Write-Host "Adding tags to $resourceGroupName"
Set-AzureRmResourceGroup -Name $resourceGroupName -Tag @{ owner = "devops"; purpose = "testing" }

Write-Host "Preparing to deploy $windowsMachineName to $resourceGroupName"

if (!$SkipConfirmation) {
  Write-Host "Continue? (Y/N)"
  $KeyPress = $null
  $KeyOption = 'Y', 'N'
  while ($KeyOption -notcontains $KeyPress.Character) {
    $KeyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
  }
  if ($KeyPress.Character -ne 'Y') {
    Write-Host "Aborting deployment"
    exit 1
  }
}

# Determine latest Win10 VM
$Sku = (Get-AzureRmVMImageSku `
    -Location $resourceGroupLocation `
    -PublisherName "MicrosoftWindowsDesktop" `
    -Offer "Windows-10" |
    Where-Object {
    $_.Skus -match "^rs[0-9]+-pro$"
  } |
    Sort-Object {
    [convert]::ToInt32("$([regex]::match($_.Skus, '^rs([0-9]+)-pro$').Groups[1].Value)", 10)
  } -Descending -ErrorAction SilentlyContinue)[0]
$imageReference = @{ publisher = $Sku.PublisherName; offer = $Sku.Offer; sku = $Sku.Skus; version = "latest" }
Write-Host "Using image reference sku $($imageReference.sku)"

# Start the deployment
Write-Host "Starting deployment...";
New-AzureRmResourceGroupDeployment `
  -ResourceGroupName $resourceGroupName `
  -TemplateFile $templateFilePath `
  -adminUsername $windowsAdminCredentials.UserName `
  -adminPassword $windowsAdminCredentials.Password `
  -imageReference $imageReference `
  -Verbose:$VerbosePreference;
