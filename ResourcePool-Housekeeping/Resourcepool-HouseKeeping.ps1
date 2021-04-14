<#

.SYNOPSIS

    Resource Pool housekeeping of main resource pool in cluster by using vCenter Tags.

.DESCRIPTION

    Best practise is to have no VMs in the root resource pool of the cluster, when using resource pools.
    This script will scan the main resource pools for VMs. And move those VMs into one of the resource pools.
    VMware tags are used to find out in which resource pool a VM should be placed.
    The resource pool needs to be tagged with the same tag as the VM, for this to work.
    When the VM has no resource pool tag, the resource pool will be selected which is tagged with the default root resource pool tag.
    VMs that are created within ... hours are not moved. This is arbitrary and can be fine tuned with script parameters defined in the Begin{} script block.

    VMs in the default resource pool that have a resource pool tag assigned will be moved.

    If possible, the script will use the windows eventlog to log progress. Filter the windows application log by source, where source is the filename of this script.

    Preruiqisites:
    - stored vCenter credentials in the vi credential store, or windows user is known in vCenter and has enough privileges.
 
	EventIDs:
	1-99	log messages
	100-199	warnings
	201-299	verbose
	301-399	error

#>
Begin{
    #=== Script parameters
    $vCenterFQDN="FQDN"
    $ClusterName="cluster" #-- Cluster whre we are going to do some housekeeping
    $MinVM_Age=12 #[hrs] Age filter for VMs that have no Resource Pool tag assigned.

    $tagCategory="tgc_MainResourcePool" # vCenter tag category to use
    $tagDefaultRP="rp_root_default" # vCenter tag assigned to resource pool to be used as default resource pool for VMs without resource pool tag
    
    #==== Main ====
    $TS_start=get-date #-- used for logging purpose

    #-- determine script location and name
    $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
    $scriptname=(Split-Path -Leaf $MyInvocation.mycommand.path).Split(".")[0]

    #-- initialize windows eventlog logging
    $log=Get-EventLog -LogName Application -Source $scriptname -ErrorVariable Err1 -ErrorAction SilentlyContinue | select -first 1
    if ($Err1)
        {
        $log = new-eventlog -LogName Application -Source $scriptname -ErrorAction SilentlyContinue #-- init eventlog
        }

    function write-Log {
        Param(
            [string]$LogName='Application',
            [string]$source=$scriptname,
            [string]$EntryType='skip', # informational
            [string]$message,
            $eventid
        )

        Switch ($entryType) {
            'Warning' {Write-Warning -Message $message}
            'Error' {Write-Error -Message $message}
            'Verbose' {
                Write-Verbose -Message $message
                $EntryType='Information'
                break
                }
            default {write-host $message}
        }
        Write-EventLog -LogName $LogName -Source $source -EntryType $EntryType -EventId $eventID -Message $message
    }

    function writeError {
        param(
            [string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Error' -eventid $eventid
    }

    function writeWarning {
        param(
            [string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Warning' -eventid $eventid
    }

    function writeLog {
        param(
            [string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Information' -eventid $eventid
    }

    function writeVerbose {
        param(
            [string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Verbose' -eventid $eventid
    }

    function exit-script 
    {
        <#
        .DESCRIPTION
            Clean up actions before we exit the script.
            When log object is available, log runtime and exitcode to it.
            Default exit codes are:
            0 = script finished normal (finished_normal parameter was set when function is called)
            99999 = parent script didn't reached end{} and no exitcode was given when exit-script function is called.
            99998 = execution of cleanupcode scriptblock failed.
        .PARAMETER CleanupCode
            [scriptblock] Unique code to invoke when exiting script.
        .PARAMETER finished_normal
            [boolean] To be used in end{} block to notify that script has fully executed.
        .PARAMETER exitcode
            [string] exitcode to past to parent process. When finished_normal is set, exit code will be 0.
            By default it is 99999. When using the function to exit a script due to an error, you can return an exitcode
        #>
        [CmdletBinding()]
        param(
            [string][Parameter( ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$exitcode="99999",
            [scriptblock]$CleanupCode, #-- (optional) extra code to run before exit script.
            [switch]$finished_normal, #-- set in end{} scriptblock of parent script
            [switch]$return,
            [switch]$sleep # sleep for 15 seconds before exit
        )
    
        #-- translate exitcode if it are booleans
        if ($exitcode -eq $false) {$exitcode=-1}
        if ($exitcode -eq $true) {$exitcode=0}
    
        #-- Interpret exitcode 0 as script finished normal
        $finished_normal=$finished_normal -or ($exitcode -eq 0)
        
        if ($finished_normal) {
            $finalmsg= "Hooray.... finished without any bugs....."
            $exitcode=0 #-- script retuns 0
       #     if ($log) {write-verboseEvent -message $msg -eventid 65501} else {Write-Verbose $msg} #-- log to verbose output and/or log file
        } else {
            $finalmsg= "Script ended with errors."
            $msglevel="warning"
      #      if ($log) {write-warningEvent -message $msg -eventid 65501} else {Write-warning $msg}
        }
    
        #-- General cleanup actions
        if ($CleanupCode) {
            try {Invoke-Expression -Command $CleanupCode -ErrorVariable Err1}
            catch {
                $finalmsg=$finalmsg+"`nFailed to execute custom cleanupcode, resulted in error $err1"
                $msglevel="warning"
            }
    
        }
        #-- calculate runtime
        if ($global:ts_start) {
            #-- Output runtime and say greetings
            $ts_end=get-date
            $finalmsg=$finalmsg+"`nRuntime script: {0:hh}:{0:mm}:{0:ss}" -f ($ts_end- $ts_start)  
        } else {
            $finalmsg=$finalmsg+"`nNo ts_start variable found in global scope, cannot calculate runtime."
            $msglevel="warning"
        }
        #-- log exit code
        $finalmsg=$finalmsg+"`nExitcode: $exitcode"
        if ($msglevel -eq "warning"){
            if ($log) {writewarning-message $finalmsg -eventid 65505}  else {write-warning -Message $finalmsg}
    
        } else {
            if ($log) {writelog -message $finalmsg -eventid 65505}  else {write-verbose -Message $finalmsg}
        }
        #-- exit
        $host.SetShouldExit($exitcode)
        if ($sleep) {
            write-host "Sleeping for 15 seconds. (ZzzzZzzzZzzz)"
            start-sleep -Seconds 15}
        if ($return) {return $exitcode} else {exit $exitcode}
    }
}

END{
    $scriptExecutedOK=$true
    exit-script -finished_normal
}

Process {
    writelog -eventid 1 -message "Started housekeeping of main resource pool in cluster $($clustername) with VMs that are older then $($minVM_Age) [hrs]."

    #-- connect to vSphere server
    connect-viserver "$vcenterFQDN" -ErrorVariable Err1
    if ($err1)
    {
        writeWarning -eventid 101 -message "Failed to connect to vCenter service. Error:
        $($err1)"
        exit-script
    }

    #--- get Root resource pool of cluster
    $Cluster= get-cluster -name $Clustername
    $RP_root = (Get-ResourcePool).where({$_.parent -ilike "$($CLuster.name)"})
    if ($RP_root.count -gt 1) {
        Writewarning -eventid 102 -Message "Found multiple resource pools who have $($Cluster.name) as parent."
        exit-script
    }
    #-- find top level resource pools in root resource pool
    [array]$TopLevelRPs=(Get-ResourcePool -ErrorVariable err1 -ErrorAction SilentlyContinue).where({$_.parentid -ilike "$($RP_Root.id)"})
    if ($err1) {
        writeWarning -eventid 104 "Failed to get top level resource pools, error is $($err1)"
        exit-script
    }
    if ($TopLevelRPs.count -eq 0) {
        writeWarning -eventid 105 "No top level resource pools present in $($RP_Root.name)."
        exit-script
    }
    #-- Create list of Top Level resource pools and their tag assignment
    $lst_TopLevelRP=$TopLevelRPs | select name,id,@{N="Tag";E={(Get-TagAssignment -entity $_ -Category $tagCategory).tag}}

    #-- Find VMs who are in top level of root resource pool
    [array]$listOfVMs=(get-vm -ErrorVariable err1 -ErrorAction silentlycontinue ).where({
        ($_.resourcepoolid -ilike $RP_Root.id)
        })
    if ($err1) {
        writeWarning -eventid 103 -Message "Failed to get list of VMs in resource pool $($RP_Root.name).`n Warning was $($err1)"
        exit-script
    }

    #-- Add VMs in default resource pool that have a RP tag assigned to the list of VMs to move
    $default_RPtag=(get-tag).where({$_.name -ilike "$($tagDefaultRP)"})
    $VMsInDftRP=get-resourcepool -id ($lst_TopLevelRP.where({$_.tag -ilike "$($default_RPtag)"})).id | get-vm
    $VMsInDftRP.where({ ((Get-TagAssignment -Category $tagCategory -Entity $_).Tag)
    }).foreach({
        $listofVMs+=$_
    })

    writeVerbose -eventid 202 -message "Found $($listofVMS.count) VMs for housekeeping $($RP_Root.name)."

    #-- Move VMs to resource pool, grouped by tag
    [array]$groupedVMs=$listofVMS | select name,@{N="RP_Tag";E={(Get-TagAssignment -Category $tagCategory -Entity $_).tag}} | Group-Object -Property RP_Tag
    $groupedVMs.foreach({
        $VMgroup=$_
        if ($VMgroup.name.Length -eq 0) {
            #-- No resource pool tag is assigned to this group of vms, using default resource pool
            $destination = (get-tag).where({$_.name -ilike "$($tagDefaultRP)"})
            if (!$destination) {
                writewarning -eventid 109 "Tag $($tagDefaultRP) not found in inventory. Not possible to move untagged vms into default resource pool." 
                return
            }
            #-- select only VMs that are older then .... hours.
            [array]$VMs2Move=(get-vm $VMgroup.group.name).where({$_.createDate -lt ((get-date).AddHours(-1*$MinVM_Age)) })
            if ($VMs2Move.count -le 0) {
                writeverbose -eventid 203 -message "No untagged VMs older then $($minVM_age) hours found."
                return
            }
            writeVerbose -eventid 201 -message "Found $($VMs2Move.count) VMs that don't have a resource pool tag assigned. Moving them to $($defaultRP)."      
        } else {
            #-- group of VMs is tagged with a resource pool tag
            $destination = $VMgroup.name
            #-- select VMs
            [array]$VMs2Move = get-vm $VMgroup.group.name -errorvariable Err1 -ErrorAction SilentlyContinue
            if ($err1) {
                writeWarning -eventid 106 -message "Failed to select VMs for moving to default resource pool.`n Error was $($err1)"
                return
            }
        }
        #-- select resource pool to move VMs into
        $RP_destination = get-resourcepool -id ($lst_TopLevelRP.where({$_.tag -ilike "$($destination)"})).id -ErrorAction SilentlyContinue -ErrorVariable err1
        if ($err1) {
            WriteWarning -eventid 108 -message "Failed to select resource pool $($destination) as destination."
            return  #-- go to next group
        }
        #-- moving VM(s) into resource pool
        $list=(get-view $VMs2Move -erroraction silentlycontinue -errorvariable err1).moref
        if ($err1) {
            writeWarning -eventid 110 -message "Failed to retrieve object list for selected VMs."
            return
        }
        $ResourcepoolObject=Get-View  -id $RP_destination.id -erroraction silentlycontinue -errorvariable err1
        if ($err1) {
            writeWarning -eventid 111 -message "Failed to retrieve Resource Pool object."
            return
        }
        try { $ResourcepoolObject.MoveIntoResourcePool($list) }
        catch {
            writeWarning "Failed to move selected VMs to default resource pool. `n Error was $($err1)" - eventid 107
            return #-- go to next group
        } 
        writeLog -eventid 6 -message "Moved following VMs into resource pool $($RP_Destination.name): $($VMs2Move.name -join ", ") "         
    })
}
