. "$env:USERPROFILE\common.ps1"

Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowFileExtensions -EnableShowFullPathInTitleBar

# Enable updates aside from WSUS
SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "LocalSourcePath" -Value "" -Type "ExpandString"
SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Servicing" -Name "RepairContentServerSource" -Value "2" -Type "DWORD"

# Enable and enforce use of TLS 1.2
SetRegistryValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value "1" -Type "DWord"
SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" -Name "SchUseStrongCrypto" -Value "1" -Type "DWord"
SetRegistryValue -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value "1" -Type "DWord"
SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319" -Name "SystemDefaultTlsVersions" -Value "1" -Type "DWord"

# Start Menu: Disable Bing Search Results
SetRegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "BingSearchEnabled" -Value "0" -Type "DWord"
Disable-BingSearch

cinst sysinternals --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"

cinst git --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst gitextensions --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst kdiff3 --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
ConfigureGit

cinst nodejs-lts --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
SetEnvironemntVariable -Name "NODE_PATH" -Value "$env:APPDATA\npm\node_modules" -Scope User
AddPathEntry -PathEntry "$env:APPDATA\npm" -Scope User
if (-not (Get-Command ng -ErrorAction SilentlyContinue)) {
    npm install -g @angular/cli
}
if (-not (Get-Command eslint -ErrorAction SilentlyContinue)) {
    npm install -g eslint
}

cinst powershell-core --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst openjdk --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst webpicmd --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst dotnetcore-sdk --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst TelnetClient -source windowsFeatures --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst nuget.commandline --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
InstallPackageProvider NuGet

cinst azure-cli --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
TrustPSRepository PSGallery
if (-not (IsPSModuleInstalled -ModuleName AzureRM) -and -not (IsPSModuleInstalled -ModuleName Az.Accounts)) {
    InstallPSModule -ModuleName Az -Scope AllUsers
    Enable-AzureRmAlias -Scope CurrentUser
}
InstallServiceBusExplorer

cinst 7zip --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst notepadplusplus --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst googlechrome --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst firefox --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst keepass --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst postman --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst slack --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"

cinst dotnet3.5 --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
cinst netfx-4.7.2-devpack --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"

# Enable Developer Mode
SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value "1" -Type "DWord"

