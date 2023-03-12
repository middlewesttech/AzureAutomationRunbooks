Param(
    [Parameter(Mandatory=$true)]
    [String]$EmployeeID,
    [Parameter(Mandatory=$true)]
    [String]$Title,
    [Parameter(Mandatory=$true)]
    [String]$Department

)

# Get Credentials from Azure
$credObject = Get-AutomationPSCredential -Name "svc_account" 

# Domain Controller
$PrimaryDomainController = "Domain"

# License Groups
$E5 = "ADGroupOnPremE5"
$E3 = "ADGroupOnPremE3"
$F3 = "ADGroupOnPremF3"

# Get User by Employee ID
try{
    $User = Get-ADUser -Filter "(EmployeeID -eq '$EmployeeID')" -Properties * -Credential $CredObject -Server $PrimaryDomainController -ErrorAction Stop
    if($User.MemberOf -like "*UG-o365*")
    {
        Write-Output "ALREADYLICENSED"
        EXIT
    }

    # Check For Restricted Titles and Departments
    if($Title -like "*Sales*" -and $Department -eq "Sales")
    {
        # Assign Full License
        Add-ADGroupMember -Identity $Full -Members $User -Confirm:$False -Credential $credObject -Server $PrimaryDomainController -ErrorAction Stop
        Write-Output "Success"
    }
    elseif ($Department -eq "Finance")
    {
        if($Title -like "*Manager*" -or $Title -like "*President*" -or $Title -like "*Director*")
        {
            # Assign Full License
            Add-ADGroupMember -Identity $Full -Members $User -Confirm:$False -Credential $credObject -Server $PrimaryDomainController -ErrorAction Stop
            Write-Output "Success"
        }
        else
        {
            # Assign F3 License
            Add-ADGroupMember -Identity $F3 -Members $User -Confirm:$False -Credential $credObject -Server $PrimaryDomainController -ErrorAction Stop
            Write-Output "Success"
        }
    }
    elseif ($Department -eq "Call Center")
    {
        # Assign Call Center License
        Add-ADGroupMember -Identity $CallCenter -Members $User -Confirm:$False -Credential $credObject -Server $PrimaryDomainController -ErrorAction Stop
        Write-Output "Success"
    }
    elseif ($Department -ne "Call Center") {

        # Assign Full License
        Add-ADGroupMember -Identity $Full -Members $User -Confirm:$False -Credential $credObject -Server $PrimaryDomainController -ErrorAction Stop
        Write-Output "Success"
    }
    else{
        Write-Output "No Matches for Licensing"
    }
}
catch{
    Write-Output "Failed"
    Write-Output $_
    Exit
}





