function ResizeConsole {
    Param(
        [Parameter(Mandatory = $True)]
        [int]
        $Width
    )
    $Console = $Host.UI.RawUI
    $Buffer = $Console.BufferSize
    $ConSize = $Console.WindowSize

    # If the Buffer is wider than the new console setting, first reduce the buffer, then do the resize
    If ($Buffer.Width -gt $Width ) {
        $ConSize.Width = $Width
        $Console.WindowSize = $ConSize
    }
    $Buffer.Width = $Width
    $ConSize.Width = $Width
    $Buffer.Height = 3000
    $Console.BufferSize = $Buffer
    $ConSize = $Console.WindowSize
    $ConSize.Width = $Width
    $Console.WindowSize = $ConSize
}

function GetRecipeList {
    $spaceBar = 32
    $upArrow = 38
    $downArrow = 40
  
    $firstPosition = $Host.UI.RawUI.CursorPosition
    $visualstudioIndex = 0
    $databasesIndex = 0
  
    $recipes = @(
        @{"RecipeName" = "devmachine-core"; "Description" = "`tBasic tools like Git, .NET Core, etc."; "Selected" = $true}
        @{"RecipeName" = "vscode"; "Description" = "`t`tVS Code and some useful extensions"; "Selected" = $true}
        @{"RecipeName" = "visualstudio"; "Description" = "`tVisual Studio 2017 with useful workloads"; "Selected" = $true}
        @{"RecipeName" = "databases"; "Description" = "`t`tPowerShell tools for SQL and LocalDB (requires Visual Studio)"; "Selected" = $true}
        @{"RecipeName" = "servicefabric"; "Description" = "`tService Fabric runtime, SDK, and tools"; "Selected" = $false}
        @{"RecipeName" = "docker-hyper-v"; "Description" = "`tDocker running with Hyper-V"; "Selected" = $false}
        @{"RecipeName" = "ubuntu-bash"; "Description" = "`tBash with Ubunutu kernel"; "Selected" = $false}
    )
  
    function MoveCursorUp() {
        if ($Host.UI.RawUI.CursorPosition.Y -gt $firstPosition.Y) {
            $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $Host.UI.RawUI.CursorPosition.Y - 1}
        }
    }
  
    function MoveCursorDown() {
        if ($Host.UI.RawUI.CursorPosition.Y -lt $firstPosition.Y + $recipes.Count - 1) {
            $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $Host.UI.RawUI.CursorPosition.Y + 1}
        }
    }
  
    function ToggleRecipe() {
        $currentRecipe = $recipes[$Host.UI.RawUI.CursorPosition.Y - $firstPosition.Y]
        if ($currentRecipe.Selected) {
            $currentRecipe.Selected = $false
            Write-Host " " -NoNewline
            if ($currentRecipe.RecipeName -eq "visualstudio") {
                $recipes[$databasesIndex].Selected = $false
                $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $firstPosition.Y + $databasesIndex}
                Write-Host " " -NoNewline
                $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $firstPosition.Y + $visualstudioIndex}
            }
        }
        else {
            $currentRecipe.Selected = $true
            Write-Host "X" -NoNewline
            if ($currentRecipe.RecipeName -eq "databases") {
                $recipes[$visualstudioIndex].Selected = $true
                $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $firstPosition.Y + $visualstudioIndex}
                Write-Host "X" -NoNewline
                $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $firstPosition.Y + $databasesIndex}
            }
        }
        $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $Host.UI.RawUI.CursorPosition.Y}
    }

    if ($Host.UI.RawUI.BufferSize.Width -lt 90) {
        ResizeConsole 90
    }
  
    for ($i = 0; $i -lt $recipes.Count; $i++) {
        $recipe = $recipes[$i]
        $selected = " "
        if ($recipe.Selected) {
            $selected = "X"
        }
        Write-Host "[$selected] $($recipe.RecipeName) $($recipe.Description)"
        if ($recipe.RecipeName -eq "visualstudio") {
            $visualstudioIndex = $i
        }
        elseif ($recipe.RecipeName -eq "databases") {
            $databasesIndex = $i
        }
    }
  
    Write-Host "Use cursors and space bar to toggle options, then press Enter to continue, or Q to quit"
  
    $Host.UI.RawUI.CursorPosition = @{ X = 1; Y = $firstPosition.Y }
  
    Do {
        $keyPress = $null
        $keyPress = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        if ($keyPress.VirtualKeyCode -eq $upArrow) {
            MoveCursorUp
        }
        elseif ($keyPress.VirtualKeyCode -eq $downArrow) {
            MoveCursorDown
        }
        elseif ($keyPress.VirtualKeyCode -eq $spaceBar) {
            ToggleRecipe
        }
    } While ($keyPress.Character -notlike "Q" -and $keyPress.VirtualKeyCode -ne 13)
  
    $Host.UI.RawUI.CursorPosition = @{ X = 0; Y = $firstPosition.Y + $recipes.Count + 1 }
  
    if ($keyPress.Character -like "Q") {
        return @()
    }
  
    return $recipes | Where-Object { $_.Selected } | Select-Object -Property @{Name = "RecipeName"; Expression = {"$([string]$_.RecipeName)"}},@{Name = "Path"; Expression = {"$PSScriptRoot\boxstarter-recipes\$($_.RecipeName).ps1"}}
}

