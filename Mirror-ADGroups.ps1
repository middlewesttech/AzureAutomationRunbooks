Param(
    [Parameter(Mandatory=$true)]
    [String]$NewEmployeeID,
    [Parameter(Mandatory=$true)]
    [String]$ExistingEmployeeID
)

# Get Credentials
$credObject = Get-AutomationPSCredential -Name "svc_account"

# Domain Controllers
$PrimaryDomainController = "Primary.Corecorp.com"
$SecondaryDomainController = "Secondary.CoreCORP.COM"
$ThirdDomainController = "Third.CoreCORP.COM"
$CoreDomainController = "CoreCORP.COM"

# List of Domain Controllers
$DomainControllers = @(
    $PrimaryDomainController
    $SecondaryDomainController
    $ThirdDomainController
)

# Groups
$TotalGroups = 0
$SuccessfullyAddedGroups = 0
$SuccessfullyAddedGroupsName = @()
$FailedGroups = 0
$FailedGroupsName = @()
$GroupsToAdd = @()

# ForEach Statement - Find Existing Employee
ForEach($DomainController in $DomainControllers)
{
    # Get User
    $ExistingUser = Get-ADUser -Filter "EmployeeID -eq $ExistingEmployeeID" -Properties * -Credential $credObject -Server $DomainController

    if($ExistingUser)
    {
        $Groups = $ExistingUser.MemberOf
        foreach ($Group in $Groups)
        {
            if($Group -like "*o365*")
            {
            }
            else
            {
                $GroupsToAdd += $Group
            }
        }
        $TotalGroups = $GroupsToAdd.Count
    }
    else {

    }
}

# ForEach Statement - Find New Employee
ForEach($DomainController in $DomainControllers)
{
    # Get User
    $NewUser = Get-ADUser -Filter "EmployeeID -eq $NewEmployeeID" -Properties * -Credential $credObject -Server $DomainController
    if($NewUser)
    {
        foreach($Group in $GroupsToAdd)
        {
            # Determine Domain Controller for Each Group
            if($Group.Contains("DC=Primary")) 
            {
                $ADGroup = Get-ADGroup -Identity $Group -Credential $credObject -Server $PrimaryDomainController
                $GroupDomainController = $PrimaryDomainController
            }
            elseif($Group.Contains("DC=Secondary")) 
            {
                $ADGroup = Get-ADGroup -Identity $Group -Credential $credObject -Server $SecondaryDomainController
                $GroupDomainController = $SecondaryDomainController
            }
            elseif($Group.Contains("DC=Third")) 
            {
                $ADGroup = Get-ADGroup -Identity $Group -Credential $credObject -Server $ThirdDomainController
                $GroupDomainController = $ThirdDomainController
            }
            else 
            {
                $ADGroup = Get-ADGroup -Identity $Group -Credential $credObject -Server $CoreDomainController
                $GroupDomainController = $CoreDomainController
            }
            # Add to Group
            try
            {
                Add-ADGroupMember -Identity $ADGroup -Members $NewUser -Credential $credObject -Server $GroupDomainController -ErrorAction Stop
                $SuccessfullyAddedGroups++
                $GroupName = Get-ADGroup -Identity $ADGroup -Credential $credObject -Server $GroupDomainController | Select-Object -expandproperty Samaccountname
                $SuccessfullyAddedGroupsName += $GroupName
            }
            catch
            {
                $_
                $FailedGroups++
                $GroupName = $Group.Split(',')[0].Replace('CN=','')
                $FailedGroupsName += $GroupName

            }
        }
    }
    else{

    }
    
}

# Output Results
$JSON = @{
    TotalGroups = $TotalGroups
    SuccessfullyAddedGroups = $SuccessfullyAddedGroups
    FailedGroups = $FailedGroups
    SuccessfullyAddedGroupsName = $SuccessfullyAddedGroupsName
    FailedGroupsName = $FailedGroupsName
}

$JSON = $JSON | ConvertTo-JSON
Write-Output $JSON