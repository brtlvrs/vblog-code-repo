#-- vmkping test definitions, these are run from every selected ESXi host
<#
    dit bestand bevat de test opdrachten gebruikt in vmkping-tests.ps1

    De testen zijn opgesteld voor de volgende kernel configuratie binnen de amsl omgeving


    Dit bestand is een hashtabel die als psobject binnen vmkping-tests.ps1 gebruikt wordt
    De hashtabel is een nested hashtabel. De buitenste schil bevat per regel een test.
    De key naam is als volgt opgebouwd
            vmk0_vcsa
            |    |----> doel bestemming van vmkping
            |---------> bron (vm kernelport) waar vanaf de vmkping uitgevoerd wordt

    De key zelf is ook een hashtabel en bevat de volgende keys:

        Name: test definitie naam
        Enabled: in- of uitschakelen van deze test
        test: een hashtable met de esxcli.network.diag.ping.invoke parameters

    De test key is een hashtable die als parameter aan de esxcli.network.diag.ping.invoke() opdracht meegegeven wordt.
    De volgende parameters kunnen hierin opgenomen worden
        host                           Unset, ([string], optional)                                                                                                                                                                           
        wait                           Unset, ([string], optional)                                                                                                                                                                           
        df                             Unset, ([boolean], optional)                                                                                                                                                                          
        interval                       Unset, ([string], optional)                                                                                                                                                                           
        ttl                            Unset, ([long], optional)                                                                                                                                                                             
        debug                          Unset, ([boolean], optional)                                                                                                                                                                          
        nexthop                        Unset, ([string], optional)                                                                                                                                                                           
        count                          Unset, ([long], optional)                                                                                                                                                                             
        netstack                       Unset, ([string], optional)                                                                                                                                                                           
        size                           Unset, ([long], optional)                                                                                                                                                                             
        ipv4                           Unset, ([boolean], optional)                                                                                                                                                                          
        ipv6                           Unset, ([boolean], optional)                                                                                                                                                                          
        interface                      Unset, ([string], optional)   

#>
@{
    #-- vmkping from vmk0 to vcenter ip
    vmk0_vcsa=@{
        Name="vmk0 --> VCSA" #-- name test, used in displaying result
        Enabled=$true #-- [boolean] run this test if $true
        test=@{ #-- vmkping attributes, to list all attributes run $esxcli.network.diag.ping.createargs()
            host='192.168.1.1' #-- [string] target host
            df = $true #-- [boolean] do not fragment, prevents breaking up of ICMP ping frame by network devices.
            netstack = 'defaultTcpipStack' #-- ESXi networkstack used
            size= 1500 #-- [bytes] framesize including TCP/IP header, the 28 bytes TCP/IP header is later being subtracted by the script.
            ipv4=$true #-- [boolean] ICMP IP version
            interface='vmk0' #-- [string] ESXi kernel port to send ICMP packets from
            }
    }
}
