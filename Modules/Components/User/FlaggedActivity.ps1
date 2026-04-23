[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

#
#   Flagged Activity Stuff
#
$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 100)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Flagged Activity"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 125)
$treeView.Size = [System.Drawing.Size]::new(380, 339)

$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 138))        # Last Sign-In Time
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99))         # Info
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 101))        # Secure
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 102))        # Insecure
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 100))        # Compromised
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 77))         # Key

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "flaggedActivity" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "flaggedActivity" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($userId)
        Get-MgBetaRiskDetection -All -Filter "UserPrincipalName eq '$userId'"
    } -ArgumentList $user.userPrincipalName

    Register-JobCompletion -Job $job -JobCb {
        param($user, $riskListings)

        $baseForm = (Get-Component -relationName "flaggedActivity" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "flaggedActivity" -variableName "spinner"))

        $riskToIcon = @{
            "high"                  = 4
            "medium"                = 3
            "low"                   = 3
            "hidden"                = 1
            "none"                  = 1
            "unknownFutureValue"    = 1
        }

        $stateToIcon = @{
            "none"                  = 1
            "confirmedSafe"         = 2
            "remediated"            = 2
            "dismissed"             = 1
            "atRisk"                = 3
            "confirmedCompromised"  = 4
            "unknownFutureValue"    = 1
        }

        if ($null -ne $riskListings) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "flaggedActivity" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            # Correlation Cache (Removes Duplicates for Related Events)
            $correlCache = [System.Collections.ArrayList]::new()

            # Get All of the Audit Log Stuff
            foreach ($log in $riskListings) {
                # Correlation Caching
                if (($null -ne $log.CorrelationId) -and ($correlCache.Contains($log.CorrelationId))) {
                    continue
                } else {
                    if ($null -ne $log.CorrelationId) {
                        $correlCache.Add($log.CorrelationId)
                    }
                }

                $evNode = [System.Windows.Forms.TreeNode]::new("$($log.Activity) - $($log.RiskEventType)", $riskToIcon[$log.RiskLevel], $riskToIcon[$log.RiskLevel])
                $treeView.Nodes.Add($evNode)
                
                # State
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("State: $($log.RiskState)", $stateToIcon[$log.RiskState], $stateToIcon[$log.RiskState]))

                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Date: $($log.ActivityDateTime)", 0, 0))
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Detail: $($log.RiskDetail)", 99, 99))

                # Location
                if (($null -ne $log.Location) -and ($null -ne $log.Location.CountryOrRegion)) {
                    $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Location: $($log.Location.City), $($log.Location.State),  $($log.Location.CountryOrRegion)", 99, 99))
                }
            }

            $treeView.EndUpdate()
        } else {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "flaggedActivity" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            $evNode = [System.Windows.Forms.TreeNode]::new("No Flagged Activities.", 99, 99)
            $treeView.Nodes.Add($evNode)

            $treeView.EndUpdate()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "flaggedActivity" -variableName "baseForm")

    (Get-Component -relationName "flaggedActivity" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "flaggedActivity" -variableName "spinner"))
    (Get-Component -relationName "flaggedActivity" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "flaggedActivity" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "flaggedActivity" -variableName "baseForm" -valueOfVar $baseForm