### I install the Certificate when prompted but the next time I connect it prompts me again

When you install the Certificate it is issued to a specific hostname.   In the example below it is *sa-sky*.  This means when you login you need to use that name.   If you instead specify the IP address, even if it resolves to that name, it will not match the name on the certificate.
```
Certificate details
Issuer:  CN=sa-sky, OU=Demo, O=Actifio, L=Waltham, S=Mass, C=US
Subject:  CN=sa-sky, OU=Demo, O=Actifio, L=Waltham, S=Mass, C=US
```

### Can I specify a PowerShell (PS1) script in an Actifio Workflow?

Actifio workflows allow you to specify a pre and post script.   For Windows these scripts need to be in either .CMD or .BAT format and have relevant extension.   In other words, these have to be files that can be executed by a Windows Command Prompt.   

However these scripts can call PS1 scripts.  So if the postscript field specifies a bat file called postmount.bat which is located in  **C:\Program Files\Actifio\scripts**, it could could contain a script like this:
```
cd /d "C:\Program Files\Actifio\scripts"

start /wait powershell -ExecutionPolicy Bypass "& .\postmountactions.ps1"
```
You can find a working example here:   https://github.com/Actifio/powershell/tree/master/workflow_email_notifications


### I am getting this error message: "the module could not be loaded" 

If you are running PowerShell version 5 then extra steps will be needed if you get an error like this:
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
1. Unzip and again copy the folder into c:\windows\system32\windowspowershell\v1.0\modules or which ever path you are using

### I am getting this error message:  "Could not load file or assembly"


If you are running 64-bit Windows 7, Professional Edition you may get an error like this:
```
Import-Module : Could not load file or assembly
'file:///C:\Windows\system32\WindowsPowerShell\v1.0\Modules\ActPowerCLI\ActPowerCLI.dll' or one of its dependencies.
Operation is not supported. (Exception from HRESULT: 0x80131515)
At line:1 char:1
+ Import-Module ActPowerCLI
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (:) [Import-Module], FileLoadException
    + FullyQualifiedErrorId : FormatXmlUpdateException,Microsoft.PowerShell.Commands.ImportModuleCommand
```
If you get this error we will need to modify the downloaded zip file and copy the folder again.
1. Delete the actpowercli folder in c:\windows\system32\windowspowershell\v1.0\modules  or where ever you placed it
1. Right select the downloaded zip file and choose properties
1. At the bottom of the properties window select the Unblock button next to the message: *This file came from another computer and might be blocked to help protect this computer*
1. Unzip and again copy the folder into c:\windows\system32\windowspowershell\v1.0\modules or which ever path you are using



### I am getting this error message:  "running scripts is disabled on this system"
```
Import-module : File C:\Users\avandewerdt\Documents\WindowsPowerShell\Modules\ActPowerCLI\ActPowerCLI.psm1 cannot be loaded because running scripts is disabled on this system. For more information,
see about_Execution_Policies at http://go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:1
+ Import-module ActPowerCLI
+ ~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [Import-Module], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess,Microsoft.PowerShell.Commands.ImportModuleCommand
```
If you get this there are several possible solutions, here are two:
*  When starting powershell, use this command:
```
powershell -executionpolicy unrestricted
```
*  Change Group Policy setting.  To do this:
```
Open Run Command/Console (Win + R)
Type: gpedit.msc (Group Policy Editor)
Browse to Local Computer Policy -> Computer Configuration -> Administrative Templates -> Windows Components -> Windows Powershell.
Enable "Turn on Script Execution"
Set the policy to "Allow all scripts".
```
### PowerShell 6 never prompts me about Certificates

Please see the section below.

### I am getting this error message with PowerShell 6:  *An error occurred while sending the request*

PowerShell from version 6 changed from *Windows PowerShell* to just *PowerShell* to reflect that it can now run on Linux and Mac OS.   The commands used for SSL have changed which will require some changes to the Actifio PowerShell Module.   You may see this error:  

