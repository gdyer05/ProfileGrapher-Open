[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    WARNING: UNIMPLEMENTED FEATURES AHEAD

    These Buttons will allow for User Data to be exported as Files or Spreadsheets, including a Bulk No-GUI version

    This ALSO Contains the Progress Bar used to show how much information is pending
#>

$exportButton = [System.Windows.Forms.Button]::new()
$exportButton.Location = [System.Drawing.Point]::new(310, 8)
$exportButton.Size = [System.Drawing.Size]::new(60, 24)
$exportButton.Text = "Export"
$exportButton.Enabled = $false

$batchButton = [System.Windows.Forms.Button]::new()
$batchButton.Location = [System.Drawing.Point]::new(375, 8)
$batchButton.Size = [System.Drawing.Size]::new(90, 24)
$batchButton.Text = "Batch Export"
$batchButton.Enabled = $true

$baseForm.Controls.Add($exportButton)
$baseForm.Controls.Add($batchButton)

Register-Component -relationName "exportControls" -variableName "exportButton" -valueOfVar $exportButton
Register-Component -relationName "exportControls" -variableName "batchButton" -valueOfVar $batchButton

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(310, 40)) -dividerSize 380

<# 
    Progress Bar 
#>
$progressBar = [System.Windows.Forms.ProgressBar]::new()            # Create the Progress Bar
$progressBar.Location = [System.Drawing.Point]::new(475, 10)    # Align it to the Top Right
$progressBar.Size = [System.Drawing.Size]::new(213, 20)         # Size the Bar to fit properly
$baseForm.Controls.Add($progressBar)                                # Add the Bar to the Window

# Register the Bar so it can later be updated
Register-Component -relationName "exportControls" -variableName "progressBar" -valueOfVar $progressBar

# When the Bar Needs to be Updated Via Callback
Register-EventCallback -EventName "UpdateProgress" -Callback {
    #Write-Host "$($global:pg_ProgressCurrent) / $($global:pg_ProgressTotal)"
    $progressBar = [System.Windows.Forms.ProgressBar](Get-Component -relationName "exportControls" -variableName "progressBar")     # Fetch the Bar
    $progressBar.Minimum = 0                                                                                                        # Set the Minimum Value to 0
    $progressBar.Maximum = $global:pg_ProgressTotal                                                                                    # Set the Maximum to the total number of Jobs
    $progressBar.Value = $global:pg_ProgressCurrent                                                                                    # Sets the Value to number of completed Jobs
}

Register-EventCallback -EventName "AwaitData" -Callback {
    (Get-Component -relationName "exportControls" -variableName "exportButton").Enabled = $false
    (Get-Component -relationName "exportControls" -variableName "batchButton").Enabled = $false
}

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    (Get-Component -relationName "exportControls" -variableName "exportButton").Enabled = $true
    (Get-Component -relationName "exportControls" -variableName "batchButton").Enabled = $true
}

# Button Callbacks
$exportButton.Add_Click({
    param()

    . "$modulePath\Components\Windows\ExportToFile" -userPrincipalName $global:pg_lastSearchedUser
})
$batchButton.Add_Click({
    param()

    $userListFile = (Request-UserListFile)
    if ($null -ne $userListFile) {
        . "$modulePath\Components\Windows\ExportToFile" -userList (Get-UserListFromFile -Path $userListFile.FileName) -batchExport
    } else {
        $allUsers = (Get-MgBetaUser -Select "userPrincipalName" -All | Select-Object -ExpandProperty userPrincipalName)
        . "$modulePath\Components\Windows\ExportToFile" -userList $allUsers -batchExport
    }
})