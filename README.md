# actpowercli


### 1)   Ensure PowerShell 3.0 and .NET are installed.

Ensure that PowerShell 3.0 is installed on the target workstation.
For Windows 7 SP1 and Windows 2008 R2, Powershell 3.0 should already be installed. 
We also need .NET 4.0 installed on the OS. To find out the Powershell version, start Powershell and then enter the version command as shown:  
```
powershell
$host.version 
 ```
If you are downlevel, installing the Windows Management Framework 3.0 (https://www.microsoft.com/en-us/download/details.aspx?id=34595) will upgrade your PowerShell software to version 3.0.

To find out the current version of .NET Framework, enter the following in PowerShell:
```
$PSVersionTable.CLRVersion 
```

### 2)   Confirm if actpowercli is already installed

To get a list of available modules to the current PowerShell:
```
Get-module -listavailable 
```

### 3)    Determine where to place actpowercli if needed

Find out where we should place the Windows ActPowerCLI PowerShell modules in the environment by querying the PSModulePath environment variable:
```
Get-ChildItem Env:\PSModulePath | format-list
```

### 4)  Copy actpowercli into place

Unzip the ActPOWERCLI-7.0.0.6.zip software and copy the ActPowerCLI to a relevant directory.  For example:
```
c:\windows\system32\windowspowershell\v1.0\modules 
```

### 5)  Import actpowercli

Import the module into the Powershell session by running:
```
Import-module ActPowerCLI
```
If you are running Powershell version 5 then extra steps to enable script command execution will be needed if you get an error like this:
```
PS C:\Users\av> connect-act
connect-act : The 'connect-act' command was found in the module 'ActPowerCLI', but the module could not be loaded. For
more information, run 'Import-Module ActPowerCLI'.
At line:1 char:1
+ connect-act
+ ~~~~~~~~~~~
    + CategoryInfo          : ObjectNotFound: (connect-act:String) [], CommandNotFoundException
    + FullyQualifiedErrorId : CouldNotAutoloadMatchingModule

```
If you get this error we will need to modify the downloaded zip file and copy the folder again.
1. Delete the actpowercli folder in c:\windows\system32\windowspowershell\v1.0\modules  or where ever you placed it
1. Right select the downloaded zip file and choose properties
1. At the bottom of the properties window select the Unblock button next to the message: *This file came from another computer and might be blocked to help protect this computer*
1. Unzip and again copy the foler into c:\windows\system32\windowspowershell\v1.0\modules or which ever path you are using


### 6)  Find out the current version of ActPowerCLI:
```
(Get-Module ActPowerCLI).Version
```

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

a)  Create an encrypted password file using the Powershell Get-Credential cmdlet:
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
### 9)  Login to your appliance

To login to an Actifio appliance (10.61.5.114) as admin and enter password interactvely:
```
Connect-Act 10.61.5.114 admin
```
Or login to the Actifio cluster using the password file created in the previous step:
```
Connect-Act 10.61.5.114 -actuser admin -passwordfile "c:\temp\password.key"
```
You will need to store the certificate during first login.

