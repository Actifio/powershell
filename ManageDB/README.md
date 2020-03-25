## What does this do?

This is a powershell script that helps you manage the lifecycle of virtual SQL or Oracle database. It allows the user to remove the virtual database, provision a copy the virtual database, and also refresh an existing mount with the latest image stored in VDP.

## How does this work?

It relies on a parameter file for all the virtual database settings and VDP configuration. 

A sample parameter file with an .ps1 extension can be created using this script. You can then customise the parameter file with your database settings.

For security purpose, you can use the script to encrypt the password once and use the encrypted password to login to the VDP appliance.

## Usage

The following are actions supported:
* _genparamfile_  This wll create a sample parameter file supported by this script.  
* _config_  This will create an encrypted passwordfile which can be used later for other operations.
* _cleanup_  This will remove an existing mount from the target environment.
* _provision_  This will provision a new virtual database based on the definition in the parameter file.
* _refresh_  This will first clean up any existing virtual database mount, and provision a new virtual database using the latest VDP backup image.


## Sample output:
The following are sample of the different operations supported:

### _genparamfile_
Create a sample parameter file in .\vdpSampleParam.ps1 file .
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action genparamfile
Generating all the parameters in .\vdpSampleParam.ps1 file
PS C:\Users\johndoe\Desktop>
```

### _config_
Create an encrypted password file in c:\keys\cliuser.key .
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action config -paramfile .\vdpacme.ps1
Enter the full filename (e.g. c:\vdp\password.key): : c:\keys\cliuser.key
PS C:\Users\johndoe\Desktop>
```

### _cleanup_
Clean up an existing mount on the target server.
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action cleanup -paramfile .\actjpmc.ps1

Connected to 172.27.24.96

About to unmount the application if it's mounted.....

Executing: udstask unmountimage -delete -image Image_2530009 | Out-Null
Success!
```

### _provision_
Provision a virtual database using the latest VDP image.
```
```

### _refresh_
Unmount an existing image and provision a virtual database using the latest VDP image.
```
```
