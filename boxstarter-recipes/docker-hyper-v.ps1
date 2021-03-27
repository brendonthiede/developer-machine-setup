. "$env:USERPROFILE\common.ps1"

# In case Docker Toolbox had been previously installed
[Environment]::SetEnvironmentVariable("DOCKER_CERT_PATH", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_HOST", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_MACHINE_NAME", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_TLS_VERIFY", $null, "User")
[Environment]::SetEnvironmentVariable("DOCKER_TOOLBOX_INSTALL_PATH", $null, "User")

cinst Microsoft-Hyper-V-All -source windowsFeatures --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"
try {
    Set-ProcessMitigation -Name C:\Windows\System32\vmcompute.exe -Remove -Disable CFG -ErrorAction SilentlyContinue
}
catch {
}
Set-Service -Name vmms -StartupType Automatic
Start-Service -Name vmms
cinst docker-for-windows --cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"

