[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

#
#   Mini-Header
#
$statusPicture = [System.Windows.Forms.PictureBox]::new()                    # Create a Picture Box
$statusPicture.Location = [System.Drawing.Point]::new(15, 25)              # LOcation of the Picture box on the Winform
$statusPicture.Size = [System.Drawing.Size]::new(50, 50)                   # Size of the Picture box on the Winform
$statusPicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom      # The image content will be scaled to fit in the PictureBox's size
$statusPicture.Image = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99 -LargeIcon)
$baseForm.Controls.Add($statusPicture)

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(75, 20)
$header.Size = [System.Drawing.Size]::new(300, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Account is Not Compromised"

$lastUpdated = [System.Windows.Forms.Label]::new()
$lastUpdated.Location = [System.Drawing.Point]::new(75, 42)
$lastUpdated.Size = [System.Drawing.Size]::new(350, 22)
$lastUpdated.Text = "Last Updated: Date"

$rawStatus = [System.Windows.Forms.Label]::new()
$rawStatus.Location = [System.Drawing.Point]::new(75, 60)
$rawStatus.Size = [System.Drawing.Size]::new(350, 22)
$rawStatus.Text = "Status"

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($lastUpdated)
$baseForm.Controls.Add($rawStatus)

Register-Component -relationName "riskOverview" -variableName "statusHeader" -valueOfVar $header
Register-Component -relationName "riskOverview" -variableName "statusPicture" -valueOfVar $statusPicture
Register-Component -relationName "riskOverview" -variableName "lastUpdated" -valueOfVar $lastUpdated
Register-Component -relationName "riskOverview" -variableName "rawStatus" -valueOfVar $rawStatus

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    $job = Start-ThreadJob -ScriptBlock {
        param($userId)
        (Get-MgBetaRiskyUser -Top 1 -Filter "UserPrincipalName eq '$userId'")
    } -ArgumentList $user.userPrincipalName

    Register-JobCompletion -Job $job -JobCb {
        param($user, $riskLog)

        (Get-Component -relationName "riskOverview" -variableName "baseForm").Controls.Remove((Get-Component -relationName "riskOverview" -variableName "spinner"))
        (Get-Component -relationName "riskOverview" -variableName "baseForm").Controls.Add((Get-Component -relationName "riskOverview" -variableName "statusPicture"))

        $riskToIcon = @{
            "high"               = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 100 -LargeIcon)
            "medium"             = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 102 -LargeIcon)
            "low"                = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 102 -LargeIcon)
            "hidden"             = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99 -LargeIcon)
            "none"               = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 101 -LargeIcon)
            "unknownFutureValue" = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99 -LargeIcon)
        }
        $riskToStatus = @{
            "high"               = "Account is Compromised or Risky"
            "medium"             = "Account is Possibly Compromised"
            "low"                = "Account May Be At Risk"
            "hidden"             = "Account Status Hidden"
            "none"               = "Account is Not Compromised"
            "unknownFutureValue" = "Account Status Unknown"
        }

        (Get-Component -relationName "riskOverview" -variableName "lastUpdated").Text = "Last Updated: $(Get-Date)"
        (Get-Component -relationName "riskOverview" -variableName "rawStatus").Text = "N/A"

        if (($null -eq $riskLog) -or ($riskLog.RiskLevel -eq "none")) {
            # No Risk Fallback
            (Get-Component -relationName "riskOverview" -variableName "statusPicture").Image = $riskToIcon["none"]
            (Get-Component -relationName "riskOverview" -variableName "statusHeader").Text = $riskToStatus["none"]
            if ($null -eq $riskLog) {
                (Get-Component -relationName "riskOverview" -variableName "statusHeader").Text = $riskToStatus["none"]
                (Get-Component -relationName "riskOverview" -variableName "statusHeader").Text = $riskToStatus["none"]
                return
            }
        }
        else {
            (Get-Component -relationName "riskOverview" -variableName "statusPicture").Image = $riskToIcon[$riskLog.RiskLevel]
            (Get-Component -relationName "riskOverview" -variableName "statusHeader").Text = $riskToStatus[$riskLog.RiskLevel]
        }
        
        # DateTime
        (Get-Component -relationName "riskOverview" -variableName "lastUpdated").Text = "Last Updated: $($riskLog.RiskLastUpdatedDateTime)"
        (Get-Component -relationName "riskOverview" -variableName "rawStatus").Text = "$($riskLog.RiskState) - $($riskLog.RiskDetail)"
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "riskOverview" -variableName "baseForm")

    (Get-Component -relationName "riskOverview" -variableName "statusPicture").Image = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99 -LargeIcon)
    (Get-Component -relationName "riskOverview" -variableName "statusHeader").Text = "..."

    $baseForm.Controls.Add((Get-Component -relationName "riskOverview" -variableName "spinner"))
    $baseForm.Controls.Remove((Get-Component -relationName "riskOverview" -variableName "statusPicture"))
    (Get-Component -relationName "riskOverview" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $statusPicture
Register-Component -relationName "riskOverview" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "riskOverview" -variableName "baseForm" -valueOfVar $baseForm