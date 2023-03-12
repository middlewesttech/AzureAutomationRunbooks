$credObject = Get-AutomationPSCredential -Name "svc_account"

Connect-Msolservice -Credential $credObject

try {
    $CurrentTime = [System.DateTime]::UtcNow
    $TenantInfo = Get-MsolCompanyInformation -ErrorAction Stop
    $LastSynctime = $TenantInfo.LastDirSyncTime
    $NewSyncTime = $LastSynctime.AddMinutes(30)
    $WaitTime = ($NewSyncTime - $CurrentTime).TotalMinutes
    $TimeToWait = ([Math]::Round($WaitTime, 0))
    $TimeToWait = $TimeToWait+12
    Write-Output $TimeToWait
}
catch {
    Write-Output "Failed"
}
