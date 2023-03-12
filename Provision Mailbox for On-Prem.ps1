#Original Authors: Jordan Bardwell, Colt Coan

[CmdletBinding()]
Param(
[Parameter(Mandatory=$true)]
[string]$UserPrincipalName,
[Parameter(Mandatory=$true)]
[string]$SamAccountName,
[Parameter(Mandatory=$true)]
[string]$Department,
[Parameter(Mandatory=$true)]
[string]$Title
)

# Initialize Variables
$JSON = @()
$PrimaryDomainController = "DOMAIN"

# Test Variables for Empty Ones
if($UserPrincipalName -and $SamAccountName -and $Department -and $Title)
{
    
}
else{
    $JSON += @{
        Status = "Failed"
        Step = "Check Variables"
        Provisioned = $true
        Reason = "Department or Title Missing"
        ChangedUPN = $false
        UserPrincipalName = $UserPrincipalName
    }
    $JSON = $JSON | ConvertTo-JSON
    Write-Output $JSON
    EXIT
}

# Get Credentials
$credObject = Get-AutomationPSCredential -Name "svc_account"


    try 
    {
        # Connect to Exchange OnPrem (Yuck)
        $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://exchangeserver.domain.com -Authentication Kerberos -Credential $credObject
        Import-Module (Import-PSSession $Session -DisableNameChecking) -Global 

        #Mailbox Variables
        $AccountName = $UserPrincipalName.Split("@")[0]
        $RoutingAddress = '@domain.mail.onmicrosoft.com'
        $RemoteRoutingAddress = $AccountName+$RoutingAddress

        # Check Mailbox Existence by RemoteRoutingAddress
        $Mailbox = Get-RemoteMailbox $RemoteRoutingAddress

        # Provision
        if($Mailbox -eq $null)
        {
            # Configure Exchange Mailbox
            try {
                Enable-RemoteMailbox $UserPrincipalName -RemoteRoutingAddress $RemoteRoutingAddress -ErrorAction Stop | Out-Null
                Update-Recipient $UserPrincipalName
                $JSON += @{
                    Status = "Success"
                    Step = "Provision Mailbox"
                    Provisioned = $true
                    Reason = "Provisioned"
                    ChangedUPN = $false
                    UserPrincipalName = $UserPrincipalName
                }
                $JSON = $JSON | ConvertTo-JSON
                Write-Output $JSON
                exit
                
            }
            catch {
                $JSON += @{
                    Status = "Failed"
                    Step = "Provision Mailbox"
                    Provisioned = $false
                    Reason = $_.Exception.Message
                    ChangedUPN = $false
                    UserPrincipalName = $UserPrincipalName
                }
                $JSON = $JSON | ConvertTo-JSON
                Write-Output $JSON
                exit
            }
        }
        elseif($Mailbox.UserPrincipalName -eq $UserPrincipalName)
        {
            $Mailbox | Update-Recipient
            $JSON += @{
                Status = "Success"
                Step = "Provision Mailbox"
                Provisioned = $false
                Reason = "OnPremMailboxExists"
                ChangedUPN = $false
                UserPrincipalName = $UserPrincipalName
            }
            $JSON = $JSON | ConvertTo-JSON
            Write-Output $JSON
            exit
        }
        else
        {
            # Change UPN
            $AccountName = $UserPrincipalName.Split("@")[0]
            $Length = $AccountName.Length
            $UPNSuffix = $UserPrincipalName.Split("@")[1]
            $UPNChanged = $false
            $UPNNumber = 2
            while($UPNChanged -eq $false)
            {
                $NewAccountName = $AccountName.Insert($Length,$UPNNumber)
                $NewUserPrincipalName = $NewAccountName+"@"+$UPNSuffix
                $User = Get-ADUser -Filter * -Server $PrimaryDomainController -Credential $credObject | ?{$_.UserPrincipalName -eq $NewUserPrincipalName}
                if($User -eq $null)
                {
                    try{
                        Set-ADUser -Identity $SamAccountName -UserPrincipalName $NewUserPrincipalName -Server $PrimaryDomainController -Credential $credObject -ErrorAction Stop
                        $UPNChanged = $true
                    }
                    catch{
                        $JSON += @{
                            Status = "Failed"
                            Provisioned = $false
                            Step = "Change User Principal Name"
                            Reason = $_.Exception.Message
                            ChangedUPN = $false
                            UserPrincipalName = $UserPrincipalName
                        }
                        $JSON = $JSON | ConvertTo-JSON
                        Write-Output $JSON
                        exit
                    }
                    
                }
                else{
                    $UPNNumber++
                }
            }

            # Configure Exchange Mailbox
            try {
                #Mailbox Variables
                $NewRoutingAddress = '@edomain.mail.onmicrosoft.com'
                $NewRemoteRoutingAddress = $NewAccountName+$NewRoutingAddress
                Start-Sleep -Seconds 30
                Enable-RemoteMailbox $NewUserPrincipalName -RemoteRoutingAddress $NewRemoteRoutingAddress -ErrorAction Stop | Out-Null
                Update-Recipient $NewUserPrincipalName
                # Add to License Group
                $JSON += @{
                    Status = "Success"
                    Step = "Provision Mailbox After UPN Change"
                    Provisioned = $true
                    Reason = "Provisioned"
                    ChangedUPN = $true
                    UserPrincipalName = $NewUserPrincipalName
                }
                $JSON = $JSON | ConvertTo-JSON
                Write-Output $JSON
                exit
                
            }
            catch {
                $JSON += @{
                    Status = "Failed"
                    Step = "Provision Mailbox After UPN Change"
                    Provisioned = $false
                    Reason = $_.Exception.Message
                    ChangedUPN = $true
                    UserPrincipalName = $NewUserPrincipalName
                }
                $JSON = $JSON | ConvertTo-JSON
                Write-Output $JSON
                exit
            }
        }
        
    }
    catch 
    {
        $JSON += @{
            Status = "Failed"
            Step = "Connect to Exchange"
            Provisioned = $false
            Reason = $_.Exception.Message
            ChangedUPN = $false
            UserPrincipalName = $UserPrincipalName
        }
        $JSON = $JSON | ConvertTo-JSON
        Write-Output $JSON
        exit
    }
