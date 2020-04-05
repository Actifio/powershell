## What does this do?

This powershell script automates the installation of the ActPowerCLI. It allows you to download the ActPowerCLI-x.y.z.w.zip and copies the files into the c:\windows\system32\windowspowershell\v1.0\module directory.

## How does this work?

You will need to start a command prompt and run it as administrator. Launch powershell and run the AutoInstallActCLI.ps1 with the appropriate parameters.

## Parameters

The following are parameters supported:
* _-download_  This wll download the ActPowerCLI-x.y.z.w.zip from the Actifio github repository.  
* _-install_  This will extract the zip files and copy them to c:\windows\system32\windowspowershell\v1.0\module directory.
* _-TmpDir_  Specify the working directory and it be used as the temporary directory that hold the zipped file.


## Sample output:
The following are sample of the different options supported:

### _-download -TmpDir c:\temp_
Download the zipped file to c:\temp directory .
```
PS C:\Users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -download -TmpDir c:\temp
```

### _-install -TmpDir c:\temp_
Install the zipped file from c:\temp directory . The zipped file was downloaded earlier.
```
PS C:\Users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -install -TmpDir c:\temp
```

### _-download -install_
To download and install the latest ActPowerCLI zipped file (ActPowerCLI-x.y.z.w.zip)
```
PS C:\Users\johndoe\Desktop> .\AutoInstallActCLI.ps1 -download -install 
```
