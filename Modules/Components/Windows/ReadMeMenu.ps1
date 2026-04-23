[CmdletBinding()]
Param()

$readmeForm = [System.Windows.Forms.Form]::new()
$readmeForm.Text = "Help"
$readmeForm.Width = 600                                                             # Width
$readmeForm.Height = 600                                                            # Height
$readmeForm.MaximizeBox = $false                                                    # Hide Unnecessary Buttons
$readmeForm.MinimizeBox = $false                                                    # Hide Unnecessary Buttons
$readmeForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog   # Prevents the Window from Resizing
$readmeForm.Icon = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 238 -LargeIcon) # Sets the Icon for the Window to be the User Icon
[PSAppID]::SetAppIdForWindow($readmeForm.Handle, "ProfileGrapher")                  # This will separate our ProfileGrapher window from the Powershell Script
$readmeForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen  # Center the Window when it shows up

<#
    This uses Markdig and WebBrowser control elements to display the project ReadMe file.
#>
$viewer = [System.Windows.Forms.WebBrowser]::new()
$viewer.Size = [System.Drawing.Size]::new(600, 600)
$viewer.ScrollBarsEnabled = $true
$viewer.DocumentText = "<!DOCTYPE html><html><style>*{font-family:'Trebuchet MS';background-color:rgb(240,240,240)}body{margin-left:20px;margin-right:20px}h1,h2{background-color: transparent;border: none;border-bottom: 1px solid #cdcdcd;outline: none;padding: 8px;width:75%}</style><body class='markdown-body'>$([Markdig.Markdown]::ToHtml((Get-Content -Path "$modulePath\..\ReadMe.md" -Raw)))<div style='height:40px'></div></body></html>"

<#
    Show the Popup Window
#>
$readmeForm.Controls.Add($viewer)
$readmeForm.TopMost = $true
$readmeForm.ShowDialog() | Out-Null