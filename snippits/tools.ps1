function set-defaultSatpToRR{
    $esxcli=get-esxcli -v2 -vmhost (get-vmhost | Out-GridView -Title "Select vSphere host" -OutputMode Single)
    if (($esxcli.storage.nmp.satp.list.Invoke() | ?{$_.name -ilike "VMW_SATP_DEFAULT_AA"}).DefaultPSP -ilike "VMW_PSP_RR") {
        write-host "SATP: VMW_SATP_DEFAULT_AA is already set to VMW_PSP_RR"
    } else {
    $rslt=$esxcli.storage.nmp.satp.set.Invoke(
        @{
            satp="VMW_SATP_DEFAULT_AA"
            defaultpsp="VMW_PSP_RR" #-- Round Robin path selection policy
        }
    )
    if ($rslt -ilike "*EsxCLI.CLIFault.summary*") {
        write-host "Failed to set SATP 'VMW_SATP_DEFAULT_AA' to 'VMW_PSP_RR'" -ForegroundColor Yellow
    } else {
        write-host "Change was succesfull"
    }
    }
}