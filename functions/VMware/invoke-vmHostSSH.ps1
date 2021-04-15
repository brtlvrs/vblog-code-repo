function invoke-vmHostSSH {
    [cmdletbinding()]
    Param (
        [string]$plinkLocation=$global:plinkLocation,
        $credential=$global:plinkCredential,
        [parameter(mandatory=$true)][string]$command,
        [parameter(mandatory=$true)]$vmHost,
        $server=$global:global:DefaultVIServer
    )
    <#
    .SYNOPSYS 
        Run commands on a ESXi host via SSH
    .DESCRIPTION
        Using plink to run commands on an ESXi host via SSH
    .Parameter plinkCredential
        [PScredential] Powershell credential object containing username and password acces to the ESXi host
    .PARAMETER plinkLocation
        [string] Location of the plink.exe program
    .PARAMETER command
        [string] The command that should be executed via SSH
    .PARAMETER vmHost
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl] The ESXi host to run the command against.
    #>
    Begin {
        if (!(Test-Path $plinkLocation)) {
            write-warning "Plink.exe not found at $plinkLocation." -ForegroundColor Yellow
            exit
        }
        if ($command.Length -le 0) {
            Write-Warning "No command string is given."
            exit
        }
    }
    End {}
    Process{
        #-- start SSH service on ESXi if it is not already running
        $startSSH=(!(Get-VMHostService -VMHost $vmHost.Name | ?{$_.key -ilike "TSM-SSH"}).running)
        if ($startSSH) { Get-VMHostService -VMHost $vmHost | ?{$_.key -ilike "TSM-SSH"} | Start-VMHostService -confirm:$false | Out-Null}
        #-- build command
        $plink= "$plinkLocation " +$vmHost.name+ " -l " +$credential.username+ " -pw " + $credential.GetNetworkCredential().Password+  " -ssh"
        #invoke-expression ("echo Y | " +$plink + " exit") #-- try connection to cache fingerprint
        $result= Invoke-Expression ("echo Y | "+ $plink + " " + $command)
        #-- stop SSH service if it wasn't running before
        if ($startSSH) { Get-VMHostService -VMHost $vmHost | ?{$_.key -ilike "TSM-SSH"} | Stop-VMHostService -Confirm:$false | Out-Null}
        #-- return plink result
        return $result
    }
}