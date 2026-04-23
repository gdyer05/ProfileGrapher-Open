[CmdletBinding()]
Param()

<#
    Load Any Components With Functions or Utilities
#>
. "$modulePath\Components\Base\WndProcForm"
. "$modulePath\Components\Base\DividerLine"
. "$modulePath\Components\Base\BorderlessTabControl"
. "$modulePath\Components\Base\BoldableLabel"

<# 
    Create a WindowsForms Window to display our data on
#>
$baseForm = [WndProcForm]::new()
$baseForm.Text = "$($global:pg_projectJson.Name)"                                  # Title Bar
$baseForm.Width = 720                                                           # Width
$baseForm.Height = 600                                                          # Height
$baseForm.MaximizeBox = $false                                                  # Hide Unnecessary Buttons
$baseForm.MinimizeBox = $false                                                  # Hide Unnecessary Buttons
[System.Windows.Forms.Application]::EnableVisualStyles()                        # Used to make the window appear in Windows 11 Style
$baseForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog # Prevents the Window from Resizing
$baseForm.Icon = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 238 -LargeIcon) # Sets the Icon for the Window to be the User Icon
[PSAppID]::SetAppIdForWindow($baseForm.Handle, "ProfileGrapher")                # This will separate our ProfileGrapher window from the Powershell Script
$baseForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen# Center the Window when it shows up

<# 
    Compose the Inner Contents of our Window 
#>
. "$modulePath\Components\Base\Loader"                                      # Spinning Loading Indicator Basis, VERY IMPORTANT FOR KEEPING ASYNCHRONOUS TASKS ALIVE!
. "$modulePath\Components\Base\SearchBar" -baseForm $baseForm               # Search Bar, Used to Look Up Information on a User via their email
. "$modulePath\Components\Base\ExportControls" -baseForm $baseForm          # Export and  Batch Export Buttons that Automatically Export Data to a file
. "$modulePath\Components\User\DisplayProfile" -baseForm $baseForm          # The Display Profile information of the user being searched
. "$modulePath\Components\User\AccountInformation" -baseForm $baseForm      # The Account Information of the user being searched
. "$modulePath\Components\User\LicenseInfo" -baseForm $baseForm             # The License and Plan information regarding the user

<#
    TABS
#>
Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(294, 10)) -dividerSize 540 -isVertical

$tabControl = [System.Windows.Forms.TabControl]::new()                      # Create the Container that Holds the Tabs
$tabControl.Location = [System.Drawing.Point]::new(310, 45)                 # Position the Tab Control
$tabControl.Size = [System.Drawing.Size]::new(380, 550)                     # Size for the Tab Control
$tabControl.Multiline = $true                                               # Allows the Tabs to stack instead of cram
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::FillToRight      # Makes the Tabs Fill Up Empty Space
$baseForm.Controls.Add($tabControl)                                         # Adds the Tab Control

$borderless = [BorderlessTabControl]::new()                                 # After the Tab Control is added, create a Borderless Handle for the Tab Control
$borderless.AssignHandle($tabControl.Handle)                                # Assign the Tab Control's Handle to the Borderless Version

if ($global:pg_userPermissions.Contains("UserAuthenticationMethod.Read.All") -or $global:pg_userPermissions.Contains("AuditLog.Read.All") -or $global:pg_userPermissions.Contains("Directory.Read.All")) {
    Add-TabPage -tabControl $tabControl -tabName "Authentication & Sign-Ins"    -tabScript "$modulePath\Components\Tabs\AuthSignIns"        # Sign-In History & Authentication Methods
}
if ($global:pg_userPermissions.Contains("User.Read.All")) {
    Add-TabPage -tabControl $tabControl -tabName "Roles and Groups"             -tabScript "$modulePath\Components\Tabs\RolesGroups"        # All Roles and Groups Assigned to User
}
if ($global:pg_userPermissions.Contains("IdentityRiskyUser.Read.All") -or $global:pg_userPermissions.Contains("IdentityRiskEvent.Read.All")) {
    Add-TabPage -tabControl $tabControl -tabName "Risk Assessment"              -tabScript "$modulePath\Components\Tabs\RiskAssessment"    
}
if ($global:pg_userPermissions.Contains("AuditLog.Read.All") -or $global:pg_userPermissions.Contains("Directory.Read.All")) {
    Add-TabPage -tabControl $tabControl -tabName "Audit Logs (<30 Days)"        -tabScript "$modulePath\Components\Tabs\Audits"
}
if ($global:pg_userPermissions.Contains("User.Read.All")) {
    Add-TabPage -tabControl $tabControl -tabName "Devices"            -tabScript "$modulePath\Components\Tabs\Devices"   # Displays Computers associated with a User
}

<#
    Finalization:
#>
$handle = $baseForm.Handle
$sysMenu = [NativeMethods]::GetSystemMenu($handle, $false)

# Add Console Toggle
[NativeMethods]::AppendMenu($sysMenu, [NativeMethods]::MF_SEPARATOR, 0, "") | Out-Null
[NativeMethods]::AppendMenu($sysMenu, [NativeMethods]::MF_STRING, 0x1000, "Toggle Shell") | Out-Null
[NativeMethods]::AppendMenu($sysMenu, [NativeMethods]::MF_STRING, 0x1100, "Show Documentation") | Out-Null
Register-ObjectEvent -InputObject $baseForm -EventName MessageReceived -MessageData $modulePath,$dependencyPath -Action {
    if ($Event.SourceEventArgs.Msg -eq [NativeMethods]::WM_SYSCOMMAND) {
        if ($Event.SourceEventArgs.WParam.ToInt32() -eq 0x1000) {
            $modulePath = $Event.MessageData[0]
            . "$modulePath\Utils\ConsoleVisibility.ps1"
            Switch-ConsoleVisible
        }
        if ($Event.SourceEventArgs.WParam.ToInt32() -eq 0x1100) {
            $modulePath = $Event.MessageData[0]
            . "$modulePath\Utils\Icons.ps1"
            . "$modulePath\Components\Windows\ReadMeMenu.ps1"
        }
    }
} | Out-Null

$baseForm.TopMost = $false
Hide-Console
$baseForm.ShowDialog() | Out-Null          # Finally, present our window to the user
Show-Console