function LogInfo {
    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingWriteHost", "")]
    param (
        [string] $Message
    )
    Write-Host -ForegroundColor Green -BackgroundColor DarkMagenta "$Message"
}

function SetTimeZone {
    param (
        [string] $TimeZone
    )

    if ((Get-TimeZone).Id -ne "$TimeZone") {
        LogInfo "Setting time zone to $TimeZone"
        Set-TimeZone -Id "$TimeZone"
    }
    else {
        LogInfo "Time zone was already set to $TimeZone"
    }
}

function SetBoxStarterParams {
    param (
        [string] $GitUserName,
        [string] $GitEmailAddress
    )
    @{GitUserName = $GitUserName; GitEmailAddress = $GitEmailAddress} | ConvertTo-Json | Out-File "$env:USERPROFILE\boxstarterparams.json"
}

function GetBoxStarterParams {
    return (Get-Content "$env:USERPROFILE\boxstarterparams.json" | ConvertFrom-Json)
}

function ConfigureGit {
    if ((Get-Command git -ErrorAction SilentlyContinue)) {
        LogInfo "Reading parameters for Box Starter"
        $params = GetBoxStarterParams

        LogInfo "Current Git configuration:"
        git config --list

        if ($params.GitUserName) {
            LogInfo "Setting Git user.name to $($params.GitUserName)"
            git config --global user.name "$($params.GitUserName)"
        }
        else {
            LogInfo "Leaving Git user.name as is"
        }
        if ($params.GitEmailAddress) {
            LogInfo "Setting Git user.email to $($params.GitEmailAddress)"
            git config --global user.email "$($params.GitEmailAddress)"
        }
        else {
            LogInfo "Leaving Git user.email as is"
        }
        if ((Get-Command kdiff3 -ErrorAction SilentlyContinue)) {
            $kdiffPath = (Get-Command kdiff3).Source -replace '\\', '/'
            LogInfo "Configuring Git to use KDiff3 for merging"
            git config --global merge.tool "kdiff3"
            git config --global mergetool.kdiff3.path "$kdiffPath"
            git config --global mergetool.kdiff3.trustexitcode "false"
            git config --global diff.tool "kdiff3"
            git config --global diff.guitool "kdiff3"
            git config --global difftool.kdiff3.path "$kdiffPath"
            git config --global difftool.kdiff3.trustexitcode "false"
        }
        else {
            LogInfo "KDiff3 could not be found. Leaving Git merge configuration as is"
        }
    }
    else {
        LogInfo "Git does not appear to be installed"
    }
}

function RemoveItemIfExists {
    param (
        [string] $Path
    )
    $Path = [IO.Path]::GetFullPath("$Path")
    if (Test-Path $Path) {
        LogInfo "Removing $Path"
        Remove-Item $Path -Recurse -Force
    }
}

