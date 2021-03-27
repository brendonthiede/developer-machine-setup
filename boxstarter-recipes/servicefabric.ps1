. "$env:USERPROFILE\common.ps1"

LogInfo "Installing python from exe"
InstallExe `
  -Uri "https://www.python.org/ftp/python/3.7.2/python-3.7.2-amd64.exe" `
  -ExpectedMd5 "ff258093f0b3953c886192dec9f52763" `
  -InstallerArguments "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0 TargetDir=C:\Python37" `
  -InstalledCommand "python"
UpgradePip
InstallPipPackage -PackageName "sfctl"

InstallWebPlatformApplication -ProductId "WDeploy"
InstallWebPlatformApplication -ProductId "VC12Redist"
InstallWebPlatformApplication -ProductId "MicrosoftAzure-ServiceFabric-CoreSDK"

RemoveItemIfExists "$env:ALLUSERSPROFILE\Microsoft\Windows\Start Menu\Programs\StartUp\Service Fabric Local Cluster Manager.lnk"

