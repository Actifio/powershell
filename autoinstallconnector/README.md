## Overview

This PowerShell script automates the installation of the Actifio connector on a Windows host. It allows the user to deploy with the Filter Driver enabled or disabled. And, this can be run from the command line or pushed out from a third-party application deployment software or Microsoft Active Directory.

## Usage

You can enter the Actifio IP address as an option in the command line by specifying the -ActifioIP:
```
powershell -noprofile -executionpolicy bypass -file autoinstallconnector.ps1 -ActifioIP 10.65.5.192
```

Or, if you prefer to run it interactively from the command line:
```
powershell -noprofile -executionpolicy bypass -file autoinstallconnector.ps1 
Please enter the Actifio IP address : **10.65.5.192**
```
