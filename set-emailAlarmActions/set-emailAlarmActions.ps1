<## 
.SYNOPSYS
    Set / remove email actions based on alarm triggers.

.DESCRIPTION
    Script to set or remove the email action type for alarm triggers.
    It wil set the general e-mail settings. 

.NOTES
    Files needed:
        - parameters.ps1
        - CSV file provided in pramaters.ps1 file

    *** DISCLAIMER ***

    This software is provided "AS IS", without warranty of any kind, express or implied, 
    fitness for a particular purpose and noninfringement. 
    In no event shall the authors or copyright holders be liable for any claim, damages or other liability,
    whether in an action of contract, tort or otherwise, arising from, 
    out of or in connection with the software or the use or other dealings in the software.
##>
[CmdletBinding()]
Param ()

Begin {
    $global:ts_start=Get-Date
    $VerbosePreference="SilentlyContinue"
    $WarningPreference="Continue"
    $DebugPreference="SilentlyContinue"
    $ErrorActionPreference="SilentlyContinue"
    Clear-Host

    #-- Get Script Parameters
    $scriptPath=(get-item (Split-Path -Path $MyInvocation.MyCommand.Definition)).FullName
    $scriptName=Split-Path -Leaf $MyInvocation.MyCommand.path
    write-verbose "Scriptpath : " $scriptpath
    write-verbose "Scriptname : "$scriptName
    write-verbose "================================"

    #-- load script parameters
    if(!(Test-Path -Path $scriptPath\parameters.ps1 -IsValid)) {
        Write-Warning "Parameters.ps1 not found. Script will exit."
        exit
    }
    $P = & $scriptPath\parameters.ps1

    #-- load functions
    if (Test-Path -IsValid -Path($scriptpath+"\functions\functions.psm1") ) {
        write-host "Loading functions" -ForegroundColor cyan
        import-module ($scriptpath+"\functions\functions.psm1") -DisableNameChecking -Force:$true  #-- the module scans the functions subfolder and loads them as functions
    } else {
        write-verbose "functions module not found."
        exit-script
    }

    #-- connect to vCenter (if not already connected)
    connect-vSphere -vCenter $P.vCenterFQDN

    function set-emailAlarmActions {
        [cmdletbinding()]
        Param(
            $Alarms,
            $AlarmClass,
            $AlarmProfile
        )

    }
}

End {
    exit-script -finished_normal
}

Process {
    #-- set SMTP settings
    Get-AdvancedSetting -Entity $p.vCenterFQDN -Name mail.smtp.server | Set-AdvancedSetting -Value $P.SMTPserver -Confirm:$false
    Get-AdvancedSetting -Entity $p.vCenterFQDN -Name mail.smtp.port | Set-AdvancedSetting -Value $P.SMTPport -Confirm:$false
    Get-AdvancedSetting -Entity $p.vCenterFQDN -Name mail.sender | Set-AdvancedSetting -Value $P.SMTPSendingAddress -Confirm:$false

    #-- load CSV
    [array]$alarmPriorities= Import-Csv $scriptpath\$($P.emailAlarm.CSVfile) -Delimiter ";"
    if ($alarmPriorities.count -le 0) {
        Write-Warning "No Definitions found in $($P.emailAlarm.CSVfile)"
        exit-script
    }
    #-- sort CSV and save 
    $alarmPriorities = $alarmPriorities | sort name
    $alarmPriorities |  Export-Csv -del   ";"-NoTypeInformation -Path $scriptpath\$($P.emailAlarm.CSVfile)
    Write-host "Found "  $alarmPriorities.Count  " Alarms in the following groups : "

    $alarmPriorities | Group-Object -Property alarmClass | select name,count | ft -AutoSize| out-string | write-host

    #-- validate CSV for unknown classes
    [array]$difference=Compare-Object -ReferenceObject ($alarmPriorities | Group-Object -Property alarmclass | select -ExpandProperty name) -DifferenceObject ($P.emailAlarm.Profiles.GetEnumerator().name)
    if ($difference| ?{$_.SideIndicator -ilike "<="}) {
        write-warning "Unknown alarm classes found in CSV : "
        foreach($unknownClass in ($difference| ?{$_.SideIndicator -ilike "<="}).inputobject) {
            write-warning "alarmclass : $unknownClass, found in:"
            write-warning (($alarmPriorities | ?{$_.alarmclass -ilike $unknownClass}) | select -ExpandProperty name)
        }
    }

    #-- process CSV file
    foreach ($alarmCLass in ($alarmPriorities | Group-Object -Property alarmclass | select -ExpandProperty name)) {
        write-host "=== alarmClass : $alarmClass ===" -ForegroundColor Cyan
        $alarmProfile=$p.emailAlarm.Profiles.($alarmclass)
        if (!$P.emailAlarm.Profiles.Contains($alarmclass) ) {
            #-- unknown alarmclass found in CSV
            write-warning "Alarmclass $alarmClass not found in parameters file."
        } elseif ($Alarmclass -imatch "^(disabled|noEmail)$") {
            #-- process noEmail or disabled Alarm definitions
            foreach ($row in ($alarmPriorities | ?{$_.alarmClass -ilike $alarmClass})) {
                Get-AlarmDefinition -Name $row.Name | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false | Out-Null #-- remove send-email actions                  
                Get-AlarmDefinition -Name $row.name | Set-AlarmDefinition -Enabled:(!$AlarmProfile.disabled) -Confirm:$false | out-null #-- disable alarm
                Get-AlarmDefinition -Name $row.name | select name,Description,Enabled,ActionRepeatMinutes,Entity | ft -AutoSize 
            }
        }  else {
            #-- process all other classes
            foreach ($row in ($alarmPriorities | ?{$_.alarmClass -ilike $AlarmClass})) {
                #-- Enable / disable alarm
                $alarmDef = Get-AlarmDefinition -Name $row.name  | Set-AlarmDefinition -Enabled (!($AlarmProfile.disabled))
                $alarmDef = Get-AlarmDefinition -Name $row.name 
                $alarmdef | select name,Description,Enabled,ActionRepeatMinutes,Entity | ft -AutoSize
                #--set e-mail actions
                $alarmDef | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction -Confirm:$false
                foreach ($email in $AlarmProfile.emailTo) {
                    $alarmaction=$alarmdef | New-AlarmAction -Email -To $email -Subject $AlarmProfile.emailSubject
                    $alarmaction |  select actiontype,subject,to,trigger | ft -Autosize  | out-string | write-host
                    $triggers=@()
                    $triggers+=$alarmaction | New-AlarmActionTrigger -StartStatus Green -EndStatus Yellow 
                    $triggers+=$alarmaction | New-AlarmActionTrigger -StartStatus red -EndStatus Yellow 
                    $triggers+=$alarmaction | New-AlarmActionTrigger -StartStatus yellow -EndStatus green
                    $triggers | select StartStatus,EndStatus,Repeat,AlarmAction | ft -Autosize  | out-string | write-host
                }
            }
        }
    }
}
