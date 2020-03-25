## What does this do?

This is a powershell script that helps you manage the lifecycle of virtual SQL or Oracle database. It allows the user to remove the virtual database, provision a copy the virtual database, and also refresh an existing mount with the latest image stored in VDP. This script can be used if user is not interested in using the VDP workflow feature.

## How does this work?

It relies on a parameter file for all the virtual database settings and VDP configuration. For Oracle database, user will be able to specify startup initialisation parameters such as as SGA size, location of the Oracle Home directory, and etc.

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
Create an encrypted password file in c:\keys\cliuser.key . There are two ways to specify the password: 1) place it in the parameter file by specifying in the `$vdppassword` parameter. 2) If `$vdppassword` is missing, the script will prompt you for the password.
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action config -paramfile .\vdpacme.ps1
Enter the full filename (e.g. c:\vdp\password.key): : c:\keys\cliuser.key
PS C:\Users\johndoe\Desktop> dir c:\keys\cliuser.key
    Directory: C:\keys
Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----        3/25/2020   5:21 AM            654 cliuser.key

PS C:\Users\johndoe\Desktop>
```

### _cleanup_
Clean up an existing mount on the target server.
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action cleanup -paramfile .\vdpacme.ps1

Connected to 10.10.10.1

About to unmount the application if it's mounted.....

Executing: udstask unmountimage -delete -image Image_2530009 | Out-Null
Success!
```

### _provision_
Provision a virtual database using the latest VDP image.
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action provision -paramfile .\vdpacme.ps1

Connected to 10.10.10.1

Mounting ACMESA to acme-ora01 as demodb...

Executing: udstask mountimage -appid 11343 -host 11107 -appaware -restoreoption "provisioningoptions=<provisioningoptions><databasesid>demodb</databasesid><username>oracle</username><orahome>/u01/app/oracle</orahome><totalmemory>1536</totalmemory><sgapct>80</sgapct><nonid>false</nonid><noarchivemode>false</noarchivemode><notnsupdate>false</notnsupdate><rrecovery>true</rrecovery><standalone>true</standalone></provisioningoptions>,reprotect=false" -nowait | Out-Null

Job is now running....
- Progress% : 51 ...
- Progress% : 57 ...
- Progress% : 58 ...
- Progress% : 59 ...
- Progress% : 60 ...
- Progress% : 96 ...
- Progress% : 99 ...

Displaying the statistics for Job_2533877

Kicking off an on-demand provision of virtual database demodb on acme-ora01 using images from ACMESA database

demodb database is successfully provisioned on acme-ora01 !!
Job started at 2020-03-25 21:48:15.427 , and took 00:13:00 to complete.
The size of demodb on acme-ora01 is 1978.177 GB, and actual storage consumed is 0.249 GB
Success!
```

### _refresh_
Unmount an existing image and provision a virtual database using the latest VDP image.
```
PS C:\Users\johndoe\Desktop> .\ManageDB.ps1 -action refresh -paramfile .\vdpacme.ps1

Connected to 10.10.10.1

About to unmount the application if it's mounted.....

Executing: udstask unmountimage -delete -image Image_2533877 | Out-Null

Mounting ACMESA to acme-ora01 as demodb...

Executing: udstask mountimage -appid 11343 -host 11107 -appaware -restoreoption "provisioningoptions=<provisioningoptions><databasesid>demodb</databasesid><username>oracle</username><orahome>/u01/app/oracle</orahome><totalmemory>1536</totalmemory><sgapct>80</sgapct><nonid>false</nonid><noarchivemode>false</noarchivemode><notnsupdate>false</notnsupdate><rrecovery>true</rrecovery><standalone>true</standalone></provisioningoptions>,reprotect=false" -nowait | Out-Null

Job is now running....
- Progress% : 18 ...
- Progress% : 51 ...
- Progress% : 53 ...
- Progress% : 58 ...
- Progress% : 59 ...
- Progress% : 61 ...
- Progress% : 96 ...
- Progress% : 99 ...

Displaying the statistics for Job_2537228

Kicking off an on-demand provision of virtual database demodb on acme-ora01 using images from ACMESA database

demodb database is successfully provisioned on acme-ora01 !!
Job started at 2020-03-25 22:11:19.015 , and took 00:13:30 to complete.
The size of demodb on acme-ora01 is 1978.177 GB, and actual storage consumed is 0.248 GB
Success!
```
---

## FAQ
Q: Is there a way where I can find out the CLI commands without executing them?  
A: Yes, set `$debug = $True` in the parameter file. 
  
Q: How do I specify the ORACLE_SID when provisioning or refreshing an Oracle database?  
A: The `$tgt_appname` in the parameter file is synonymous with the Oracle SID.  
  
Q: How do I secure the password of the VDP CLI user?  
A: Use the `config` option to store the password in an encrypted file. Modify the parameter file to use the encrypted file using the `$vdppasswordfile` in the parameter file.  
  
Q: Can I include pre and post scripts as part of the provisioning / refresh process?  
A: Yes, set the name of the scripts in `$pre_scriptfile` and `$post_scriptfile` parameters. You can also set the timeouts for the pre & post scripts in `$pre_timeout` and `$post_timeout`. For Linux, use the `.sh` extension, and `.bat` for Windows.  
  
