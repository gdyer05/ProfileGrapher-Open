[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    2. Sign-in Status and Recent Activity (Get-MgAuditLogSignIn)
    Retrieve: 
    status.errorCode, status.failureReason, conditionalAccessStatus, ipAddress, 
    location.countryOrRegion, clientAppUsed, authenticationRequirement, authenticationMethodsUsed, 
    riskDetail, appliedConditionalAccessPolicies.

    3. Conditional Access Insights
    From the same sign-in logs, collect:
    conditionalAccessPolicies.displayName,conditionalAccessPolicies.result, 
    conditionalAccessStatus (success, failure, notApplied)
#>

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 15)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Sign-In Activity"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 40)
$treeView.Size = [System.Drawing.Size]::new(380, 190)

$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 99))     # Unknown
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 100))    # Bad
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 101))    # Good
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 102))    # Warn
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 170))    # Internet
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 273))    # Calendar

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "signInLog" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    #$baseForm.Controls.Remove($StoredComponents["accountDetails"]["spinner"])
    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "signInLog" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($searchName)
        Get-MgBetaAuditLogSignIn -Top 25  -Filter "userPrincipalName eq '$($searchName)'"
    } -ArgumentList $user.userPrincipalName

    Register-JobCompletion -Job $job -JobCb {
        param($user, $auditLog)

        $baseForm = (Get-Component -relationName "signInLog" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "signInLog" -variableName "spinner"))
        if ($null -ne $auditLog) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "signInLog" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            # Get All of the Audit Log Stuff
            foreach ($log in $auditLog) {
                $evNode = [System.Windows.Forms.TreeNode]::new($log.AppDisplayName, ($log.Status.ErrorCode -eq 0 ? 2 : 1), ($log.Status.ErrorCode -eq 0 ? 2 : 1))
                $treeView.Nodes.Add($evNode)

                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Date: $($log.CreatedDateTime)", 5, 5))

                # Risk
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Risk: $($log.RiskDetail)", ($log.RiskDetail -eq "none" ? 2 : 3), ($log.RiskDetail -eq "none" ? 2 : 3)))

                # Status Information

                $statusNode = [System.Windows.Forms.TreeNode]::new("Status Information", ($log.Status.ErrorCode -eq 0 ? 2 : 1), ($log.Status.ErrorCode -eq 0 ? 2 : 1))
                $evNode.Nodes.Add($statusNode)

                $statusNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Code: $($log.Status.ErrorCode)", 99, 99))
                $statusNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Reason: $($log.Status.FailureReason)", 99, 99))
                $statusNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($log.Status.AdditionalDetails, 99, 99))

                # Conditional Access

                $condNode = [System.Windows.Forms.TreeNode]::new("Conditional Access", 99, 99)
                $evNode.Nodes.Add($condNode)
            
                $condNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Status: $($log.ConditionalAccessStatus)", 99, 99))

                # Authentication

                $authNode = [System.Windows.Forms.TreeNode]::new("Authentication", 0, 0)
                $evNode.Nodes.Add($authNode)

                $authNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Requirement: $($log.AuthenticationRequirement)", 99, 99))
                $authNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Used: $($log.AuthenticationMethodsUsed -join ", ")", 99, 99))

                # Location
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("IP: $($log.IPAddress)", 4, 4))

                $locNode = [System.Windows.Forms.TreeNode]::new("Location", 99, 99)
                $evNode.Nodes.Add($locNode)

                $locNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Country: $($log.Location.CountryOrRegion)", 99, 99))
                $locNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("State: $($log.Location.State)", 99, 99))
                $locNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("City: $($log.Location.City)", 99, 99))

                # Client App Used
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Client: $($log.ClientAppUsed)", 99, 99))
            }

            $treeView.EndUpdate()

            foreach ($item in  ([System.Windows.Forms.DataGridView](Get-Component -relationName "accountDetails" -variableName "thisGrid")).DataSource) {
                if ($item.Name -eq "Last Sign-In") {
                    $item.Value = $auditLog[0].CreatedDateTime
                    break
                }
            }
            ([System.Windows.Forms.DataGridView](Get-Component -relationName "accountDetails" -variableName "thisGrid")).Refresh()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "signInLog" -variableName "baseForm")

    (Get-Component -relationName "signInLog" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "signInLog" -variableName "spinner"))
    (Get-Component -relationName "signInLog" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "signInLog" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "signInLog" -variableName "baseForm" -valueOfVar $baseForm