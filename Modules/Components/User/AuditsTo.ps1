[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 15)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Audits Targeting Account"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 40)
$treeView.Size = [System.Drawing.Size]::new(380, 190)

$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 94))     # Unknown                   0
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 246))    # DELETE                    1
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 290))    # CREATE                    2
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 279))    # UPDATE                    3
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 179))    # Category                  4
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 273))    # Calendar                  5
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 233))    # Success                   6
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 230))    # Failure                   7
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 227))    # Target Resources          8
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 209))    # User                      9
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 124))    # Role                      10
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 77))     # ID                        11
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 15))     # Email                     12

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "auditsTo" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    #$baseForm.Controls.Remove($StoredComponents["accountDetails"]["spinner"])
    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "auditsTo" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($searchName)
        Get-MgBetaAuditLogDirectoryAudit -All -Filter "targetResources/any(tr:tr/userPrincipalName eq '$searchName')"
    } -ArgumentList $user.userPrincipalName

    Register-JobCompletion -Job $job -JobCb {
        param($user, $auditLog)

        $baseForm = (Get-Component -relationName "auditsTo" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "auditsTo" -variableName "spinner"))

        $operationToIcon = @{
            "create"             = 2
            "update"             = 3
            "delete"             = 1
            "stageddelete"       = 1
            "disable"            = 7
            "other"              = 0
            "unknownFutureValue" = 0
        }

        if ($null -ne $auditLog) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "auditsTo" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            # Get All of the Audit Log Stuff
            foreach ($log in $auditLog) {
                $evNode = [System.Windows.Forms.TreeNode]::new($log.ActivityDisplayName, $operationToIcon[$log.OperationType], $operationToIcon[$log.OperationType])
                $treeView.Nodes.Add($evNode)

                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Date: $($log.ActivityDateTime)", 5, 5))

                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Category: $($log.Category)", 4, 4))
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Operation: $($log.OperationType)", $operationToIcon[$log.OperationType], $operationToIcon[$log.OperationType]))
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Result: $($log.Result)", ($log.Result -eq "success" ? 6 : 7), ($log.Result -eq "success" ? 6 : 7)))

                $targetResources = [System.Windows.Forms.TreeNode]::new("Target Resources", 8, 8)
                $evNode.Nodes.Add($targetResources)

                foreach ($res in $log.TargetResources) {
                    if ($res.Type -eq "Role") {
                        $roleNode = [System.Windows.Forms.TreeNode]::new("Role: $($res.DisplayName)", 10, 10)
                        $targetResources.Nodes.Add($roleNode)

                        $roleNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($res.Id)", 11, 11))
                    }
                    if ($res.Type -eq "User") {
                        $roleNode = [System.Windows.Forms.TreeNode]::new("User: $($res.DisplayName)", 9, 9)
                        $targetResources.Nodes.Add($roleNode)

                        $roleNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($res.userPrincipalName)", 12, 12))
                        $roleNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($res.Id)", 11, 11))
                    }
                }

                if ($log.InitiatedBy.User.userPrincipalName -ne $null) {
                    $initBy = [System.Windows.Forms.TreeNode]::new("Initiator", 9, 9)
                    $evNode.Nodes.Add($initBy)

                    $initBy.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($log.InitiatedBy.User.DisplayName)", 9, 9))
                    $initBy.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($log.InitiatedBy.User.UserPrincipalName)", 12, 12))
                    $initBy.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($log.InitiatedBy.User.Id)", 11, 11))
                }
            }

            $treeView.EndUpdate()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "auditsTo" -variableName "baseForm")

    (Get-Component -relationName "auditsTo" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "auditsTo" -variableName "spinner"))
    (Get-Component -relationName "auditsTo" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "auditsTo" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "auditsTo" -variableName "baseForm" -valueOfVar $baseForm