#[CmdletBinding()]
Param 
(

    $scriptPath = (Split-Path $MyInvocation.MyCommand.Path),
    $vSphereCred = (Get-Credential -Message "Enter in your credentials for the vCenter server."),
    $VC = (Read-Host -Prompt "Input your target vCenter server."),
    $VMName = ((Read-Host "Input the VM names. Seperate by comma.").split(',') | % {$_.trim()}),
    $OU = (Read-Host -Prompt "Input the name of the OU."),
    $Domain = (Read-Host -Prompt "Input the name of the domain."),
    $DomainCred = (Get-Credential -Message "Enter domain credentials."),
    $DNSServers = ((Read-Host -Prompt "Enter your DNS server(s). Sperate by a comma.").Split(',') | % {$_.Trim()})
    
)

begin 
{
    Get-ChildItem $scriptPath\Module\*.psm1 | Import-Module
    asnp VMware*
    Import-Module ActiveDirectory
    Connect-VIServer -Server $VC -Cred $vSphereCred -Verbose
 }

Process
{
    #Create the VMs from a template
    Create-fVMS -Template 2012R2_Template -Cluster NTNX-CL01 -Datastore Forthright_DS1 -VC $vc -VMName $VMName
    
    #Power on the VMs
    Start-VM $VMName

    #Sleep for 5 minutes to allow for Sysprep to finish
    Start-Sleep 300
    
    #create properties for the VMWare VMs object.  It will pair the created VM name with the IP.
    $properties = 
    @{
    'VMName'=$properties.VMName;
    'IP'=$properties.IP;
    }

    #Create object that will hold the VMware vSphere VM name and associated IP address
    $VMArray = @()
    foreach ($vm in $VMName)
    {
        $temp = New-Object -TypeName PSObject -Property $properties

        $temp.VMName = $VM
        $temp.IP = (Get-VM $VM | Select @{N="IP";E={@($_.guest.IPAddress[0])}}).IP

        $VMArray += $temp
    }
      
    #Update the DNS server.  This a pre-requesite of joining a domain.
    Write-Verbose -Message "Setting DNS Server(s)..."
    foreach ($VM in $VMArray)
    {
        Set-FDNSServer -DNSServers $DNSServers -VMName $VM
    }    

    $OU = (Get-ADOrganizationalUnit -Filter 'name -eq $OU').DistinguishedName

    #Add-Computer -ComputerName $VMArray -Credential $DomainCred -Restart -NewName $VMName -DomainName $Domain -PassThru -Confirm:$false
    Add-Computer -DomainName $Domain -OUPath $OU -ComputerName $VM.IP -Credential $DomainCred -NewName $VM.VMName -WarningAction SilentlyContinue -PassThru -Restart
    #Join-FDomain -Domain $Domain -DomainCred $DomainCred -VMName $VMArray -OuPath $OU

    #Allow 60 seconds for VMs to reboot.
    Start-Sleep 60
        
    Add-FDisks -numberOfDisks 2 -labels Apps, Data -sizes 10,10 -letters A, D -VMName $VMArray
}