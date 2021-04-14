# set-emailAlarmActions

set-sendEmailAlarmActions is a script to configure sendmail alarmactions on vSphere Alarm definitions in batch.

A basic vCenter 6.7 U1 deployment contains around 268 Alarm definitions. And to configure them by hand is tough. So this script will help you to do it for you.

## General

| | |
|---|---|
|Name| set-emailAlarmActions|
|Version| 0.1|
|License| [MIT license](License)|

## CHANGE LOG

| build| Change |
|---|---|
|0.1|Initial code|
|0.0|Initial release|

## Set-up

1. Download this repository with all the files.
1. Edit the settings in the parameters.ps1
1. add/remove/edit the alarmdefinitions.csv file
1. execute the script

### pre-requisites

- Powershell
- PowerCLI
- script files
    - alarmDefinitions.csv - containing the alarmdefinitions to work with
    - parameters.ps1 - containing script parameters and variables
    - functions\connect-vSphere.ps1 - PS wrapper for connect-viserver
    - functions\exit-script - function to exit cleanly a script

### vCenter authentication

Credentials are not stored in the script. The script assumes that the user it is running under, is known by vCenter.
You can also store credentials for vCenter with the connect-viserver cmdlet. Please see ```get-help connect-viserver -full``` for more info.

### Way of thinking

The AlarmDefinitions.csv is a CSV file containing 2 columns of fields, these are:
|column/field| description|
|---|---|
|name| The alarmdefinition name, like 'Host connection and power state'|
|alarmClass| The alarmclass or profile that should be configured for the alarm, by default these are : disabled, noEmail, Low, Medium, High|

#### alarmclass / profile

The script uses alarmclasses or profiles to configure the desired e-mail Alarmaction. The settings of these classes are defined in the parameters.ps1 file. The following alarmclasses are known, but you can add more.

|alarmClass | Alarm is | Email Subject | Email TO | Frequency |
|---|---|---|---|---|
|disabled|disabled
|noEmail|enabled|
|low|enabled|[LOW] \<hostname vCenter\> alarm notification| [array of strings] notification receiver| once on state change|
|medium|enabled|[MEDIUM] \<hostname vCenter\> alarm notification| [array of strings] notification receiver| once on state change and every 24 hrs|
|high|enabled|[HIGH] \<hostname vCenter\> alarm notification| [array of strings] notification receiver| once on state change and every 4 hrs|

#### workflow

When executed, the script will process in the following steps

| | |
|---|---|
| init | Loading the functions in the functions folder<br>connecting to the vCenter
|validation| Validating the CSV file. checking if the used alarmClasses are defined in the parameters.ps1
|processing CSV| Processing the CSV file in batches, filtered by the alarmClass.<br> The settings / profile for the alarmclass is read from the parameters.ps1

## Final

I hope this code is usefull. Use it according to the MIT license.