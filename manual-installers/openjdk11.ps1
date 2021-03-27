#Requires -RunAsAdministrator

## This is a completely stand alone installer for setting up Open JDK 11
[CmdletBinding()]
param (
    $InstallDir = "C:\tools"
)

$ErrorActionPreference = "Stop"

if ((Get-Command java -ErrorAction SilentlyContinue)) {
    throw "Java is already installed"
}

$javaVersion = "jdk-11.0.2"
New-Item -Path $InstallDir -ItemType Directory -ErrorAction SilentlyContinue
Set-Location $InstallDir
(New-Object System.Net.WebClient).DownloadFile("https://download.java.net/java/GA/jdk11/9/GPL/open$($javaVersion)_windows-x64_bin.zip", "$PWD\openjdk11.zip")
$actualHash = (Get-FileHash -Path .\openjdk11.zip -Algorithm SHA256).Hash
$expectedHash = "cf39490fe042dba1b61d6e9a395095279a69e70086c8c8d5466d9926d80976d8"

if ($actualHash -ne $expectedHash) {
    throw "SHA 256 hash for downloaded zip is not correct"
}

Expand-Archive ".\openjdk11.zip" -DestinationPath .\

[System.Environment]::SetEnvironmentVariable('JAVA_HOME', "$PWD\$javaVersion\", 'Machine')
$env:JAVA_HOME = "$PWD\$javaVersion\"

$pathEntry = "%JAVA_HOME%\bin\"
$pathEntries = ([System.Environment]::GetEnvironmentVariable("PATH", "Machine") -split ";" -ne "")
if (!($pathEntries -contains "$pathEntry")) {
    $pathEntries += "$pathEntry"
    [System.Environment]::SetEnvironmentVariable("PATH", "$($pathEntries -join ';')", "Machine")
}

$pathEntries = (([System.Environment]::GetEnvironmentVariable("PATH", "User") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "Machine")) -split ";" -ne "")
$env:PATH = "$($pathEntries -join ';')"

if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "Java command is not available after install process. You may need to restart."
}