function SetRegistryValue {
    param (
        [string] $Path,
        [string] $Name,
        [string] $Value,
        [string] $Type = "DWord"
    )
    if (Test-Path $Path) {
        $CurrentValue = (Get-ItemProperty -Path "$Path" -Name "$Name" -ErrorAction SilentlyContinue)
        if ($CurrentValue) {
            $CurrentValue = $CurrentValue | Select-Object -ExpandProperty $Name
            LogInfo "Current value of $Path\$Name`: $CurrentValue"
        }
        if ($CurrentValue -and $CurrentValue -eq $Value) {
            LogInfo "Registry entry $Path\$Name was already set to $CurrentValue"
        }
        else {
            LogInfo "Setting $Path\$Name to $Value"
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        }
    }
    else {
        LogInfo "Registry path $Path does not exist. Cannot set $Path\$Name to $Value"
    }
}

function SetSearchDomain {
    param(
        [string] $DomainName
    )
    $existingEntries = ((Get-DnsClientGlobalSetting).SuffixSearchList)
    if (($existingEntries | Where-Object { $_ -eq "$DomainName" }).Length -eq 0) {
        LogInfo "Adding Search Domain for $DomainName"
        Set-DnsClientGlobalSetting -SuffixSearchList ($existingEntries + $DomainName)
    }
    else {
        LogInfo "Search Domain $DomainName already exists"
    }
}

