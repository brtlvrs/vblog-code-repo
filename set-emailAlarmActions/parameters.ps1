# Script Parameters for set-emailAlarmActions.ps1
<#
    Author             : Bart lievers
    Last Edit          : BL - 2-1-2019
#>

@{
    vCenterFQDN="value" #-- vCenter FQDN
    SMTPserver="" #-- Mail server
    SMTPport=25 #-- mail server port
    SMTPSendingAddress="something@Domain.local" #-- E-mail address to identify sender

    #-- settings for function set-emailAlarmActions
    emailAlarm=@{
        CSVfile="alarmDefinitions.csv" #-- CSV file containing the alarmdefinitions name and profile. 
        Profiles=@{
            disabled=@{ #-- Alarms in this class will be disabled and e-mail actions removed.
                disabled=$true
                }
            noEmail=@{ #-- Alarms in this class will be striped of e-mail alarm actions
                disabled=$false
                }
            High=@{ #-- 
                disabled=$false
                emailTo=@("servicedesk@acme.local","manager@acme.local") #-- e-mail address(es) 
                repeatMinutes=240 #-- 60 * 4 uur, 
                emailSubject="[HIGH] <hostname vCenter> alarm notification"
                }
            Medium=@{
                disabled=$false
                emailTo=@("servicedesk@acme.local","manager@acme.local") 
                repeatMinutes=1440 #-- 60 [min] * 24 [uur]
                emailSubject="[MEDIUM] <hostname vCenter> alarm notification"
                }
            Low=@{
                disabled=$false
                emailTo=@("servicedesk@acme.local","manager@acme.local") 
                repeatMinutes=0 #-- don't repeat
                emailSubject="[LOW] <hostname vCenter> alarm notification"
                }
            }
        }
}