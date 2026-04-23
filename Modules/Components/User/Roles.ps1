[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    8. Role and Group Membership (Get-MgUserMemberOf

    Retrieve: security groups, admin roles, CA exclusions.
#>

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 15)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Assigned Roles and Groups"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 40)
$treeView.Size = [System.Drawing.Size]::new(380, 424)

$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 74))     # Role/Group
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 273))    # Calendar
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 73))     # Admin Icon
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 76))         # Info

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "roles" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "roles" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($userId)
        Get-MgBetaUserMemberOf -UserId $userId
    } -ArgumentList $user.Id

    Register-JobCompletion -Job $job -JobCb {
        param($user, $roles)

        $baseForm = (Get-Component -relationName "roles" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "roles" -variableName "spinner"))

        if ($null -ne $roles) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "roles" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            # Get All of the Audit Log Stuff
            foreach ($role in $roles) {
                $newNode = [System.Windows.Forms.TreeNode]::new($role["displayName"],0,0)

                if ($role["@odata.type"] -eq "#microsoft.graph.directoryRole") {
                    $newNode = [System.Windows.Forms.TreeNode]::new($role["displayName"] ? $role["displayName"] : "[Directory Role]",2,2)
                    #Write-Host ($role.AdditionalProperties)
                    #Write-Host ($role.Id)
                }

                $treeView.Nodes.Add($newNode)

                if ($role["description"] -ne $null) {
                    $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($role["description"], 3, 3))
                }
                if ($role["createdDateTime"] -ne $null) {
                    $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($role["createdDateTime"], 1, 1))
                }
            }

            $treeView.EndUpdate()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "roles" -variableName "baseForm")

    (Get-Component -relationName "roles" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "roles" -variableName "spinner"))
    (Get-Component -relationName "roles" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "roles" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "roles" -variableName "baseForm" -valueOfVar $baseForm