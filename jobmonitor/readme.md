## Overview

This PowerShell script monitors a nominated job till either the job completes or the retry interval is exceeded.

## Usage

You should run the script using the following syntax (change job name to suit your own):
```
.\jobmon.ps1 -paramfile .\actparamsjobmon.ps1 -job Job_4938111
```

## Configuration

Configure the actparams.ps1 file to match your requirements.

### Example 1 - Completed job

In this example the job had already completed

```
PS C:\Users\avandewerdt> .\jobmon.ps1 -paramfile .\actparamsjobmon.ps1 -job Job_4949257
2018-06-09 21:43:16   Job_4949257 ended after this duration (hh:mm:ss.ff): 0:03:00.827
2018-06-09 21:43:16   Job_4949257 ended with this message: Success
```

### Example 2 - Retry exceeded

In this example the job kept running after the retry count had exceeded.  Note this example used different sleep and retry counts to default.

```
PS C:\Users\avandewerdt> .\jobmon.ps1 -paramfile .\actparamsjobmon.ps1 -job Job_4938111
2018-06-09 21:29:15   Job_4938111 is at 16%   This is check 1 of 4 (with 10 second intervals)
2018-06-09 21:29:25   Job_4938111 is at 16%   This is check 2 of 4 (with 10 second intervals)
2018-06-09 21:29:35   Job_4938111 is at 16%   This is check 3 of 4 (with 10 second intervals)
2018-06-09 21:29:45   Job_4938111 is at 16%   This is check 4 of 4 (with 10 second intervals)
2018-06-09 21:29:55   Stopped monitoring after 4 checks
```

### Example 3 - Job ran to completion

In this example the job was monitored to completion using custom retry and sleep settings.

```
PS C:\Users\avandewerdt> .\jobmon.ps1 -paramfile .\actparamsjobmon.ps1 -job Job_4949914
2018-06-09 21:45:01   Job_4949914 is at 14%   This is check 1 of 100 (with 20 second intervals)
2018-06-09 21:45:21   Job_4949914 is at 46%   This is check 2 of 100 (with 20 second intervals)
2018-06-09 21:45:41   Job_4949914 is at 85%   This is check 3 of 100 (with 20 second intervals)
2018-06-09 21:46:02   Job_4949914 ended after this duration (hh:mm:ss.ff): 0:01:10.558
2018-06-09 21:46:02   Job_4949914 ended with this message: Success
```

### Example 4 - Failed to login

In this example the login failed

```
PS C:\Users\avandewerdt> .\jobmon.ps1 -paramfile .\actparamsjobmon.ps1 -job Job_4938111
Failed to login to 172.24.1.180 with username
```


