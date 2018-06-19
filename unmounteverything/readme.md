## Overview

This PowerShell script unmounts all mounted images without deleting them.

## Usage

You should run the script using the following syntax:
```
.\unmounteverything.ps1 -paramfile .\actparams.ps1 
```

## Configuration

Configure the actparams.ps1 file to match your requirements.

### Example 1 - Completed unmount run

In this example we found two mounts and unmounted them both.

```
PS C:\Users\av> .\unmounteverything.ps1 -paramfile .\actparams.ps1
2018-06-18 22:46:23  Logged into 10.1.1.1 with username admin
2018-06-18 22:46:23  There are 2 mounts.  They are: Image_5141616 Image_5141618
2018-06-18 22:46:23  Unmounting them now:

result
------
Job_5141662 to unmount Image_5141616 started
Job_5141664 to unmount Image_5141618 started
2018-06-18 22:46:39  Found 2 running unmounts, progress%: 34 34   Check 1 of 100000 (60 second intervals)
2018-06-18 22:47:39  Found 2 running unmounts, progress%: 34 34   Check 2 of 100000 (60 second intervals)
2018-06-18 22:49:13  There are no mounts.  We are complete
```
### Example 2 - Unsuccessful unmount run

In this example we found one mounts but the unmount failed.  Look for failed unmount jobs and action them.
```
PS C:\Users\av> .\unmounteverything.ps1 -paramfile .\actparams.ps1
2018-06-18 22:50:34  Logged into 10.1.1.1 with username admin
2018-06-18 22:50:35  There are 1 mounts.  They are: Image_0996972
2018-06-18 22:50:35  Unmounting them now:

result
------
Job_1182560 to unmount Image_0996972 started
2018-06-18 22:50:48  There are still mounts.  Please investigate failed unmount jobs or re-run this script.
```
