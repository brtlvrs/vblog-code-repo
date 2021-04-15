# FUNCTIONS

This folder contains powershell functions to be used in various scripting.
When used these functions should be placed in the functions folder of the script. 

## Files

| Files | Folder | Synopsys |
|---|---|---|
|connect-vSphere.ps1| VMware |Wrapper for connect-viserver (PowerCLI)  assuming that credentials are already known. And checking of there is already a session to vCenter.
|exit-script.ps1|  | Script to call on exit of script or on checks in statements. exit-script will log the execution time of the script and if the script completed succesfully or not. It is also possible to add code that should be run on exit.|
|invoke-vmHostSSH.ps1| VMware | Wrapper to execute commands via SSH on a ESXi Host.|
|remove-agedItems.ps1|  | Removing items in a folder older then a given age.|
|send-syslogmessage.ps1| logging  | cmdlet to send syslog messages to a syslog server.|
|functions.psm1|  |powershell module file that loads .ps1 files in this folder and subfolders and exports them as functions.
|

## Way of thinking

Functions are a nice way to structure code. Instead of using the same code multiple times in a script, you put it in a function and call that function multiple times.  
To save these functions to a seperate .ps1 file makes the main script file easier to read.
And when using the functions.psm1 file, you have, basicly, a modulair way of loading scripts.
