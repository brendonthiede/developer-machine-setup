# Developer Machine On-Boarding

## Running BoxStarter Recipes

Open an Administrator PowerShell prompt and navigate to this folder, then run the following:

```powershell
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
./Install-DeveloperPackages.ps1
```

As soon as BoxStarter finishes you should restart before doing anything else. The machine will be in a "Super Admin" mode, where if you install anything yourself at this point you run the risk of it being locked away from your normal user.

## Creating a Development VM (Optional for use in Azure)

You can use the ARM template here to create a VM in Azure:

```powershell
Set-Executionpolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
$windowsAdminCredentials = (Get-Credential -Message "Provide credentials to use for the Windows Admin" -UserName "devmachineadmin")
.\azure-vm-windows10-developer-on-boarding\deploy.ps1 -subscriptionName "Visual Studio Enterprise" -windowsAdminCredentials $windowsAdminCredentials -SkipConfirmation
```

After the VM is created, connect to it as the admin, then create a new user and add them to the `Administrators` group. At this point you can log off as the admin and log back in as the new user and run the BoxStarter recipes as normal.

## BoxStarter Bug

### [Cache location issue](https://github.com/chocolatey/boxstarter/issues/241)

To avoid this issue, you need to append `--cacheLocation "$env:USERPROFILE\AppData\Local\ChocoCache"` (or something like it) to every `cinst` call.

## LocalDB Limitations

LocalDB 14 (SQL Server 2017) has a [bug](https://support.microsoft.com/en-us/help/4096875/fix-access-is-denied-error-when-you-try-to-create-a-database-in-sql-se) where a fresh install (version 14.0.1000.?) will fail to create databases without an explicit path provided due to a missing slash between the user's home directory and the database name (`C:\Users\myusermydatabase.mdf` instead of `C:\Users\myuser\mydatabase.mdf`). This can be fixed by applying [CU13](https://support.microsoft.com/en-us/help/4466404/cumulative-update-13-for-sql-server-2017) for SQL Server 2017, bringing the LocalDB version up to 14.0.3048.4, however there is still another [bug](https://feedback.azure.com/forums/908035-sql-server/suggestions/36481279-sql-server-2017-express-localdb-shared-instance-co) where you cannot connect to a shared instance in LocalDB 14. For this reason, this template sticks to LocalDB 13 (SQL Server 2016), which is installed as part of the "Data" workload for Visual Studio.
