### 
## This script 
###

## Overview

This PowerShell script automates the installation the ActPowerCLI module.

## Usage

There are two ways you can run the script:

Method 1:
```
First, download the PowerShell script (https://raw.githubusercontent.com/Actifio/powershell/master/setup-actpowercli/instactpowercli.ps1) to your current directory.


Then, launch the powershell command with the PS file as a parameter:

C:\Users\Administrator\Desktop>powershell -file .\instactpowercli.ps1
Downloading latest version of ActPowerCLI from https://github.com/Actifio/powers
hell/raw/master/ActPowerCLI-7.0.0.6.zip
File saved to C:\Users\ADMINI~1\AppData\Local\Temp\2\ActPowerCLI-7.0.0.6.zip
Uncompressing the Zip file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules

Renaming folder
Module has been installed

CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        Connect-Act                                        ActPowerCLI
Function        Disconnect-Act                                     ActPowerCLI
Function        get-sargreport                                     ActPowerCLI
Function        Save-ActPassword                                   ActPowerCLI
Function        udsinfo                                            ActPowerCLI
Function        udstask                                            ActPowerCLI
Function        usvcinfo                                           ActPowerCLI
Function        usvctask                                           ActPowerCLI
Cmdlet          Get-ActAppID                                       ActPowerCLI
Cmdlet          Get-LastSnap                                       ActPowerCLI
Cmdlet          Get-Privileges                                     ActPowerCLI

Major         : 7
Minor         : 0
Build         : 0
Revision      : 6
MajorRevision : 0
MinorRevision : 6

```

Method 2:
```
First, launch a PowerShell session

Then, download the bootstrap script and it will automatically install it for you:

C:\>powershell
Windows PowerShell
Copyright (C) 2012 Microsoft Corporation. All rights reserved.

PS C:\> iex (New-Object Net.WebClient).DownloadString("https://raw.githubusercon
tent.com/Actifio/powershell/master/setup-actpowercli/instactpowercli.ps1")
Downloading latest version of ActPowerCLI from https://github.com/Actifio/powers
hell/raw/master/ActPowerCLI-7.0.0.6.zip
File saved to C:\Users\ADMINI~1\AppData\Local\Temp\2\ActPowerCLI-7.0.0.6.zip
Uncompressing the Zip file to C:\Windows\System32\WindowsPowerShell\v1.0\Modules

Renaming folder
Module has been installed

CommandType     Name                                               ModuleName
-----------     ----                                               ----------
Function        Connect-Act                                        ActPowerCLI
Function        Disconnect-Act                                     ActPowerCLI
Function        get-sargreport                                     ActPowerCLI
Function        Save-ActPassword                                   ActPowerCLI
Function        udsinfo                                            ActPowerCLI
Function        udstask                                            ActPowerCLI
Function        usvcinfo                                           ActPowerCLI
Function        usvctask                                           ActPowerCLI
Cmdlet          Get-ActAppID                                       ActPowerCLI
Cmdlet          Get-LastSnap                                       ActPowerCLI
Cmdlet          Get-Privileges                                     ActPowerCLI

Major         : 7
Minor         : 0
Build         : 0
Revision      : 6
MajorRevision : 0
MinorRevision : 6

```
