
## Check your versions 
```
$host.version        (need version 3.0 or above)
$PSVersionTable.CLRVersion       (need .NET 4.0 or above)
```
## Check your plugins
```
Get-ChildItem Env:\PSModulePath | format-list
Get-module -listavailable 
Import-module ActPowerCLI
(Get-Module ActPowerCLI).Version    (need 7.0.0.3 or above)
```

## List all commands get help
```
Get-Command -module ActPowerCLI
Get-Help Connect-Act
Get-Help Connect-Act -examples
```

## Store your password (choose just one)
```
(Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\Users\av\Documents\password.key"
"password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\Users\av\Documents\password.key"
Save-ActPassword -filename "C:\Users\av\Documents\password.key"
```

## Login
```
Connect-Act 172.24.1.180 av
Connect-Act 172.24.1.180 -actuser av -passwordfile "C:\Users\av\Documents\password.key"
```

## Example commands
```
udsinfo lscluster
(udsinfo lscluster).operativeip 
udsinfo lsappclass -name SQLServer
udsinfo lsappclass -name SQLServer | out-gridview
udsinfo lsapplication | where-object {$_.appclass -eq "SQLServer"} 
udsinfo lsapplication | where-object {$_.appclass -eq "SQLServer"} | select appname, id, hostid
udsinfo lsbackup -filtervalue "jobclass=snapshot&appid=18405"
udsinfo lsbackup -filtervalue "jobclass=snapshot&appid=18405" | format-table
Get-LastSnap -?
Get-LastSnap -app 18405 -jobclass snapshot
get-sargreport reportlist
reportpools 
get-sargreport reportimages -a 0 | select jobclass, hostname, appname | format-table
reportsnaps | export-csv -path C:\Users\av\Documents\reportsnaps.csv
```
