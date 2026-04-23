[CmdletBinding()]
Param(
    [string] $userPrincipalName,
    [System.Collections.ArrayList] $userList,
    [Switch] $batchExport = $false
)

$exportForm = [System.Windows.Forms.Form]::new()
$exportForm.Text = $batchExport ? "Batch Export Profile" : "Export Profile"         # Title Bar
$exportForm.Width = 400                                                             # Width
$exportForm.Height = 250                                                            # Height
$exportForm.MaximizeBox = $false                                                    # Hide Unnecessary Buttons
$exportForm.MinimizeBox = $false                                                    # Hide Unnecessary Buttons
$exportForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog   # Prevents the Window from Resizing
$exportForm.Icon = (Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 238 -LargeIcon) # Sets the Icon for the Window to be the User Icon
[PSAppID]::SetAppIdForWindow($exportForm.Handle, "ProfileGrapher")                  # This will separate our ProfileGrapher window from the Powershell Script
$exportForm.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen  # Center the Window when it shows up

<#
    Components
#>
$header = [BoldableLabel]::new($true)
$header.Location = [System.Drawing.Point]::new(5, 5)
$header.Size = [System.Drawing.Size]::new(385, 20)
$header.Text = "Exporting Data For:|$($batchExport ? ("$($userList.Count) User(s)") : $userPrincipalName)"
$exportForm.Controls.Add($header)

Add-DividerLine -baseForm $exportForm -dividerLocation ([System.Drawing.Point]::new(10, 26)) -dividerSize 365

<#
    EXPORT DATA SELECTION
#>
$permsHead = [System.Windows.Forms.Label]::new()
$permsHead.Location = [System.Drawing.Point]::new(5, 30)
$permsHead.Size = [System.Drawing.Size]::new(190, 24)
$permsHead.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12)
$permsHead.Text = "Select Data to Export"
$exportForm.Controls.Add($permsHead)

$checkedList = [System.Windows.Forms.CheckedListBox]::new()
$checkedList.Location = [System.Drawing.Point]::new(10, 55)
$checkedList.Size = [System.Drawing.Size]::new(180, 120)
$checkedList.Items.AddRange(@("Account Details", "Licenses", "Devices", "Roles & Groups", "Authentication Methods", "Risk Status"))
for ($i = 0; $i -lt $checkedList.Items.Count; $i++) {
    $checkedList.SetItemChecked($i, $true);
}
$exportForm.Controls.Add($checkedList)

Add-DividerLine -baseForm $exportForm -dividerLocation ([System.Drawing.Point]::new(200, 40)) -dividerSize 120 -isVertical


<#
    EXPORT BUTTONS
#>
$expHead = [System.Windows.Forms.Label]::new()
$expHead.Location = [System.Drawing.Point]::new(205, 30)
$expHead.Size = [System.Drawing.Size]::new(190, 24)
$expHead.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12)
$expHead.Text = "Export"
$exportForm.Controls.Add($expHead)

$exportDefaultButton = [System.Windows.Forms.Button]::new()
$exportDefaultButton.Location = [System.Drawing.Point]::new(210, 55)
$exportDefaultButton.Size = [System.Drawing.Size]::new(165, 36)
$exportDefaultButton.Text = "Export All (.xlsx)"
$exportForm.Controls.Add($exportDefaultButton)
$exportDefaultButton.Add_Click({
        $progressBar.Value = 0
        $progressBar.Minimum = 0
        $progressBar.Maximum = $userList.Count + 1

        if ($batchExport) {
            # Batch Export.
            $saveFileDialogue = (Request-SaveFileLocation -userPrincipalName "Batch-Operation-$(Get-Date -Format "yyyy-MM-dd")")
            if ($null -ne $saveFileDialogue) {
                $checkedList.Enabled = $false
                $exportDefaultButton.Enabled = $false
                $exportSeparateButton.Enabled = $false
                $exportIndividualButton.Enabled = $false

                $userInfoList = [System.Collections.ArrayList]::new()
                foreach ($userEmail in $userList) {
                    $userInfoList.Add((Get-FullUserData -userPrincipalName $userEmail -getAccountDetails $checkedList.GetItemChecked(0) -getLicenses $checkedList.GetItemChecked(1) -getDevices $checkedList.GetItemChecked(2) -getRolesGroups $checkedList.GetItemChecked(3) -getAuthenticationMethods $checkedList.GetItemChecked(4) -getRiskStatus $checkedList.GetItemChecked(5)))
                    $progressBar.Value++
                }
                Convert-BatchUsersToSpreadsheet -userInfoList $userInfoList -outputPath $saveFileDialogue.FileName -getAccountDetails $checkedList.GetItemChecked(0) -getLicenses $checkedList.GetItemChecked(1) -getDevices $checkedList.GetItemChecked(2) -getRolesGroups $checkedList.GetItemChecked(3) -getAuthenticationMethods $checkedList.GetItemChecked(4) -getRiskStatus $checkedList.GetItemChecked(5)
                $progressBar.Value = $progressBar.Maximum
            }
        }
        else {
            # Single User
            $saveFileDialogue = (Request-SaveFileLocation -userPrincipalName $userPrincipalName)
            if ($null -ne $saveFileDialogue) {
                $checkedList.Enabled = $false
                $exportDefaultButton.Enabled = $false
                $exportSeparateButton.Enabled = $false
                $exportIndividualButton.Enabled = $false
                Convert-UserDataToSpreadsheet -userInfo (Get-FullUserData -userPrincipalName $userPrincipalName -getAccountDetails $checkedList.GetItemChecked(0) -getLicenses $checkedList.GetItemChecked(1) -getDevices $checkedList.GetItemChecked(2) -getRolesGroups $checkedList.GetItemChecked(3) -getAuthenticationMethods $checkedList.GetItemChecked(4) -getRiskStatus $checkedList.GetItemChecked(5)) -outputPath $saveFileDialogue.FileName
                $progressBar.Value = 1
            }
        }
    })

