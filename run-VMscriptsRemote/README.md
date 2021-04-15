# POSH-template

Powershell (POSH) scripting template.

## General

| | |
|---|---|
|Name| Posh-template|
|Version| 0.3|
|License| [MIT license](License)|

## CHANGE LOG

| build| Change |
|---|---|
|0.3|Modulized functions|
|0.2|First version |
|0.1|Initial code|
|0.0|Initial release|

## Usage
Copy the contents of this folder and the folder functions to a new folder for writing a new script in powreshell.

Rename the file posh-template.ps1 as desired and put the powershell code you want to script in the process{} block.
Parameters / variables that you need to code should be placed in the parameters.ps1.  
The parameters file contains a hashtable. This table is known as $P.  
When you want to connect to a vcenter, you put the FQDN of the vCenter in the parameters file, like  
```vCenterFQDN=server.domain.local```  
Then you can call it in the script as $P.vCenterFQDN.
In this way it is easier to use this variable in multiple places instead off hard coding the vCenter FQDN in your code.

## Default functions

### exit-script
Exit script function can be called to exit the script in any stage. When called it will calculate the execution time and also log if the script was completely executed or not.
A custom codeblock (small script) can also be given to the function to run before exiting. Useful if you want to clean up some variables before the script ends.  
An example :

```Powershell

if ($listofHosts.count -le 0) {
    write-warning "No hosts found, will exit script."
    exit-script
}
```
Or when used in the End{} block to notify that the script executed complete:

```Powershell

End {
    exit-script -finished_normal
}
```
