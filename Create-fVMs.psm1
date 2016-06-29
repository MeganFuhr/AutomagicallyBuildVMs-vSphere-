<#
.SYNOPSIS
    
    Creates one one or many virtual machines in a vSphere cluster
 
.DESCRIPTION
    This script will create one or more virtual machines in vSphere
    
 
.PARAMETER VC
 
    Mandatory parameter indicating vCenter server to connect to (FQDN or IP address)

.PARAMETER Cluster
    
    Dynamically pulls clusters from target vCenter Server and creates a validation set.  Use tab complete to navigate through clusters at command line or in ISE.

.PARAMETER Datastore

    Dynamically pulls datastores from target vCenter Server and creates a validation set.  Use tab complete to navigate through datastores at command line or in ISE.

.PARAMETER Template

    Dynamically pulls templates from target vCenter Server and creates a validation set.  Use tab complete to navigate through templates at command line or in ISE.
  
    
.EXAMPLE
 
    Create-FVMs -VC 192.168.1.2 -VMName VM1, VM2, VM3 -Template TabTemplate -Cluster TabCluster -Datastore -TabDatastore
    
    
.EXAMPLE
 
     Create-FVMs -VC MyvCenter.FQDN.local -VMName VM1 -Template TabTemplate -Cluster TabCluster -Datastore -TabDatastore

.NOTES

    Author: Megan Fuhr @Megan_Fuhr
    Date: June 22, 2016

    Resource:
            ---- https://blogs.technet.microsoft.com/heyscriptingguy/2014/03/21/use-dynamic-parameters-to-populate-list-of-printer-names/ ----
            ---- http://www.adamtheautomator.com/psbloggingweek-dynamic-parameters-and-parameter-validation/ ----

.LINK
    http://MeAbstracted.com
    
    
#>

Function Create-fVMS {

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [ValidateScript({
            If (!(Test-Connection -ComputerName $_ -quiet -count 1))
                { 
                    throw "The vCenter Server [$_] is unreachable. Please confirm the IP address or name."
                }
            Else
                {
                $true
                }
           })]        
        [string]$VC,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$VMName
        )
     
     DynamicParam{
        #Create a parameter attribute object.  This will be reused and applied to all dynamic parameters required
        $Attribute = New-Object System.Management.Automation.ParameterAttribute
        $Attribute.ParameterSetName = "_AllParameterSets"
        $Attribute.Mandatory = $true




        #Create a parameter and update its attribute.
        #This variable will hold all available clusters.
        $ClustersCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $ClustersCollection.Add($Attribute)

        #Get the values to be validated against.
        $_Values = (Get-Cluster -Server $VC).Name
        #Create another parameter attribute and include the validation set.
        $ValidateSet = New-Object System.Management.Automation.ValidateSetAttribute($_Values)

        #Add the validation set
        $ClustersCollection.Add($ValidateSet)

        #Create the run time parameter.
        #This runtime parameter is called "Cluster." Add the validation set.
        $dynParam1 = new-object -Type System.Management.Automation.RuntimeDefinedParameter("Cluster", [string], $ClustersCollection)

        #Create a runtime defined parameter dictionary.  This will be reused for every runtime parameter used
        $paramDictionary = new-object -Type System.Management.Automation.RuntimeDefinedParameterDictionary

        #Add the Cluster parameter to the runtime parameter dictionary.
        $paramDictionary.Add("Cluster", $dynParam1)

               
        
        #Create a parameter and update it's attributes.  The attributes are defined at the beginning of DynamicParam
        $TemplatesCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $TemplatesCollection.Add($Attribute)

        #Get the values to be validate against.
        $_Values2 = (Get-Template -Server $VC).Name
        #Create another parameter attribute and include the validation set
        $validateSet2 = New-Object System.Management.Automation.ValidateSetAttribute($_Values2)

        #Add the validation set
        $TemplatesCollection.Add($validateSet2)

        #This runtime parameter will be called "Template."  Add the validation set.
        $dynParam2 = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter("Template",[string], $TemplatesCollection)

        #Add the Template parameter to the runtime parameter dictionary
        $paramDictionary.Add("Template", $dynParam2)




        #Create a parameter and update it's attributes.  The attributes are defined at the beginning of DynamicParam
        $DatastoresCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
        $DatastoresCollection.Add($Attribute)

        #Get the values to be validate against.
        $_Values3 = (Get-Datastore -Server $VC).Name
        #Create another parameter attribute and include the validation set
        $validateSet3 = New-Object System.Management.Automation.ValidateSetAttribute($_Values3)

        #Add the validation set
        $DatastoresCollection.Add($validateSet3)

        #This runtime parameter will be called "Template."  Add the validation set.
        $dynParam3 = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter("Datastore",[string], $DatastoresCollection)

        #Add the Template parameter to the runtime parameter dictionary
        $paramDictionary.Add("Datastore", $dynParam3)
        
        return $paramDictionary 
        } #End DynamicParam

          #Run once, connect to vSphere.  This will prompt for credentials.
          #Begin {
          # try {
	      #      Add-PSSnapin VMware.* -ErrorAction SilentlyContinue	
	      #     Connect-VIServer -Server $VC
          #      }
          #  catch {return}
          #  }

          Process {
            $Cluster = $PSBoundParameters.Cluster
            $Template = $PSBoundParameters.Template
            $Datastore = $PSBoundParameters.Datastore

                foreach ($vm in $VMName) {
                New-VM -ResourcePool $cluster -Name $VM -Template $template -datastore $datastore -verbose
                } #End Process block
             } 
        
     } #End Function Create-fVMs