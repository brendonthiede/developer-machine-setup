$Boxstarter.RebootOk=$true # Allow reboots
$Boxstarter.NoPassword=$false # This machine doesn't have a passwordless login
$Boxstarter.AutoLogin=$true # Save password securely and auto-login after a reboot
Disable-UAC
Disable-MicrosoftUpdate
Update-ExecutionPolicy Unrestricted