function AddPathEntry {
    param(
        [string] $PathEntry,
        [string][ValidateSet("User", "Machine")] $Scope
    )

    $pathEntries = ([System.Environment]::GetEnvironmentVariable("PATH", "$Scope") -split ";" -ne "")
    if (!($pathEntries -contains "$PathEntry" -or $pathEntries -contains "$PathEntry\")) {
        LogInfo "Adding $PathEntry to the $Scope path"
        $pathEntries += "$PathEntry"
        [System.Environment]::SetEnvironmentVariable("PATH", "$($pathEntries -join ';')", "$Scope")
    }
    else {
        LogInfo "PATH entry $PathEntry was already in the $Scope path"
    }

    $pathEntries = (([System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")) -split ";" -ne "")
    $env:PATH = "$($pathEntries -join ';')"
    LogInfo "Current available PATH: $($env:PATH)"
}

function SetEnvironemntVariable {
    param (
        [string] $Name,
        [string] $Value,
        [string][ValidateSet("User", "Machine")] $Scope
    )
    $currentValue = [System.Environment]::GetEnvironmentVariable("$Name", "$Scope")
    if ($currentValue -ne $Value) {
        LogInfo "Setting environment variable $Name to $Value for $Scope"
        [System.Environment]::SetEnvironmentVariable("$Name", "$Value", "$Scope")
    }
    else {
        LogInfo "Environment variable $Name is already set to $Value for $Scope"
    }
}

function InstallPackageProvider {
    param (
        [string] $Name
    )
    if (Get-PackageProvider -Name $Name -ErrorAction SilentlyContinue) {
        LogInfo "PowerShell package provider $Name is already installed"
    }
    else {
        LogInfo "Installing PowerShell package provider $Name"
        Install-PackageProvider -Name $Name -Force
    }
}

function TrustPSRepository {
    param (
        [string] $Name
    )
    $repo = (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)
    if ($repo) {
        if ($repo.InstallationPolicy -eq "Trusted") {
            LogInfo "PSRepository $Name is already trusted"
        }
        else {
            LogInfo "Adding trust for PSRepository $Name"
            Set-PSRepository -Name $Name -InstallationPolicy Trusted
        }
    }
    else {
        throw "PSRepository $Name is not available"
    }
}

function IsPSModuleInstalled {
    param (
        [string] $ModuleName
    )
    $installed = (Get-Module $ModuleName -ListAvailable -ErrorAction SilentlyContinue)
    return -not (-not $installed)
}

function InstallPSModule {
    param (
        [string] $ModuleName,
        [string][ValidateSet('CurrentUser', 'AllUsers')] $Scope
    )
    if (IsPSModuleInstalled $ModuleName) {
        LogInfo "PowerShell module $ModuleName is already installed"
    }
    else {
        LogInfo "Installing $ModuleName PowerShell module"
        Install-Module -Name $ModuleName -AllowClobber -Scope $Scope -Force
    }
}

function InstallExe {
    param (
        [string] $Uri,
        [string] $ExpectedMd5,
        [string] $InstallerArguments,
        [string] $InstalledCommand,
        [string] $InstalledPath
    )
    if (($InstalledCommand -and (Get-Command $InstalledCommand -ErrorAction SilentlyContinue))) {
        LogInfo "The command $InstalledCommand is already available"
    }
    elseif ($InstalledPath -and (Test-Path $InstalledPath)) {
        LogInfo "The path $InstalledPath already exists"
    }
    else {
        $exe = "$env:TEMP\installer.exe"
        LogInfo "Downloading $Uri as $exe"
        (New-Object System.Net.WebClient).DownloadFile($Uri, $exe)
        $actualMd5 = (Get-FileHash -Path "$exe" -Algorithm MD5).Hash
        if ((-not $ExpectedMd5) -or ($ExpectedMd5 -eq $actualMd5)) {
            LogInfo "Ready to install $exe"
            Start-Process -Wait -FilePath "$env:ComSpec" -ArgumentList "/c start /wait $exe $InstallerArguments"
            LogInfo "Done installing"
            Update-SessionEnvironment
        }
        else {
            throw "MD5 checksum for $exe is not correct"
        }
    }
}

function UpgradePip {
    Update-SessionEnvironment
    if ((Get-Command python -ErrorAction SilentlyContinue)) {
        $installedVersion = ((python -m pip --version 2>$null) -split " ")[1]
        if ($installedVersion) {
            LogInfo "Installed version of pip: $installedVersion"
            $outdatedCheck = (python -m pip list --outdated --format=columns 2>$null | Where-Object { $_ -match "^pip .*" })
            if ($outdatedCheck) {
                LogInfo "Current pip version (Package\Version\Latest\Type): $outdatedCheck"
                LogInfo "Upgrading pip"
                python -m pip install --upgrade pip
            }
            else {
                "pip is already up to date"
            }
        }
        else {
            LogInfo "pip does not seem to be installed"
        }
    }
    else {
        LogInfo "python does not appear to be installed"
    }
}

function InstallPipPackage {
    param (
        [string] $PackageName,
        [string] $RequiredVersion
    )
    if ((Get-Command python -ErrorAction SilentlyContinue)) {
        $installedPackage = (python -m pip show $PackageName 2>$null | Where-Object { $_ -match "^Name: $PackageName$" })
        if ($installedPackage) {
            LogInfo "$PackageName is already installed"
        }
        else {
            LogInfo "Installing $PackageName $RequiredVersion"
            if ($RequiredVersion) {
                $PackageName = "$PackageName==$RequiredVersion"
            }
            python -m pip install -I "$PackageName" 2>$null
        }
    }
    else {
        LogInfo "Python is not installed"
    }
}

function InstallWebPlatformApplication {
    [cmdletbinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]
    param (
        [string] $ProductId
    )
    if (!$Global:WebPIInstalled) {
        $Global:WebPIInstalled = (WebPiCmd-x64.exe /List /ListOption:Installed)
    }
    $installedPackage = ($Global:WebPIInstalled | Where-Object { $_ -match "^$ProductId .*" })
    if (!$installedPackage) {
        LogInfo "Preparing to install $ProductId"
        LogInfo "Checking that $ProductId is available"
        $availablePackage = (WebpiCmd-x64.exe /List /ListOption:Available) -match "^$ProductId .*"
        if (!$availablePackage) {
            throw "$ProductId could is not available to the Web Platform Installer"
        }
        LogInfo "Installing $availablePackage"
        WebPiCmd-x64.exe /install /products:$ProductId /AcceptEula /SuppressReboot
        $Global:WebPIInstalled += "$ProductId "
    }
    else {
        LogInfo "$installedPackage was already installed"
    }
}

function InstallMSI {
    param (
        [string] $Uri,
        [string] $MsiName,
        # The name as shown in Add/Remove Programs. Wild cards are allowed
        [string] $InstalledName
    )
    $installed = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\ | Where-Object { $_.GetValue("DisplayName") -like "$InstalledName*" })
    if (-not $installed) {
        $msi = "$env:TEMP\$MsiName.msi"
        $logs = "$env:TEMP\$MsiName.log"
        LogInfo "Downloading $Uri as $msi"
        (New-Object System.Net.WebClient).DownloadFile($Uri, $msi)
        LogInfo "Installing $msi"
        Start-Process -Wait -FilePath "$env:ComSpec" -ArgumentList "/c start /wait msiexec.exe /i $msi /l*v $logs /qn ALLUSERS=`"1`""
        LogInfo "Installation complete. Logs are at $logs"
    }
    else {
        LogInfo "MSI package '$InstalledName' is already installed"
    }
}

function LocalDbInstanceExists {
    param (
        [string] $InstanceName
    )
    $errors = ((SqlLocalDB info "$InstanceName") | Where-Object { $_.Contains("doesn't exist!") }).length
    return $errors -eq 0
}

function CreateLocalDbInstance {
    param (
        [string] $InstanceName
    )
    if (LocalDbInstanceExists $InstanceName) {
        sqllocaldb start $InstanceName
        LogInfo "LocalDB instance $InstanceName already exists"
    }
    else {
        LogInfo "Creating LocalDB instance $InstanceName"
        sqllocaldb create $InstanceName
        sqllocaldb start $InstanceName
    }
}

function ShareLocalDbInstance {
    param (
        [string] $InstanceName,
        [string] $ShareName
    )
    if (LocalDbInstanceExists ".\$ShareName") {
        LogInfo "LocalDB share $ShareName already exists"
    }
    else {
        LogInfo "Creating LocalDB share of $InstanceName as $ShareName"
        sqllocaldb share $InstanceName $ShareName
        sqllocaldb stop $InstanceName
        sqllocaldb start $InstanceName
    }
}

function GiveSystemUserLocalDbAdmin {
    param(
        [string] $InstanceName,
        [string] $SystemUser
    )
    Push-Location
    if (Get-Command SQLCMD -ErrorAction SilentlyContinue) {
        Set-Location ([System.IO.Path]::GetDirectoryName((Get-Command SQLCMD).Source))
    }
    else {
        if (Test-Path "C:\Program Files\Microsoft SQL Server\110\Tools\Binn") {
            Set-Location "C:\Program Files\Microsoft SQL Server\110\Tools\Binn"
            AddPathEntry -PathEntry "$PWD" -Scope User
        }
        elseif (Test-Path "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn") {
            Set-Location "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn"
            AddPathEntry -PathEntry "$PWD" -Scope User
        }
        else {
            throw "Could not find SQLCMD"
        }
    }
    $result = (.\SQLCMD.EXE -S "(LocalDb)\$InstanceName" -E -d master -Q "SELECT COUNT(sid) FROM syslogins WHERE name = '$SystemUser'")
    $count = [System.Convert]::ToInt16($result[2])
    if ($count -eq 0) {
        LogInfo "Creating login for $SystemUser to LocalDB instance $InstanceName"
        .\SQLCMD.EXE -S "(LocalDb)\$InstanceName" -E -d master -Q "CREATE LOGIN [$SystemUser] FROM WINDOWS"
    }
    else {
        LogInfo "$SystemUser already has a login for LocalDB instance $InstanceName"
    }

    $result = (.\SQLCMD.EXE -S "(LocalDb)\$InstanceName" -E -d master -Q "SELECT count(server_principals.name) FROM sys.server_principals JOIN sys.syslogins ON server_principals.sid = syslogins.sid WHERE server_principals.name = '$SystemUser' AND syslogins.sysadmin = 1")
    $count = [System.Convert]::ToInt16($result[2])
    if ($count -eq 0) {
        LogInfo "Giving user $SystemUser sysadmin access to LocalDB instance $InstanceName"
        .\SQLCMD.EXE -S "(LocalDb)\$InstanceName" -E -d master -Q "EXEC sp_addsrvrolemember N'$SystemUser', sysadmin"
    }
    else {
        LogInfo "$SystemUser already has a sysadmin access for LocalDB instance $InstanceName"
    }
    Pop-Location
}

function DatabaseExists {
    param(
        [string] $DatabaseName,
        [string] $InstanceName = "MSSQLLocalDB"
    )
    Push-Location
    if (Get-Command SQLCMD -ErrorAction SilentlyContinue) {
        Set-Location ([System.IO.Path]::GetDirectoryName((Get-Command SQLCMD).Source))
    }
    else {
        if (Test-Path "C:\Program Files\Microsoft SQL Server\110\Tools\Binn") {
            Set-Location "C:\Program Files\Microsoft SQL Server\110\Tools\Binn"
            AddPathEntry -PathEntry "$PWD" -Scope User
        }
        elseif (Test-Path "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn") {
            Set-Location "C:\Program Files (x86)\Microsoft SQL Server\Client SDK\ODBC\130\Tools\Binn"
            AddPathEntry -PathEntry "$PWD" -Scope User
        }
        else {
            throw "Could not find SQLCMD"
        }
    }
    $result = (.\SQLCMD.EXE -S "(LocalDb)\$InstanceName" -E -d master -Q "SELECT COUNT(1) FROM master.dbo.sysdatabases WHERE name LIKE '$DatabaseName'")
    $count = [System.Convert]::ToInt16($result[2])
    Pop-Location
    return ($count -gt 0)
}

function AddFolder {
    param (
        [string] $Path
    )
    if (Test-Path $Path) {
        LogInfo "Folder $Path already exists"
    }
    else {
        LogInfo "Creating folder $Path"
        New-Item -Path $Path -ItemType Directory -Force
    }
}

function GetGitHubReleaseZip {
    param (
        [string] $UserName,
        [string] $Repo,
        [string] $OutFile
    )
    $ZipUrl = ((Invoke-RestMethod -Uri https://api.github.com/repos/$UserName/$Repo/releases/latest).assets | Where-Object { $_.name -match ".*\.zip$" }).browser_download_url
    Invoke-WebRequest -Uri $ZipUrl -OutFile $OutFile
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip {
    param(
        [string]$ZipFile,
        [string]$OutPath,
        [switch] $RemoveWhenFinished
    )
    LogInfo "Unzipping $ZipFile to $OutPath"
    [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $OutPath)
    if ($RemoveWhenFinished) {
        LogInfo "Deleting $ZipFile"
        Remove-Item $ZipFile -Force
    }
}

function CreateShortcut {
    param (
        [string] $Target,
        [string] $Description,
        [string] $ShortcutFolder
    )
    $shortcutPath = Join-Path "$ShortcutFolder" "$Description.lnk"
    if (Test-Path $shortcutPath) {
        LogInfo "Start Menu item for $Description already exists"
    }
    else {
        if ([System.IO.Path]::IsPathRooted("$Target")) {
            $targetPath = "$Target"
        }
        else {
            $targetPath = [System.IO.Path]::GetFullPath("$Target")
        }
        $targetDirectoryName = [System.IO.Path]::GetDirectoryName("$targetPath")
        $targetFileName = [System.IO.Path]::GetFileName("$targetPath")
        $Shell = New-Object -ComObject ("WScript.Shell")
        $ShortCut = $Shell.CreateShortcut("$shortcutPath")
        $ShortCut.TargetPath = "$targetFileName"
        $ShortCut.WorkingDirectory = "$targetDirectoryName";
        $ShortCut.WindowStyle = 1;
        $ShortCut.IconLocation = "$targetPath, 0";
        $ShortCut.Description = "$Description";
        $ShortCut.Save()
    }
}

function CreateStartMenuShortcut {
    param (
        [string] $Target,
        [string] $Description
    )
    CreateShortcut -Target $Target -Description $Description -ShortcutFolder "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
}

function InstallServiceBusExplorer {
    if (Test-Path "C:\tools\ServiceBusExplorer") {
        LogInfo "Service Bus Explorer is already installed"
    }
    else {
        AddFolder "C:\tools"
        GetGitHubReleaseZip -UserName "paolosalvatori" -Repo "ServiceBusExplorer" -OutFile "C:\tools\ServiceBusExplorer.zip"
        Unzip -ZipFile "C:\tools\ServiceBusExplorer.zip" -OutPath "C:\tools\ServiceBusExplorer" -RemoveWhenFinished
        CreateStartMenuShortcut -Target "C:\tools\ServiceBusExplorer\ServiceBusExplorer.exe" -Description "Service Bus Explorer"
    }
}
