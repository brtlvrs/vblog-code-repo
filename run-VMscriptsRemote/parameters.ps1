# Script Parameters for <scriptname>.ps1
<#
    Author             : <Script Author>
    Last Edit          : <Initials> - <date>
#>

@{
    #-- default script parameters
        LogPath="logs"
        LogExtension=".log"
        LogDays=5 #-- Logs older dan x days will be removed

    #-- Syslog settings
        SyslogServer="syslog.shire.loc" #-- syslog FQDN or IP address

    #-- vSphere vCenter FQDN
        vCenterFQDN="nldc01vs011.vdlgroep.local" #-- vCenter FQDN

        code2Run={
            write-host "Hello World."
            new-item -Path d:\beheer -name "test.txt" -value "hello world" -ItemType File -Force:$true
        }

        LoopSleeptime=2 # [s]
        WatchdogLimit=10 #[min]
        runElevated=$true
}