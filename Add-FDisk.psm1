<#

.SYNOPSIS
    
    This script adds ass many disks as as required via VMware vSphere.  It then connects to the Windows guest OS and formats and labels
    each drive provided by user input.

.DESCRIPTION
    
    This script adds ass many disks as as required via VMware vSphere. 
    The first entry of each parameter is paired.  For instance, the Label Log, Letter L, and size of 20 GB will be paired.
    Add-FDisks -NumberofDisk 3 -Labels Log, Backup, Data -Letters L, B, D -size 20,40,60 -VMName VMwareVM

.PARAMETER NumberofDisks
    
    This paremeter is an [int] and determines the number of disks to be added.

.PARAMETER Labels
    
    This parameter is a [string].  It is used to label the drives after they have been formatted.

.PARAMETER Size
    
    This parameter is a [string] and determines the size of each disk added.

.PARAMETER Letters
    
    This parameter is a [string] and determines the letter to apply to the drive.  It will accept any letter that is not "C."

.PARAMETER VMName
    
    This parameter is a [string] and is the name of the machine as it appears in vSphere (not the guest OS).

.EXAMPLE
    
    Add-FDisks -NumberofDisk 3 -Labels Log, Backup, Data -Letters L, B, D -size 20,40,20 -VMName VMwareVM
    Add-FDisks -NumberofDisk 2 -Labels Apps, Data -Letters A, D -size 100,200 -VMName VMwareVM

.NOTES
    
    Author: Megan Fuhr @Megan_Fuhr
    Date: June 22, 2016

.LINK
    http://MeAbstracted.com

#>

function Add-FDisks 
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [int]$numberOfDisks = 1,
        
        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [string[]]$labels,

        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [string[]]$sizes,

        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        [ValidatePattern('[a-bd-z]')] #Any single character that is not C
        [string[]]$letters,     

        [Parameter(Mandatory=$true,ValueFromPipeLine=$true)]
        $VMName
       
    )
#Create Counter
[int]$i = 0

#create properties for the $diskInput object
$properties = 
    @{
    'Size'=$properties.size;
    'Letter'=$properties.letter;
    'Label'=$properties.label
    }
  
#Create the diskInput object and the properties to it
$diskInput = @()

#Create custom object containing all the disks to be added as well as letters, size, and label.   
    while ($i -lt $numberOfDisks)
    {
      $test = New-Object -typename PSOBject -Property $properties

      $test.letter = $letters[$i]
      $test.size = $sizes[$i]
      $test.label = $labels[$i]

      $diskinput += $test
      $i++   
    }

#Get the virtual machine in VMware
#$VM = Get-VM -Name $VMName.VMname

#Get the self signed certificate that was created on the target device template
#$cert = Get-ChildItem -Path Cert:\LocalMachine\My\1F3893E8DCBC8A1DBC8D06D5C4E4B4EB712E0EC2

#Get the credentials of the target machine.
#$cred = Get-Credential -Message "Enter in a local administrator account and password for the target device."

#Create a CIM Session option that sets the use of SSL    
#$option = New-CimSessionOption -UseSSL

#Create the CIM Session
$CIMSession = New-CimSession -ComputerName $VMName.vmname -Authentication Kerberos -Credential $DomainCred

#For each disk created in $diskinput, create a drive, assign a letter and label, and format in NTFS.
foreach ($disk in $diskInput)
    {
        New-HardDisk -VM $VMName.vmname -CapacityGB $disk.size -Persistence Persistent 

        #Get disk list each time to find the last one added by filtering only RAW type.
        $DiskList = Get-Disk -cimsession $CIMSession | where {$_.PartitionStyle -eq "RAW"}

            #Initialize, create partition, and format in NTFS.
            foreach ($drive in $disklist)
            {
                    #Initialize disk by drive number
                    Initialize-Disk -Number $drive.Number -CimSession $CIMSession
                    #Assign a drive letter and set partition size by drive number
                    New-Partition -DiskNumber $drive.Number -DriveLetter $disk.letter -UseMaximumSize -CimSession $CIMSession
                    #Format the volume as NTFS by disk letter and label it
                    Format-Volume -DriveLetter $disk.letter -FileSystem NTFS -newFileSystemLabel $disk.label -CimSession $CIMSession -force -Confirm:$False
             
            }
        #Clear variable
        $disklist = @()       
    }
}