```
Connect-ActAppliance : One or more errors occurred. (An error occurred while sending the request.)
At C:\program files\powershell\6-preview\Modules\ActPowerCLI\ActPowerCLI.psm1:192 char:3
+         Connect-ActAppliance -cdshost $acthost -cdsuser $actuser -Pas ...
+         ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+ CategoryInfo          : NotSpecified: (:) [Connect-ActAppliance], AggregateException
+ FullyQualifiedErrorId : System.AggregateException,ActPowerCLI.ConnectActAppliance
```
Firstly if you have Windows PowerShell 3.0 to 5.1, use that to install the Actifio Appliance Certificate as a Trusted Root Certificate as per the example shown.  Note the Subject name, in this example *sa-sky*
```
PS C:\Users\avandewerdt> connect-act 172.24.1.180
The SSL certificate from https://172.24.1.180 is not trusted. Please choose one of the following options
(I)gnore & continue
(A)ccept & install certificate
(C)ancel
Please select an option: a
Certificate details
Issuer:  CN=sa-sky, OU=Demo, O=Actifio, L=Waltham, S=Mass, C=US
Subject:  CN=sa-sky, OU=Demo, O=Actifio, L=Waltham, S=Mass, C=US
Effective:  12/13/2017 2:25:49 PM
Expiration:  12/11/2027 2:25:49 PM
This certificate will be installed into the Trusted Root Certication Authorities store
Please choose the location where the certificate should be installed
[M] LocalMachine
[U] CurrentUser
Choose location: u
Certificate added successfully and will be used in the next session.
Actifio user: av
Password: **********
Login Successful!
PS C:\Users\avandewerdt>
```
Once the certificate is installed using Windows PowerShell, you can now use PowerShell 6, but always use the correct Subject name.  In the example above it was *sa-sky* so logging in as *172.24.1.180* will not work.
```
PS C:\Program Files\PowerShell\6-preview> connect-act sa-sky
Actifio user: av
Password: **********
Login Successful!
PS C:\Program Files\PowerShell\6-preview> connect-act 172.24.1.180
Actifio user: av
Password: **********
Connect-ActAppliance : One or more errors occurred. (An error occurred while sending the request.)
At C:\program files\powershell\6-preview\Modules\ActPowerCLI\ActPowerCLI.psm1:192 char:3
```

#### Using the Actifio Desktop to import the Certificate

If you don't have access to PowerShell 3 to 5, then we could import the Certificate using the Actifio Desktop if it is installed.   Open the Actifio Desktop and logon to the Appliance, you should get a Security Alert.   Choose the option to *View Certificate*.   Note if you don't get this prompt, your certificate is already trusted.

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-03-23.jpg)

Carefully note the _Issued to:_  section.   This contains the name or IP you need to connect to.   Select *Install Certficate*

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-03-44.jpg)

Choose *Local Machine* and select Next.  You will get a security popup.

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-05-05.jpg)

Browse and select *Trusted Root Certification Authorities*.   Select Next and follow the prompts.

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-05-34.jpg)

Now next time you login with the Actifio Desktop provided you point at the name or IP that the certificate was issued to, you can login.  In my example it was *172.24.2.180*

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-20-18.jpg)

#### Importing or viewing the certificates on your Windows host:

1. Open a Command Prompt window.
1. Type mmc and press the ENTER key. Note that to view certificates in the local machine store, you must be in the Administrator role.
1. On the File menu, click Add/Remove Snap In.
1. Click Add.
1. In the Add Standalone Snap-in dialog box, select Certificates.
1. Click Add.
1. In the Certificates snap-in dialog box, select Computer account and click Next. Optionally, you can select My User account or Service account. If you are not an administrator of the computer, you can manage certificates only for your user account.
1. In the Select Computer dialog box, click Finish.
1. In the Add Standalone Snap-in dialog box, click Close.
1. On the Add/Remove Snap-in dialog box, click OK.
1. In the Console Root window, click Certificates (Local Computer) to view the certificate stores for the computer.

In this example you can the trusted certificate that was added:

![alt text](https://github.com/Actifio/powershell/blob/master/images/2018-06-20_15-23-38.jpg)

If we export the certificate using a webbrowser, we could import using the Certificates snapin.

### I am trying to use PWSH on Linux or Mac OS

We currently don't support these OSs.   While the module will load ok, you cannot connect with SSL.  It may be possible we will support this in a future version of our module.  

### I am getting a 7.0.0 version error 

After upgrading your appliance to 10.0.0.x or higher you will get this error:

```Error: The current platform version: (10.0) 10.0.0.xxx does not support SARG reports via ActPowerCLI. The minimum version for SARG reports via ActPowerCLI is with Actifio CDS/Sky 7.0.0 and higher```

To resolve this you need to upgrade to version 10.0.0.227 of ActPowerCLI or higher.

### I am getting file not found errors

After installing a newer version of the module, you may start getting errors like these:

```
The term 'C:\Program Files (x86)\WindowsPowerShell\Modules\ActPowerCLI C:\Windows\system32\WindowsPowerShell\v1.0\Modules\ActPowerCLI\ActPowerCLI.ArgumentCompleters.ps1' is not recognized 
as the name of a cmdlet, function, script file, or operable program. Check the spelling of the name, or if a path was included, verify that the path is correct and try again.
At C:\Program Files (x86)\WindowsPowerShell\Modules\ActPowerCLI\ActPowerCLI.psm1:239 char:6
```

This happens if you have installed two different versions of ActPowerCLI in two different locations.  For instance you have modules in more than one of the following and some of them are different versions:

```
C:\Program Files (x86)\WindowsPowerShell\Modules
C:\Program Files\WindowsPowerShell\Modules
C:\Windows\System32\WindowsPowerShell\v1.0\Modules
C:\Windows\SysWOW64\WindowsPowerShell\v1.0\Modules
```

Ideally delete all copies and install just the latest to a single location.
