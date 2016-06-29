<#
    
Copyright © 2015 Citrix Systems, Inc. All rights reserved.

.SYNOPSIS

    Join the specified domain

.DESCRIPTION

.PARAMETER Domain
    
    This is the domain in which the computer will be joined.

.PARAMETER DomainCred

    These are the credentials that will be used to join the computer to the domain.

.NOTES

    This is a modified version from Citrix Lifecycle Management.

#>

function Join-FDomain {
    [CmdletBinding()]
    Param (
        $Domain,
        $DomainCred,
        $VMName,
        $OUPath,
        [int]$retries = 3
    )
    $ex = ""



    for ($i=0; $i -lt $retries; $i++) 
    {
        foreach ($VM in $VMName) 
        {
            try {
                    $result = Add-Computer -DomainName $Domain -OUPath $OUPath -ComputerName $VM.IP -Credential $DomainCred -NewName $VM.VMName -WarningAction SilentlyContinue -PassThru
                    if ($result.HasSucceeded) 
                    {
                        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False                        
                        Restart-Computer -ComputerName $VM.IP -Force -Confirm:$false
                        return $result.ComputerName

                    }
                }    catch 
                    {
                        $ex = $_
                        Start-Sleep -Seconds 10
                    }
                }
            }
    throw "Domain join failed: $ex"
}
   
