[CmdletBinding()]
Param()

<#
    Load Any Components With Functions or Utilities
#>
. "$modulePath\Components\Base\DividerLine"

$global:pg_userPermissions = $null

<# 
    Create a WindowsForms Window to display our data on
#>
$baseForm = [System.Windows.Forms.Form]::new()
$baseForm.Text = ""                                                                 # Title Bar
$baseForm.Width = 240                                                               # Width
$baseForm.Height = 290                                                              # Height
$baseForm.MaximizeBox = $false                                                      # Hide Unnecessary Buttons
$baseForm.MinimizeBox = $false                                                      # Hide Unnecessary Buttons
[System.Windows.Forms.Application]::EnableVisualStyles()                            # Used to make the window appear in Windows 11 Style
$baseForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen    # Center the Window when it shows up
$baseForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog     # Prevents the Window from Resizing
$baseForm.Icon = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 238 -LargeIcon) # Sets the Icon for the Window to be the User Icon
[PSAppID]::SetAppIdForWindow($baseForm.Handle, "ProfileGrapher")                    # This will separate our ProfileGrapher window from the Powershell Script

<#
    This is the Label for the Launcher Dialog, Displaying the Project Name
#>
$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(5, 0)
$header.Size = [System.Drawing.Size]::new(250, 30)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 16, [System.Drawing.FontStyle]::Bold)
$header.Text = "$($global:pg_projectJson.Name)"

<#
    This is the Version Label, which also includes the Author, shown just below the Project Name
#>
$version = [System.Windows.Forms.Label]::new()
$version.Location = [System.Drawing.Point]::new(10, 32)
$version.Size = [System.Drawing.Size]::new(250, 16)
$version.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 8)
$version.Text = "v$($global:pg_projectJson.Version) | $($global:pg_projectJson.Author)"

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(10, 50)) -dividerSize 205

<#
    This is the Header for the Permissions Checklist
#>
$permsHead = [System.Windows.Forms.Label]::new()
$permsHead.Location = [System.Drawing.Point]::new(8, 65)
$permsHead.Size = [System.Drawing.Size]::new(250, 24)
$permsHead.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12)
$permsHead.Text = "User Permissions"

<#
    This is the Checklist for Permissions to request on authentication
#>
$checkedList = [System.Windows.Forms.CheckedListBox]::new()
$checkedList.Location = [System.Drawing.Point]::new(10,90)
$checkedList.Size = [System.Drawing.Size]::new(205,120)

<#
    This sets the Default Permissions and is where all of the permissions the program supports can be enabled or disabled
#>
$checkedList.Items.AddRange(@("User.Read.All", "UserAuthenticationMethod.Read.All", "ProfilePhoto.Read.All" , "AuditLog.Read.All", "IdentityRiskEvent.Read.All", "IdentityRiskyUser.Read.All", "Directory.Read.All"))
for ($i=0;$i -lt 7;$i++) {
    $checkedList.SetItemChecked($i, ($null -ne $global:pg_projectJson.DefaultPermissions[$checkedList.Items[$i]] ? $global:pg_projectJson.DefaultPermissions[$checkedList.Items[$i]] : $true));
}

<#
    This is the Button Used to Submit and Proceed to Permissions Authentication
#>
$startButton = [System.Windows.Forms.Button]::new()
$startButton.Text = "Login"
$startButton.Location = [System.Drawing.Point]::new(10,210)
$startButton.Size = [System.Drawing.Size]::new(205,30)
$startButton.Add_Click({
    $baseForm.Hide()

    # Read which boxes are checked and add the permission to the Global Registry
    $global:pg_userPermissions = [System.Collections.ArrayList]::new()
    for ($i=0;$i -lt $checkedList.Items.Count;$i++) {
        if ($checkedList.GetItemChecked($i)) {
            $global:pg_userPermissions.Add($checkedList.Items[$i])
        }
    }

    # Close the Window to resume the Main Thread
    $baseForm.Close() | Out-Null
})

$helpButton = [System.Windows.Forms.Button]::new()
$helpButton.Text = "?"
$helpButton.Location = [System.Drawing.Point]::new(190,5)
$helpButton.Size = [System.Drawing.Size]::new(24,24)
$helpButton.Add_Click({
    . "$modulePath\Components\Windows\ReadMeMenu.ps1"
})

<#
    Add All of our Components to the Window
#>
$baseForm.Controls.Add($helpButton)
$baseForm.Controls.Add($header)
$baseForm.Controls.Add($version)
$baseForm.Controls.Add($permsHead)
$baseForm.Controls.Add($checkedList)
$baseForm.Controls.Add($startButton)

<#
    Finalization:
#>
$baseForm.TopMost = $true
$baseForm.ShowDialog() | Out-Null          # Finally, present our window to the user