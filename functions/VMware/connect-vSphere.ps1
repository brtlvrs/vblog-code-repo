function connect-vSphere {
    [cmdletbinding()]
    Param(
        [string]$vCenter
    )
    Begin{}
    End{}
    Process{
        #-- connect to vCenter (if not already connected)
        $noConnection=$true
        if ($global:DefaultViserver) {
            if ($global:DefaultViserver.IsConnected -and $global:DefaultViserver.name -ilike $vCenter) {
                write-host "Already connected to vCenter" $vCenter -ForegroundColor Cyan
                $noConnection=$false
            } elseif ($global:DefaultViserver.IsConnected ) {
                Disconnect-VIServer -Server $global.defaultViserver -Confirm:$false -Force
            }
        }
        if ($noConnection) {
            Connect-VIServer $vCenter -ErrorVariable Err1
            if ($err1) {
                Write-Warning "Failed to connect  to vCenter $vCenter."
                write-verbose $err1
                exit-script
                }
        }
    }
}