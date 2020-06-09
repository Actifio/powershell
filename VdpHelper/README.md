## Introduction

The purpose of this VdpHelper module is to help simplify the usage of ActPowerCLI related tasks and commands. Users can just focus on the task instead of all the checks that are required. 

### Setup
Copy the VdpHelper folder consisting of the two files into the PowerShell Modules directory. Launch PowerShell session and run the `Import-Module` command to load the module in the PS session..

### Usage
The following functions are available:

| Function Name | Parameters | Description |
| --- | -- | -- |
| Vdp-Disable-WorkflowName | Workflow Name | disable the workflow |
| Vdp-Enable-WorkflowName | Workflow Name | enable the workflow |
| Vdp-Run-WorkflowName | Workflow Name | run the workflow |
| Vdp-Run-WorkflowName-Image | Workflow Name, Image Name | run the workflow using a predefined image |
| Vdp-Remove-WorkflowName | Workflow Name | remove the workflow |
| Vdp-Status-WorkflowName | Workflow Name | check the status of the workflow |
| Vdp-Get-WorkflowID | Workflow Name | return the workflow ID |
| Vdp-List-Workflows | App ID | return a list of workflows based on the AppID |
| Vdp-ConvertTo-HostID | HostName | return the Host ID |
| Vdp-ConvertTo-AppID | AppName | return the App ID |
| Vdp-ConvertTo-SlaID | SLA Name | return the SLA ID |
| Vdp-Get-AppAware-JobID | HostName, AppName | return the Job ID for the AppAware job |
| Vdp-Get-Unmount-JobID | HostName, AppName | return the Job ID for the Unmount job |
| Vdp-List-Hosts | | return a list of hosts |
| Vdp-List-Apps | HostID | return a list of applications based on HostID |
| Vdp-Expire-Image | Image Name | expire an image |
| Vdp-Change-Image-Expiration | Image Name , NumHours | increase the expiration by NumHours to the current expiration |
| Vdp-List-Images | App ID , Image Type | return a list of images based on AppID and image type (snapshot, dedup) |
| Vdp-Get-Latest-App-Image | App ID , Image Type | return the latest images based on AppID and image type (snapshot, dedup) |
| Vdp-Remove-Existing-Mount | Src AppName&HostName, Tgt AppName&HostName | remove existing mount based on input parameters |
| Vdp-List-Job-Stats | Job ID, App ID, AppName | display detailed information on the completed Job ID |
| Vdp-Wait-For-JobID-End | Job ID | monitor and wait for the job to complete |
| Vdp-Login-VDP-Password | Vdp ID, Vdp User, Vdp Password | login to the VDP appliance using supplied credentials |
| Vdp-Login-VDP-PasswordFile |Vdp ID, Vdp User, Vdp PasswordFile | login to the VDP appliance using supplied credentials | 
| Vdp-Logoff-VDP | | logoffs from VDP appliance |
| Vdp-Load-Module | | import the ActPowerCLI module if not loaded previously |

### Example

The following example of how we can use the functions in VdpHelper.

```
$CurrWorkflowName='bigdb-wf'
$VdpUser='cliuser'
$VdpIP='vdp-prod'
$VdpPassFile='c:\keys\cliuser.key'

Load-Module
Login-VDP-PasswordFile $VdpIP $VdpUser $VdpPassFile
$CurrWFID = Get-WorkflowID $CurrWorkflowName
Run-WorkflowName $CurrWFID
Logoff-VDP
```
