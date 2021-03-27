#Requires -Version 5
#Requires -RunAsAdministrator

[CmdletBinding()]
param (
    # User credentials in order to log in automatically after a reboot
    [Parameter(Mandatory = $false)]
    [pscredential]
    $WindowsCredentials = (Get-Credential -Message "Enter the Windows credentials to use after a reboot" -UserName "$env:USERDOMAIN\$env:USERNAME"),

    # Time zone to use for the VM
    [Parameter(Mandatory = $false)]
    [string]
    $TimeZone = "Eastern Standard Time"
)

. "$PSScriptRoot\common.ps1"

function InstallBoxStarter {
    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingInvokeExpression", "")]
    param ()
    if (!(Get-Command Install-BoxstarterPackage -ErrorAction SilentlyContinue)) {
        LogInfo "Installing BoxStarter"
        . { Invoke-WebRequest -UseBasicParsing https://boxstarter.org/bootstrapper.ps1 } | Invoke-Expression; Get-Boxstarter -Force -Verbose:$VerbosePreference
    }
}

function InstallBoxstarterRecipes {
    param(
        [object[]] $Recipes,
        [pscredential] $Credentials
    )
    $common = "$env:USERPROFILE\common.ps1"
    $package = "$env:USERPROFILE\package.ps1"

    Copy-Item -Path "$PSScriptRoot\common.ps1" -Destination $common -Force

    Get-Content $PSScriptRoot\recipe-header.ps1 | Set-Content $package
    foreach ($recipe in $Recipes) {
        LogInfo "Adding content of $($recipe.RecipeName) to boxstarter package"
        Get-Content $recipe.Path | Add-Content $package
    }
    Get-Content $PSScriptRoot\recipe-footer.ps1 | Add-Content $package
    LogInfo "The computer may restart of you continue. Save all work and close all other programs."
    Read-Host -Prompt "Press enter to continue"
    LogInfo "Running package from $package"
    Install-BoxstarterPackage -PackageName $package -Credential $Credentials -Verbose:$VerbosePreference
}

$recipes = GetRecipeList
if ($recipes.Count -eq 0) {
    Write-Error "No recipes to install"
    exit 1
}
else {
    $devmachineCoreRecipe = $recipes | Where-Object { $_.RecipeName -eq "devmachine-core" }
    if ($devmachineCoreRecipe) {
        $gitUserName = Read-Host -Prompt "Enter your Git user name (First Last)"
        $gitEmailAddress = Read-Host -Prompt "Enter your Git email address (leave blank to use $env:USERNAME`@courts.mi.gov)"
        if ($gitEmailAddress.Length -eq 0) {
            $gitEmailAddress = "$env:USERNAME`@courts.mi.gov"
        }
        SetBoxStarterParams -GitUserName $gitUserName -GitEmailAddress $gitEmailAddress
    }
        
    Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
    SetTimeZone "$TimeZone"
    if (!(Test-Path $PROFILE)) {
        New-Item -Path $PROFILE -ItemType File -Force
        '# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}' | Set-Content -Path $PROFILE
    }
    InstallBoxStarter
    InstallBoxstarterRecipes -Recipes $recipes -Credentials $WindowsCredentials
}
