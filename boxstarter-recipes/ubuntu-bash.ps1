. "$env:USERPROFILE\common.ps1"

cinst Microsoft-Windows-Subsystem-Linux -source windowsFeatures -y --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"

$distroDir = "$env:USERPROFILE\Ubuntu"
if (-not (Test-Path "$distroDir")) {
    SetRegistryValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value "1" -Type "DWord"
    Push-Location
    Set-Location $env:USERPROFILE
    LogInfo "Downloading and extracting Ubuntu.zip"
    (New-Object System.Net.WebClient).DownloadFile("https://aka.ms/wsl-ubuntu-1804", "$PWD\Ubuntu.zip")
    Expand-Archive ".\Ubuntu.zip"
    Remove-Item -Path ".\Ubuntu.zip"
    AddPathEntry -PathEntry "$PWD\Ubuntu" -Scope User
    LogInfo "Installing Ubuntu distro as default for Bash"
    .\Ubuntu\ubuntu1804.exe install --root
    LogInfo "Creating default user"
    $username = ($env:USERNAME).ToLower()
    ubuntu1804.exe -c "adduser --disabled-password --gecos 'Windows User' $username"
    LogInfo "Giving user $username sudo rights"
    ubuntu1804.exe -c "echo '$username ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/$username && chmod 440 /etc/sudoers.d/$username"
    LogInfo "Creating symlink to Windows user home as ~/winhome"
    ubuntu1804.exe config --default-user "$username"
    ubuntu1804.exe -c "ln -s "$PWD" ~/winhome"
    LogInfo "Installing Ubuntu updates"
    ubuntu1804.exe -c "sudo apt-get update"
    ubuntu1804.exe -c "sudo apt-get upgrade -y"
    LogInfo "Bash shell is now ready. If you want to set a user password (may be needed for certain operations) run`nsudo passwd $username"
    Pop-Location
} else {
    LogInfo "Ubuntu is already installed at $distroDir"
}