$exportSeparateButton = [System.Windows.Forms.Button]::new()
$exportSeparateButton.Location = [System.Drawing.Point]::new(210, 55 + 38)
$exportSeparateButton.Size = [System.Drawing.Size]::new(165, 36)
$exportSeparateButton.Text = "Export Separate Users (.xlsx)"
$exportSeparateButton.Enabled = $batchExport
$exportForm.Controls.Add($exportSeparateButton)
$exportSeparateButton.Add_Click({
        $progressBar.Value = 0
        $progressBar.Minimum = 0
        $progressBar.Maximum = $userList.Count

        $saveFileDialogue = (Request-FolderExportLocation)
        if ($null -ne $saveFileDialogue) {
            $checkedList.Enabled = $false
            $exportDefaultButton.Enabled = $false
            $exportSeparateButton.Enabled = $false
            $exportIndividualButton.Enabled = $false

            foreach ($userEmail in $userList) {
                $outPath = "$($saveFileDialogue.SelectedPath)/Export-$($userEmail -Replace "@", "-" -Replace "\.","-").xlsx"
                Convert-UserDataToSpreadsheet -userInfo (Get-FullUserData -userPrincipalName $userEmail -getAccountDetails $checkedList.GetItemChecked(0) -getLicenses $checkedList.GetItemChecked(1) -getDevices $checkedList.GetItemChecked(2) -getRolesGroups $checkedList.GetItemChecked(3) -getAuthenticationMethods $checkedList.GetItemChecked(4) -getRiskStatus $checkedList.GetItemChecked(5)) -outputPath $outPath
            
                $progressBar.Value++
            }
            $progressBar.Value = $progressBar.Maximum
        }
    })

$exportIndividualButton = [System.Windows.Forms.Button]::new()
$exportIndividualButton.Location = [System.Drawing.Point]::new(210, 55 + (38 * 2))
$exportIndividualButton.Size = [System.Drawing.Size]::new(165, 36)
$exportIndividualButton.Text = "Individual Export (.csv)"
$exportIndividualButton.Enabled = (-not $batchExport)
$exportForm.Controls.Add($exportIndividualButton)
$exportIndividualButton.Add_Click({
        $progressBar.Value = 0
        $progressBar.Minimum = 0
        $progressBar.Maximum = 1

        $saveFileDialogue = (Request-FolderExportLocation)
        if ($null -ne $saveFileDialogue) {
            $checkedList.Enabled = $false
            $exportDefaultButton.Enabled = $false
            $exportSeparateButton.Enabled = $false
            $exportIndividualButton.Enabled = $false
            Convert-UserDataToSpreadsheet -userInfo (Get-FullUserData -userPrincipalName $userPrincipalName -getAccountDetails $checkedList.GetItemChecked(0) -getLicenses $checkedList.GetItemChecked(1) -getDevices $checkedList.GetItemChecked(2) -getRolesGroups $checkedList.GetItemChecked(3) -getAuthenticationMethods $checkedList.GetItemChecked(4) -getRiskStatus $checkedList.GetItemChecked(5)) -outputPath $saveFileDialogue.SelectedPath -individualCsvFiles
            $progressBar.Value = 1
        }
    })

<#
    EXPORT PROGRESS
#>
Add-DividerLine -baseForm $exportForm -dividerLocation ([System.Drawing.Point]::new(10, 175)) -dividerSize 365

$progressBar = [System.Windows.Forms.ProgressBar]::new()            # Create the Progress Bar
$progressBar.Location = [System.Drawing.Point]::new(10, 185)    # Align it to the Top Right
$progressBar.Size = [System.Drawing.Size]::new(365, 16)         # Size the Bar to fit properly
$exportForm.Controls.Add($progressBar)                                # Add the Bar to the Window

<#
    Finalization:
#>
#Save-ProfileUserToFile -userPrincipalName $userPrincipalName
$exportForm.TopMost = $true
$exportForm.ShowDialog() | Out-Null          # Finally, present our window to the User