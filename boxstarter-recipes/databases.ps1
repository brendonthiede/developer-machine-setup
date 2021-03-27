. "$env:USERPROFILE\common.ps1"

cinst azure-data-studio --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
Update-SessionEnvironment
InstallPSModule SqlServer -Scope AllUsers

LogInfo "Installing Storage Explorer from EXE"
InstallExe `
  -Uri "https://download.microsoft.com/download/A/E/3/AE32C485-B62B-4437-92F7-8B6B2C48CB40/StorageExplorer.exe" `
  -ExpectedMd5 "22BCB4000F0684F34F787FD99DB37659" `
  -InstallerArguments "/VERYSILENT /DIR=`"C:\Program Files (x86)\Microsoft Azure Storage Explorer`"" `
  -InstalledPath "C:\Program Files (x86)\Microsoft Azure Storage Explorer\StorageExplorer.exe"

LogInfo "Installing Azure CosmosDB Emulator from MSI"
InstallMSI -Uri "https://aka.ms/cosmosdb-emulator" -MsiName "cosmosdbsetup" -InstalledName "Azure Cosmos DB Emulator"

# Fix LocalDB bug - https://social.msdn.microsoft.com/Forums/en-US/1257bf26-6ab0-416d-bf26-34f128f42248/sql-2016-sp1-sqllocaldb-versions-errors-with-quotwindows-api-call-quotreggetvaluewquot
$LocalDBVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL13E.LOCALDB\MSSQLServer\CurrentVersion").CurrentVersion
$InstalledLocalDBVersionsPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions"
if ($LocalDBVersion -like "13.1.*" -and -not (Test-Path "$InstalledLocalDBVersionsPath\13.1") -and (Test-Path "$InstalledLocalDBVersionsPath\13.0")) {
  Move-Item "$InstalledLocalDBVersionsPath\13.0" "$InstalledLocalDBVersionsPath\13.1"
}

# Iniitialize storage emulator
if (-not (DatabaseExists -DatabaseName "AzureStorageEmulatorDb%")) {
  LogInfo "Initializing Storage Emulator"
  $StorageEmulatorHome = "C:\Program Files (x86)\Microsoft SDKs\Azure\Storage Emulator\"
  Push-Location
  Set-Location $StorageEmulatorHome
  .\AzureStorageEmulator.exe init
  Pop-Location
} else {
  LogInfo "Storage Emulator is already initialized"
}

# Prepare shared localDB instance
CreateLocalDbInstance -InstanceName "MSSQLLocalDB"
ShareLocalDbInstance -InstanceName "MSSQLLocalDB" -ShareName "sharedlocal"
GiveSystemUserLocalDbAdmin -InstanceName "MSSQLLocalDB" -SystemUser "NT AUTHORITY\NETWORK SERVICE"

