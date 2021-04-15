<#
.SYNOPSIS
   Add the Veeam service account to the local administrators group.
#>
[CmdletBinding()]
Param(
    [PSCredential]$userCreds,
    $VMs
)
Begin{
    $ts_start=get-date #-- note start time of script
    #-- initialize environment
    $DebugPreference="SilentlyContinue"
    $VerbosePreference="SilentlyContinue"
    $ErrorActionPreference="Continue"
    $WarningPreference="Continue"
    clear-host #-- clear CLi

	#-- determine script location and name
    $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
    $scriptname=(Split-Path -Leaf $MyInvocation.mycommand.path).Split(".")[0]
    
    #-- Load Parameterfile
    if (!(test-path -Path $scriptpath\parameters.ps1 -IsValid)) {
        write-warning "Cannot find parameters.ps1 file, exiting script."
        exit
    } 
    $P = & $scriptpath\parameters.ps1

    #-- load functions
    if (Test-Path -IsValid -Path($scriptpath+"\functions\functions.psm1") ) {
        write-host "Loading functions" -ForegroundColor cyan
        import-module ($scriptpath+"\functions\functions.psm1") -DisableNameChecking -Force:$true #-- the module scans the functions subfolder and loads them as functions
    } else {
        write-verbose "functions module not found."
        exit-script
    }
    
    #-- start new log file
    $log=New-LogObject -name $scriptname -TimeStampLog -location ($scriptPath+"\"+$P.logpath) -extension $P.LogExtension -keepNdays $P.logdays -syslogServer $P.syslogserver
}

End{
    #-- we made it, exit script.
    exit-script -finished_normal
}

Process{
    #-- connect to vSphere
    connect-vsphere $P.vcenterfqdn
    #-- select VMs
    if (!$VMs) {
        $VMs=get-VM | Out-GridView -OutputMode Multiple -Title "Select VM(s)" 
        if (!$VMs) {
            $log.warning("No VMs selected.")
            exit-script
        }
    }
    #-- get credentials
    if (!$userCreds) {
        $userCreds=Get-Credential -Message "Provide User credentials with sufficient privilege for running scripts in selected VMs." -ErrorVariable Err1
        if ($err1) {
            $log.warning("Failed to get credentials.")
            exit-script
        }
    }

    foreach ($vm in $VMs) {
        $log.msg("Working on VM $($VM.name)")
        #-- make sure VM is poweredOn
        if ($vm.PowerState -imatch "PoweredOff") {
            $log.msg("VM is poweredOff, will start VM and wait for VMwareTools")
            $ts_shutdown=get-date
            start-VM $vm -Confirm:$false
            $shutdownVM=$true
        }
        while ((get-vm $vm).extensiondata.guest.toolsrunningStatus -inotmatch "guestToolsRunning") {
            if (((get-date)-$ts_shutdown).totalminutes -ge $P.watchdogLimit) {
                $logs.warning("Waited $($P.watchdogLimit) minutes. VMware tools not running in VM $($VM.name)")
                exit-script
            }
            start-sleep -Seconds $P.LoopSleeptime
        }
        if ($P.runElevated) {
            $log.verbose("wrapping scriptcode with code to run it elevated.")
            $scriptCode={
                #-- one-liner to add VEEAM service account to local administrators
                $code= $P.code2run
                #-- run one-liner in elevated powershell session
                Start-Process powershell.exe -verb runAs -argumentList "-noprofile $code -executionpolicy bypass" 
            }
        } else {
            $scriptCode=$P.code2Run
        }
        #-- run script via VMware tools
        Invoke-VMScript -VM $vm -GuestCredential $userCreds -ErrorVariable err1 -ScriptText $scriptCode | Out-String -Width 1024
        if ($err1) {
            $log.warning("Failed to run code on VM $($VM.name)")
            $log.verbose("Errormessage : $err1")
        }
        if ($shutdownVM) {Shutdown-VMGuest -VM $VM}
    }
}