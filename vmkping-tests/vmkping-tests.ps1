<#
.NOTES
    Dit script bevat een serie van testen specifiek voor de ESXi servers in het AMSL.
    Uitgangspunt is de volgende kernel configuraties van een ESXi host.
    Als framesize wordt de volle framesize gebruikt. Van de framesize wordt 28 bytes afgetrokken 
#>

Begin{
    #=== Script parameters
    $vcenterFQDN = "<FQDN/IPV4>"
    $testDefFileName = "vmkpingTestDef.ps1"

    #==== Main ====
    $global:ts_start=Get-Date
    $VerbosePreference="SilentlyContinue"
    $WarningPreference="Continue"
    $DebugPreference="SilentlyContinue"
    $ErrorActionPreference="SilentlyContinue"
    Clear-Host

    #-- determine script location and name
    $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
    $scriptname=(Split-Path -Leaf $MyInvocation.mycommand.path).Split(".")[0]
    $serialdate=  "{0:yyyyMMdd-HHmmss}" -f (get-date)    

    # init text log
    $global:logfile=new-item -Path $scriptPath -Name "$($scriptname)-$($serialdate).log" -ErrorAction SilentlyContinue

    function New-TimeStamp {
        <#
            .SYNOPSIS  
                Returns a timestamp based on the current date and time     
            .DESCRIPTION 
                Returns a timestamp based on the current date and time 
            .NOTES  
                Author         : Bart Lievers
                Copyright 2013 - Bart Lievers
            .PARAMETER Sortable
                [switch] Make the timestamp sortable. like YYYYMMDD instead of DDMMYYYY
            .PARAMETER Serial
                [switch]  Remove seperation characters. Fur usage in filenames
            .PARAMETER noSeconds
                [switch] don't return the seconds in the timestamp
        #>	
        [cmdletbinding()]
        param(
            [switch]$Sortable,
            [switch]$serial,
            [switch]$noSeconds
            )
            $TimeFormat="%H:%M:%S"
            if ($Sortable) {
                $TimeFormat="%Y-%m-%d_%H:%M:%S"
            } else {
                $TimeFormat="%d-%m-%Y_%H:%M:%S"	
            }
            if($serial){
                $TimeFormat=$TimeFormat.replace(":","").replace("-","")
            }
            if ($noSeconds) {
                $TimeFormat=$TimeFormat.replace(":%S","").replace("%S","")
        
            }
            return (Get-Date -UFormat $TimeFormat)
    }

    function write-Log {
        Param(
            [string]$Logfile=$global:logfile.fullname,
            [string]$EntryType='informational', # informational
            [parameter(ValueFromPipeline=$true)][string]$message,
            $eventid,
            [parameter(mandatory=$false)][consolecolor]$foregroundcolor
        )

        Switch ($entryType) {
            'Warning' {
                Write-Warning -Message $message
                $prefix ="Warning"
                break
                }
            'Error' {
                Write-Error -Message $message
                $prefix ="Error"
                break
                }
            'Verbose' {
                Write-Verbose -Message $message
                $prefix="Verbose"
                break
                }
            default {
                $prefix ="Information"
                $param=@{
                    object=$message
                }
                if ($foregroundcolor) { $param["foregroundcolor"]=$foregroundcolor}
                write-host @param
                }
        }
        $prefix="$(new-timestamp) |{0,-12} |{1:0000} | " -f $prefix,$eventid
        $msg="$($prefix) $($message)"


    #-- handle multiple lines
    $msg=[regex]::replace($msg, "`n`r","", "Singleline") #-- remove multiple blank lines
    $msg=[regex]::Replace($msg, "`n", "`n"+$Prefix, "Singleline") #-- insert prefix in each line
    #-- write message to logfile, if possible
    if ($LogFile.length -gt 0) {
        if (Test-Path $LogFile) {
            $msg | Out-File -FilePath $LogFile -Append -Width $msg.length } 
        else { Write-Warning "No valid log file (`$LogFilePath). Cannot write to log file."}
    } 
    else {
        Write-Warning "No valid log file (`$LogFilePath). Cannot write to log file."
    }
    }
        
    function writeError {
        param(
            [parameter(ValueFromPipeline=$true)][string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Error' -eventid $eventid
    }

    function writeWarning {
        param(
            [parameter(ValueFromPipeline=$true)][string]$message,
            $eventid
        )
        write-log -message $message -EntryType 'Warning' -eventid $eventid
    }

    function writeLog {
        param(
            [parameter(ValueFromPipeline=$true)][string]$message,
            $eventid,
            [parameter(Mandatory=$false)][consolecolor]$foregroundcolor
        )
        $param=@{
            message=$message
            eventid=$eventid
            EntryType='Information'
        }
        if ($foregroundcolor) {$param["foregroundcolor"]=$foregroundcolor}
        write-log @param
    }

    function writeVerbose {
        param(
            [parameter(ValueFromPipeline=$true)][string]$message,
            $eventid
        )
        $param=@{
            message=$message
            eventid=$eventid
            EntryType='Verbose'
        }
        write-log @param
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
            By default it is -1 or #FFFFFF. When using the function to exit a script due to an error, you can return an exitcode
        .PARAMETER sleep
            [boolean] Sleep 15 seconds before exit script.
        .PARAMETER return
            [boolean] return instead of exit. 
        #>
        [CmdletBinding()]
        param(
            [string][Parameter( ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$exitcode="-1",
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
        } else {
            $finalmsg= "Script ended with errors."
            $msglevel="warning"
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
            if ($logfile) {writewarning -message $finalmsg -eventid 65505}  else {write-warning -Message $finalmsg}
    
        } else {
            if ($logfile) {writelog -message $finalmsg -eventid 65505 -foregroundcolor Green }  else {write-verbose -Message $finalmsg}
        }
        #-- exit
        if ($sleep) {
            write-host "Sleeping for 15 seconds. (ZzzzZzzzZzzz)"
            start-sleep -Seconds 15}
        if ($return) {return $exitcode} else {exit $exitcode}
    }

    <#
.SYNOPSYS
    Remove files/items in folder that are aged
.DESCRIPTION

.PARAMETER Age
    [int] max Age for item until it is removed.
.Parameter folder
    [string] Folder to clean up
.NOTES

    *** DISCLAIMER ***

#>
    function remove-AgedItems {
        [cmdletbinding()]
        param (
            [int]$Age,
            [string]$folder
        )

        #-- input validation
        if ($age -lt 1) {
            writewarning -eventid 151 -message "Invalid age given $age [days], we will use 30 days as default."
            $age=30
            }
        if ($folder.Length -lt 3) {
            writewarning -eventid 152 -message "Folder to cleanup is invalid, exit script."
            return
        }
        if (!(test-path $folder)) {
            writewarning -eventid 153 -message "Failed to find $folder, exiting script."
            return
        }
        #-- select root folder and its childrens
        $rootFolder=Get-item $folder
        $childrens=get-childitem $rootFolder -
        #-- log threshold date
        $thresholdDate=(get-date).AddDays(-1*$age)
        writelog -eventid 51 -message ("Files and folders in $folder that are created on or before {0:dd MMM yyyy} will be deleted." -f $thresholdDate)
        #-- check if there are childrens that are older then a certain age
        $currentDate=get-date
        $itemsToClean=$childrens | ?{((get-date) - $_.CreationTime ).days -ge $age} 
        if ($itemsToClean.count -le 0) {
            writelog -eventid 52 -message  "Nothing to cleanup in $folder"
            return
        }
        #-- remove items
        $itemsToClean | Remove-Item -Recurse -Force -Confirm:$false
    }    


    #-- let's start
    $message="Started Script at $($global:TS_start)."
    $message=$message+"`n     Script name: $($scriptname).ps1"
    $message=$message+"`n     Script location: $($scriptpath)"
    $message=$message+"`n     Logfile : $($logfile.fullname)"
    writelog -eventid 1 -message $message -foregroundcolor magenta
}

END{
    $scriptExecutedOK=$true
    exit-script -finished_normal
}

Process {
    if ($vCenterFQDN.length -lt 0) {
        writeWarning -eventid 307 -message "No valid vcenter (or vSphere Host) FQDN is given."
        exit-script

    }

    writelog -eventid 7 -message "connecting to $($vcenterFQDN)"
    #-- connect to vSphere server
    connect-viserver "$vcenterFQDN" -force -ErrorVariable Err1 -ErrorAction SilentlyContinue | out-string | writelog -eventid 6
    if ($err1)
    {
        writeWarning -eventid 101 -message "Failed to connect to vCenter service. Error:
        $($err1)"
        exit-script
    }


    #-- Load tests
    $path="$scriptpath\$($testDefFileName)"
    if (!(test-path -Path $path)) {
        writeWarning -eventid 105 -message "Failed to load file with vmkping tests. ($($path))
        $($err1)"
        exit-script
    } 
    Remove-Variable -Name tests -ErrorAction SilentlyContinue 
    $tests = & $path

    #-- Ask user to select one or multiple ESXi hosts to run vmkping commands on. Only connected and/or hosts in maintenance mode are shown.
    $vmhosts=((get-vmhost).where({
        ($_.ConnectionState -imatch "(Connected|Maintenance)") -and ($_.Powerstate -imatch "PoweredOn")
    })|sort-object name)|Out-GridView -Title " select host " -OutputMode Multiple

    writelog -eventid 10 -message  "De volgende ESXi hosts zijn geselecteerd om vanaf te testen: `n$($vmhosts | ft -AutoSize | out-string)"
    $results=@()
    #-- run the tests, run each test on all selected hosts
    ($tests.GetEnumerator()|Sort-Object name).ForEach({
        $test=$_
        $test=$test.value
        #-- distracting IPv4 header from framesize (28 bytes), 
        #   vmkping size is the payload size of a frame and does not include the header size of 28 bytes.
        $test.test.size=$test.test.size-28
        write-log -eventid 11 -message "`n`n========"
        write-log -eventid 12 -message "Working with test $($test.name)"

        if ($test.enabled) {
            #-- walk through each selected host to execute test
            write-log -eventid 13 -message ($test.test | ft -AutoSize | out-string)
            $vmhosts.foreach({
                $vmhost = $_
                write-log -eventid 14 -message "running test on $($vmhost.name)"
                $esxcli=get-esxcli -v2 -vmhost $vmhost

                try {
                    $result=$esxcli.network.diag.ping.invoke($test.test).summary
                }
                catch {
                    $msg=$_
                    $result=$msg.ToString()        }
                #-- test results are shown when script is finished
                $results+=$result| select-object @{N='test';E={$test.name}},@{N='vmhost';E={$vmhost.name}},@{N="Size";E={$test.test.size+28}},* | sort-object vmhost
                return        
            }) #| sort-object vmhost | ft -AutoSize
        } else {
            writelog -eventid 15 -message  "Skipping test."
        }
    })
    write-log -eventid 16 -message  ($results | ft -AutoSize | out-string )
    [array]$failedResults= $results.where({$_.packetlost -gt 0})
    if ($failedResults.count -gt 0) {
        writewarning -eventid 115 -message "vmkping tests failed on the following hosts`n$(($failedResults | group-object -Property vmhost).name | out-string)"
        writewarning -eventid 116 -message "vmkping tests failed with the following tests`n$(($failedResults | group-object -Property test).name | out-string)"
        writeWarning -eventid 117 -message "Not all vmkping tests finished with 0% packet loss`n$($failedResults | ft -autosize | out-string)"
    }
}
