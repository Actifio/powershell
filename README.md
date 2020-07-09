# Actifio Windows PowerShell integration

These instructions are for a Windows PowerShell Module that is used to manage Actifio Appliances.
For a fully PowerShell 7 compatible module, please look here:  https://github.com/Actifio/ActPowerCLI-PS7

### 1)   Ensure PowerShell 3.0 and .NET 4.5 are installed.

Ensure that Windows PowerShell 3.0 to 5.1 or above is installed on the target workstation.
For Windows 7 SP1 and Windows 2008 R2, PowerShell 3.0 should already be installed. 
We also need .NET 4.5 installed on the OS. To find out the PowerShell version, start PowerShell and then enter the version command as shown:  
```
powershell
$host.version 
 ```
If you are downlevel, installing the Windows Management Framework 3.0 (https://www.microsoft.com/en-us/download/details.aspx?id=34595) will upgrade your PowerShell software to version 3.0.    You should consider upgrading to 5.1 (https://www.microsoft.com/en-us/download/details.aspx?id=54616)

To find out the current version of .NET Framework, enter the following in PowerShell:
```
$PSVersionTable.CLRVersion 
```

Note that the second digit can be misleading.  For instance 4.0.30319.42000 is actually .NET 4.6

#### PowerShell 7  (once known as Core)

PowerShell 6+ (as opposed to Windows PowerShell) has been tested on Windows.   At this time the only known issue is that SSL Certificates need to be manually imported before using PowerShell Core.

For a fully PowerShell 7 compatible module, please look here:  https://github.com/Actifio/ActPowerCLI-PS7

### 2)   Confirm if the actpowercli module is already installed

To get a list of available modules to the current PowerShell:
```
Get-module -listavailable 
```

### 3)    Determine where to place actpowercli if needed

Find out where we should place the Windows ActPowerCLI PowerShell modules in the environment by querying the PSModulePath environment variable:
```
Get-ChildItem Env:\PSModulePath | format-list
```

### 4)  Use the installer

1.  From GitHub, use the download button to download the ActPowerCLI-10.0.0.709.zip file
1.  Copy the Zip file to the server where you want to install it
1.  Right select on the zip file, choose  Properties and then use the Unblock button next to the message:  "This file came from another computer and might be blocked to help protect  your computer."
1.  Now right select and use Extract All to extract the contents of the zip file to a folder.  It doesn't matter where you put the folder but you will need to know where it is!  
1.  Now start Windows PowerShell and change directory to the directory that should contain our module files.   
1.  There is an installer, Install-ActPowerCLI.ps1   So we need tp run that with ./Install-ActPowerCLI.ps1
If you find multiple installs, we strongly recommend you delete them all and run the installer again to have just one install.


If the install fails with something like this:
```
PS C:\Users\av\Downloads\ActPowerCLI-10.0.0.709\ActPowerCLI> .\Install-ActPowerCLI.ps1
.\Install-ActPowerCLI.ps1 : File C:\Users\av\Downloads\ActPowerCLI-10.0.0.709\ActPowerCLI\Install-ActPowerCLI.ps1
cannot be loaded. The file C:\Users\av\Downloads\ActPowerCLI-10.0.0.709\ActPowerCLI\Install-ActPowerCLI.ps1 is not
digitally signed. You cannot run this script on the current system. For more information about running scripts and
setting execution policy, see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ .\Install-ActPowerCLI.ps1
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```
Then use this command to allow Windows PowerShell to run the script:
```
powershell -executionpolicy unrestricted
```
Then re-run the installer.  The installer will unblock all the files.



### 5)  Import actpowercli

Import the module into the PowerShell session by running:
```
Import-module ActPowerCLI
```
If you get any errors at this point, please review this FAQ document for possible solutions:
https://github.com/Actifio/powershell/blob/master/FAQ.md

### 6)  Find out the current version of ActPowerCLI:
```
(Get-Module ActPowerCLI).Version
```

### 3) - 6) Automating the installation process

To automate steps 3-6 listed above, please refer to https://github.com/Actifio/powershell/tree/master/setup-actpowercli

### 7)  Get some help
List the available commands in the ActPowerCLI module:
```
Get-Command -module ActPowerCLI
```
Find out the syntax and how you can use a specific command. For instance:
```
Get-Help Connect-Act
```
If you need some examples on the command:
```
Get-Help Connect-Act -examples
```

### 8)  Save your password
Following are three different methods of storing a credential in a file:

a)  Create an encrypted password file using the PowerShell Get-Credential cmdlet:
```
(Get-Credential).Password | ConvertFrom-SecureString | Out-File "C:\temp\password.key"
```
b)	Create an encrypted password file using clear text:
```
"password" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\temp\password.key"
```
c)	Create an encrypted password file using the ActPowerCLI Save-ActPassword cmdlet:
```
Save-ActPassword -filename "C:\temp\password.key"
```
##### Sharing key files

