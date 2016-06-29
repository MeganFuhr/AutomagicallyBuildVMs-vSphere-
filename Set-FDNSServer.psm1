<#   

Copyright © 2014-2016 Citrix Systems, Inc. All rights reserved.

.SYNOPSIS
Configure the DNS server search order (as long this is not an Azure Virtual Network).

.DESCRIPTION
This script will configure the DNS server search order for one or all of the computer's NICs

.PARAMETER DnsServers
List of DNS server IP addresses 

.PARAMETER MacAddress
Optional MAC address used to identify the NIC to configure. If not specified all 
NICs will be re-configured with the specified DNS server addresses.

.PARAMETER VnetName
Optional name of the Azure Virtual Network: if this indicator is present the script will perform no change

#>
function Set-FDNSServer {
    [CmdletBinding()]
    Param
    (
    [Parameter(Mandatory=$true)]
    [string[]]$DnsServers, 
    $VMName
    )

    foreach ($VM in $VMName)
    {
        #$IP = Get-VM $VM | Select @{N="IP"; E={@($_.guest.IPAddress[0])}} 
        $adapters = Get-WmiObject -Class Win32_NetWorkAdapterConfiguration -ComputerName $VM.IP -filter "IPEnabled=True"

        foreach ($adapter in $adapters)
        {
        $result = $adapter.SetDNSServerSearchOrder($DNSServers)
            if ($result.ReturnValue -ne 0)
            {
                Throw "Win32_NetworkAdapterConfiguration.SetDNSServerSearchOrder failed for DNS servers $DNSServers. Error code $(result.ReturnValue)"
            }
        }
    }
}