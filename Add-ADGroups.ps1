Param(
    [Parameter(Mandatory=$true)]
    [String]$EmployeeID,
    [Parameter(Mandatory=$true)]
    [String]$Groups,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Domain1","Domain2","Domain3")]
    [String]$Domain
)

# Domain Controller
$Server = "domain"

# Get Credentials
$credObject = Get-AutomationPSCredential -Name "svc_account"

# Domain Controllers
$1DomainController = "Domain1"
$2DomainController = "Domain2"
$3DomainController = "Domain3"

# Confirm Domain Controller to Use
if($Domain -eq "Domain1")
{
    $DomainController = $1DomainController
}
elseif($Domain -eq "Domain2")
{
    $DomainController = $2DomainController
}
elseif($Domain -eq "Domain3")
{
    $DomainController = $3DomainController
}
else{}

# Convert Groups to List
$Groups2 = $Groups
$Groups2 = $Groups2.Trim()
$Groups2 = $Groups2.Split(',')

# Find User
$User = Get-ADUser -Filter "(EmployeeID -eq '$EmployeeID')" -Credential $CredObject -Server $DomainController
if($User)
{}
else {
    Write-Output "USERNOTFOUND"
    exit
}

# Create Arrays
$Success = @()
$Failed = @()

# ForEach Statement - Add Group(s) to account
ForEach($Group in $Groups2)
{
    try{
        $User | Add-ADPrincipalGroupMembership -MemberOf $Group -Credential $CredObject -ErrorAction Stop
        $Success += @{
            GroupName = $Group
        }
    }
    catch{
        $Failed += @{
            GroupName = $Group
            Error = $_
        }
    }
}

# Output Results
$JSON = @{
    Success = $Success
    Failed = $Failed
}
$JSON = $JSON | ConvertTo-JSON
Write-Output $JSON