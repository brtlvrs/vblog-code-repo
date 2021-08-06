# Brtlvrs vmkping multi test script

|version| 0.0.1 | [MIT license](LICENSE)|Copyright (c) 2021 Bart Lievers|[blog](https://vblog.bartlievers.nl)|[github](https://github.com/brtlvrs/)|[dockerhub](https://hub.docker.com/u/brtlvrs)|
|---|---|---|---|---|---|---|

This script enables a multi vmkping execution from the selected vSphere hosts.   
By looping through a nested hashtable with predefined vmkping tests

# Test definitions

Test definitions are set in the vmkpingTestDef.ps1 containing a hashtable format.
Each hashtable row is a specific vmkping test containing metadata and a hashtable with the vmkping properties. 


## vmkping properties

|property| type| omschrijving
|---|---|---
|host|string|(optional) IPv4 of FQDN adres to use as target
|wait|string|(optional) [ms]
|df|boolean|(optional) 'do not fragment', prefents fragmentation of ICMP frame      
|interval|string|(optional) [ms] interval time between ICMP pings
|ttl|long|(optional) [ms] 'time to live'
|debug|boolean|(optional)                                                                    
|nexthop|string|(optional)
|count|long|(optional) number of pings to send
|netstack|string|(optional) TCP/IP networkstack to use
|size|long|(optional) [byte] Size of ICMP frame including TCP/IP header of 28 bytes.
|ipv4|[boolean|(optional) IPv4 ping
|ipv6|[boolean|(optional) IPv6 ping
|interface|string|(optional)  ESXi kernel naam
