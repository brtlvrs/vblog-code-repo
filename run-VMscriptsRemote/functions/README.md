# FUNCTIONS

The functions folder contains custom powershell functions used by scripts  
in the parent folder.  
The functions are loaded via the functions.psm1 module.

To import functions add the following code  to the begin {} block of the script.
```powershell
#-- load custom functions
import-module $scriptpath\functions\functions.psm1 -DisableNameChecking -Force:$true  
```

## DISCLAIMER

    This software is provided "AS IS", without warranty of any kind, express or implied, 
    fitness for a particular purpose and noninfringement. 
    In no event shall the authors or copyright holders be liable for any claim, damages or other liability,
    whether in an action of contract, tort or otherwise, arising from, 
    out of or in connection with the software or the use or other dealings in the software.

## Functions

| Function | Folder | Synopsys |
|---|---|---|
|exit-script|  | Script to call on exit of script or on checks in statements. exit-script will log the execution time of the script and if the script completed succesfully or not. It is also possible to add code that should be run on exit.|