Currently if a key file is created by a specific user, it cannot be used by a different user.    You will see an error like this:
```
Key not valid for use in specified state.
```
This will cause issues when running saved scripts when two differerent users want to run the same script with the same keyfile.    To work around this issue, please have each user create a keyfile for their own use.   Then when running a shared script, each user should execute the script specifying their own keyfile.  This can be done by using a parameter file for each script.

### 9)  Login to your appliance

To login to an Actifio appliance (10.61.5.114) as admin and enter password interactvely:
```
Connect-Act 10.61.5.114 admin -ignorecerts
```
Or login to the Actifio cluster using the password file created in the previous step:
```
Connect-Act 10.61.5.114 -actuser admin -passwordfile "c:\temp\password.key" -ignorecerts
```
You will need to store the certificate during first login if you don't use **-ignorecerts**

Note you can use **-quiet** to supress messages.   This is handy when scripting.

### 10) Example commands

To list all the Actifio clusters using the udsinfo command:
```
udsinfo lscluster
```
To list only the operative IP address:
```
(udsinfo lscluster).operativeip 
```
To grab the operative IP address for a specific Appliance (called *appliance1* in this example):
```
(udsinfo lscluster -filtervalue name=appliance1).operativeip
```
To list all the advanced options related to SQL server:
```
udsinfo lsappclass -name SQLServer
```
To list all the advanced options related to SQL server and display the results in a graphical popup window:
```
udsinfo lsappclass -name SQLServer | out-gridview
```
To list all the fields for all the SQL server databases:
```
udsinfo lsapplication | where-object {$_.appclass -eq "SQLServer"} 
```
To list selected fields for all the SQL server databases:
```
udsinfo lsapplication | where-object {$_.appclass -eq "SQLServer"} | select appname, id, hostid
```
To list all the snapshot jobs for appid 18405:
```
udsinfo lsbackup -filtervalue "jobclass=snapshot&appid=18405"
```
To list the above in a table format
```
udsinfo lsbackup -filtervalue "jobclass=snapshot&appid=18405" | format-table
```
If you need help with a command, use the -? option:
```
Get-LastSnap -?
```
To find out the latest snapshot image for appid 18405:
```
Get-LastSnap -app 18405 -jobclass snapshot
```
To get a list of available SARG reports, run either:
```
reportlist 
get-sargreport reportlist
```
To list all available storage pools on the Actifio appliance, run the reportpools command:
```
reportpools 
```
Run the SARG reportimages command:
```
get-sargreport reportimages -a 0 | select jobclass, hostname, appname | format-table
```
To export to CSV we use the PowerShell export-csv option and then specify the path.   In this example you can see the path and filename that was used.
```
reportsnaps | export-csv -path c:\Users\av\Documents\reportsnaps.csv
```
To learn the latest snapshot date for each application we could do this:
```
reportrpo | select apptype, hostname, appname, snapshotdate
```
To learn the latest snapshot date for each VM we could do this:
```
reportrpo | where {$_.Apptype -eq "VMBackup"} | select appname, snapshotdate
```
udsinfo lshost provides us with high level information on a host. To find out the detail information on each host:
```
udsinfo lshost | select id | foreach-object { udsinfo lshost $_.id } | select svcname, hostname, id, iscsi_name, ipaddress
```
To list out all the workflow configurations on an appliance, use a combination of reportworkflows and udsinfo lsworkflow:
```
reportworkflows | select id | foreach-object {udsinfo lsworkflow $_.id}
```
#### Avoiding white space and multiple lines in array output
A common requirement is that you may want to get the latest image name for an application, but the command returns white space and/or multiple lines.   In this example the output not only has multiple image names, but white space.  This could result in errors when trying to use this image name in other commands like udstask mountimage
```
PS C:\Users\av> $imagename = udsinfo lsbackup -filtervalue "backupdate since 124 hours&appname=SQL-Masking-Prod&jobclass=snapshot" | where {$_.componenttype -eq "0"} | select backupname | ft -HideTableHeaders
PS C:\Users\av> $imagename

Image_4393067
Image_4410647
Image_4426735


PS C:\Users\av>
```
If we use a slightly different syntax, we can guarantee both no white space and only one image name:
```
PS C:\Users\av> $imagename =  $(udsinfo lsbackup -filtervalue "backupdate since 124 hours&appname=SQL-Masking-Prod&jobclass=snapshot" | where {$_.componenttype -eq "0"} | select -last 1 ).backupname
PS C:\Users\av> $imagename
Image_4426735
PS C:\Users\av>
```

### 11)  Disconnect from your appliance
Once you are finished, make sure to disconnect (logout).   If you are running many scripts in quick succession, each script should connect and then disconnect, otherwise each session will be left open to time-out on its own.
```
Disconnect-Act
```



# I have more questions!

Have you looked here?

https://github.com/Actifio/powershell/blob/master/FAQ.md
