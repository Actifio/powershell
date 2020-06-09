# Introduction

VdpHelper is a PowerShell module that can simplify VDP related access and operations. 

The following are some of the predefined functions:

- Vdp-Disable-WorkflowName: [ parm: Workflow Name ] ; disable the workflow
- Vdp-Enable-WorkflowName: [ parm: Workflow Name ] ; enable the workflow
- Vdp-Run-WorkflowName: [ parm: Workflow Name ] ; run the workflow
- Vdp-Run-WorkflowName-Image: [ parm: Workflow Name, Image Name ] ; run the workflow using a predefined image
- Vdp-Remove-WorkflowName: [ parm: Workflow Name ] ; remove the workflow
- Vdp-Status-WorkflowName: [ parm: Workflow Name ] ; check the status of the workflow
- Vdp-Get-WorkflowID: [ parm: Workflow Name ] ; return the workflow ID 
- Vdp-List-Workflows: [ parm: App ID ] ; return a list of workflows based on the AppID

- Vdp-Get-HostID: [ parm: HostName ] ; return the Host ID
- Vdp-Get-AppID: [ parm: AppName ] ; return the App ID
- Vdp-Get-SlaID: [ parm: SLA Name ] ; return the SLA ID 

- Vdp-Get-AppAware-JobID: [ parm: HostName, AppName ] ; return the Job ID for the AppAware job 
- Vdp-Get-Unmount-JobID: [ parm: HostName, AppName ] ; return the Job ID for the Unmount job 

- Vdp-List-Hosts: [ parm: n/a ] ; return a list of hosts
- Vdp-List-Apps: [ parm: HostID ] ; return a list of applications based on HostID

- Vdp-Expire-Image: [ parm: Image Name ] ; expire an image
- Vdp-Change-Image-Expiration: [ parm: Image Name , NumHours ] ; increase the expiration by NumHours to the current expiration
- Vdp-List-Images [ parm: App ID , Image Type ] ; return a list of images based on AppID and image type (snapshot, dedup)
- Vdp-Get-Latest-App-Image: [ parm: App ID , Image Type ] ; return the latest images based on AppID and image type (snapshot, dedup)

- Vdp-Remove-Existing-Mount: [ parm: Src AppName&HostName, Tgt AppName&HostName ] ; remove existing mount based on input parameters

- Vdp-List-Job-Stats: [ parm: Job ID, App ID, AppName ] ; display detailed information on the completed Job ID
- Vdp-Wait-For-JobID-End: [ parm: Job ID ] ; monitor and wait for the job to complete

- Vdp-Login-VDP-Password: [ parm: Vdp ID, Vdp User, Vdp Password ] ; login to the VDP appliance using supplied credentials
- Vdp-Login-VDP-PasswordFile: [ parm: Vdp ID, Vdp User, Vdp PasswordFile ] ; login to the VDP appliance using supplied credentials 
- Vdp-Logoff-VDP: [ parm: n/a ] ; logoffs from VDP appliance

- Vdp-Load-Module: [ parm: n/a ] ; import the ActPowerCLI module if not loaded previously


### Setup

Download and copy the modules in the PowerShell modules directory. Run the `Import-Module` command to load the module in the PS session.

### Usage

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
