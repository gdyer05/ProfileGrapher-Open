[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    6. Devices and Compliance (Get-MgUserRegisteredDevice,Get-MgDevice)

    Retrieve: displayName, isManaged, isCompliant, operatingSystem, deviceId.
#>

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 15)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Registered Devices"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 40)
$treeView.Size = [System.Drawing.Size]::new(380, 424)

$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 104))        # Computer Desktop
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 29))         # OS Chip
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 138))        # Last Sign-In Time
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 76))         # Info
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 101))        # Secure
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 102))        # Insecure
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 77))         # Key

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "deviceList" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "deviceList" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($userId)
        Get-MgBetaUserRegisteredDevice -UserId $userId
    } -ArgumentList $user.Id

    Register-JobCompletion -Job $job -JobCb {
        param($user, $devices)

        $baseForm = (Get-Component -relationName "deviceList" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "deviceList" -variableName "spinner"))

        if ($null -ne $devices) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "deviceList" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
                
            # Get All of the Audit Log Stuff
            foreach ($dev in $devices) {
                $newNode = [System.Windows.Forms.TreeNode]::new($dev["displayName"],0,0)
                $treeView.Nodes.Add($newNode)

                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($dev["model"], 3, 3))
                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($dev["operatingSystem"]) $($dev["operatingSystemVersion"])", 1, 1))
                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Approx. Last Sign-In: $($dev["approximateLastSignInDateTime"])", 2, 2))
                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Is Managed: $($dev["isManaged"])", ($dev["isManaged"] -eq $true ? 4 : 5), ($dev["isManaged"] -eq $true ? 4 : 5)))
                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Is Compliant: $($dev["isCompliant"])", ($dev["isCompliant"] -eq $true ? 4 : 5), ($dev["isCompliant"] -eq $true ? 4 : 5)))
                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($dev["deviceId"], 6, 6))
            }

            $treeView.EndUpdate()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "deviceList" -variableName "baseForm")

    (Get-Component -relationName "deviceList" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "deviceList" -variableName "spinner"))
    (Get-Component -relationName "deviceList" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "deviceList" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "deviceList" -variableName "baseForm" -valueOfVar $baseForm