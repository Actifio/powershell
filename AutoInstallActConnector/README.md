## What does this do?

This powershell script automates the installation of the Actifio VDP connector. It allows you to download the connector and install it or if you have already downloaded it earlier, specify the name of the directory and installer software program name.

## How does this work?

You will need to start a command prompt and run it as administrator. Launch powershell and run the AutoInstallActConnector.ps1 with the appropriate parameters. This way you will not run into access control problem such as below when installing the software.  
  
![image](https://user-images.githubusercontent.com/17056169/79042374-ad8f0480-7c3a-11ea-9532-af37d6fcddc5.png)
  
## Parameters

The following are parameters supported:  
* _-VdpIP_     This wll download the ActPowerCLI-x.y.z.w.zip from the Actifio github repository.    
* _-Download_  This will download the connector software from VdpIP appliance and place it in TmpDir folder.  
* _-Install_   This will install the software on the host.  
* _-TmpDir_    Temporary directory to hold the connector software.  
* _-SwFile_    Name of the installer software.  
* _-Cbt_       To install the connector with the CBT enabled i.e. filter driver.  
  
  
## Sample output:
The following are sample of the different options supported:

### To download from VDP appliance, without installing the software
```
PS C:\users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -Download -TmpDir c:\temp -VdpIP 10.10.10.1
Temporary Directory = c:\temp
I will be downloading Actifio connector version 9.0.
Downloading latest version of Actifio connector from http://10.10.10.1/connector-Win32-latestversion.exe
Actifio connector saved to c:\temp\connector-Win32-latestversion.exe
PS C:\users\johndoe\Desktop>
```
  
### To install the connector software from c:\temp directory with filter driver enabled.  
```
PS C:\users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -Install -Cbt -TmpDir c:\temp -SwFile connector-Win32-latestversion.exe
Temporary Directory = c:\temp
I will be installing Actifio connector version 9.0 .
Beginning installing Actifio connector
PS C:\users\johndoe\Desktop>
```

### To download and install the connector software from VDP appliance with filter driver enabled.  
```
PS C:\users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -Install -Cbt -download -vdpip 10.10.10.1
Temporary Directory =
I will be downloading Actifio connector version 9.0.
Downloading latest version of Actifio connector from http://10.10.10.1/connector-Win32-latestversion.exe
Actifio connector saved to \connector-Win32-latestversion.exe
I will be installing Actifio connector version 9.0 .
Beginning installing Actifio connector
PS C:\users\johndoe\Desktop>
```
