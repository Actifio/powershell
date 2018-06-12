## Overview

This is a powershell script that will lists all the direct-mount workflows either in an Actifo Appliance or from an input file. The input in the form of SSV. Instead of a csv format, we will be using a SSV (semicolon separated values).

### Setup
You will need to login to an Actifio appliance and run the command from the PowerShell prompt:

### Usage
To list the workflows using an input file - c:\temp\orawflow.ssv, simply run:
```
./list-wflows.ps1 -ssvfile c:\temp\oraflow.ssv
```

To get help on the usage:
```
./list-wflow.ps1 -help
```

To list all the workflows defined in an Actifio appliance:
```
./list-wflow.ps1 
```
