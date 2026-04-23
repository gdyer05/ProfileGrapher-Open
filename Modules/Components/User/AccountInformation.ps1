[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This is the Label for the Account Details Section, shown just below the Display Profile
#>
$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(15, 130)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Account Details"

<#
    This is the DataGridView, a.k.a. Table, shown in the Account Details section that holds individual values
#>
$thisGrid = [System.Windows.Forms.DataGridView]::new()
$thisGrid.Location = [System.Drawing.Point]::new(15, 155)                   # This is the position of the Table on the Window
$thisGrid.Size = [System.Drawing.Size]::new(265, 131)                       # This is the Size of the Table.
$thisGrid.BackgroundColor = [System.Drawing.Color]::FromArgb(255, 255, 255)     # This is the Background Color for the empty space
$thisGrid.Scrollbars = "Vertical"                                               # Enable Scrolling Vertically by default
$thisGrid.AutoGenerateColumns = $true                                           # Automatically handle Columns when Data is applied to the table
$thisGrid.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill     # Evenly Fill the Table's space with the Columns
$thisGrid.DataSource = [System.Collections.ArrayList]@(                         # Set Up a Sample Dataset
    [PSCustomObject]@{
        Name  = "Account Enabled"
        Value = "False"
    },
    [PSCustomObject]@{
        Name  = "Created"
        Value = "Never"
    },
    [PSCustomObject]@{
        Name  = "Last Sign-In"
        Value = "Never"
    },
    [PSCustomObject]@{
        Name  = "On-Premises Sync"
        Value = "Never"
    },
    [PSCustomObject]@{
        Name  = "User Type"
        Value = "None"
    }
)
$thisGrid.RowHeadersVisible = $false                                            # Hide the Row Names since they will show information we don't want
$thisGrid.ColumnHeadersVisible = $false                                         # Hide the Column Names since they will show information we don't want
$thisGrid.AllowUserToResizeRows = $false                                        # Disable Resizing the Rows so that Users do not mess with the Table
$thisGrid.AllowUserToResizeColumns = $false                                     # Disable Resizing the Column so that Users do not mess with the Table
$thisGrid.ReadOnly = $true                                                      # Make the Table Read-Only to prevent users from modifying the values
$thisGrid.GridColor = [System.Drawing.Color]::FromArgb(200, 200, 200)           # Set the color of the Grid to a gray color
$thisGrid.DefaultCellStyle.SelectionBackColor = [System.Drawing.Color]::White   # Make the Background of the Cells White
$thisGrid.DefaultCellStyle.SelectionForeColor = [System.Drawing.Color]::Black   # Make the Text/Foreground of the Cells Black
$thisGrid.BorderStyle = [System.Windows.Forms.BorderStyle]::None                # Remove the Border styling to make the Table fit in with the other elements
$thisGrid.RowTemplate.Height = (130 / 5)                                        # Evenly divide the space of the Rows to take up 5 rows in the view

<#
    This is the Callback for A User's Information being retrieved, including a reference to the User's Information
#>
Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    # Set the Background of the table to White to show that the data has loaded
    (Get-Component -relationName "accountDetails" -variableName "thisGrid").BackgroundColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
    $baseForm.Controls.Remove((Get-Component -relationName "accountDetails" -variableName "spinner"))   # Hide the spinning wheel

    # Update the Data contained in the Table
    (Get-Component -relationName "accountDetails" -variableName "thisGrid").DataSource = [System.Collections.ArrayList]@(
        [PSCustomObject]@{
            Name  = "Account Enabled"
            Value = $user.accountEnabled
        },
        [PSCustomObject]@{
            Name  = "Created"
            Value = $user.createdDateTime
        },
        [PSCustomObject]@{
            Name  = "Last Sign-In"
            Value = "Loading..."
        },
        [PSCustomObject]@{
            Name  = "User Type"
            Value = $user.userType
        },
        [PSCustomObject]@{
            Name  = "On-Premises Sync"
            Value = $user.onPremisesSyncEnabled
        },
        [PSCustomObject]@{
            Name  = "On-Prem. Identifier"
            Value = $user.onPremisesSecurityIdentifier
        },
        [PSCustomObject]@{
            Name  = "On-Prem. Last Synced"
            Value = $user.onPremisesLastSyncDateTime
        },
        [PSCustomObject]@{
            Name  = "User ID"
            Value = $user.id
        }
    )
}

<#
    This is the Callback for preparing the elements for the loading time while the user waits for their information to be found
#>
Register-EventCallback -EventName "AwaitData" -Callback {
    <#
        Remove/Hide the Elements that we are going to change and show later on
    #>
    (Get-Component -relationName "accountDetails" -variableName "thisGrid").DataSource = [System.Collections.ArrayList]@()
    (Get-Component -relationName "accountDetails" -variableName "thisGrid").BackgroundColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

    <#
        Show the Loading Spinner and Bring it to the front of the Form
    #>
    $baseForm.Controls.Add((Get-Component -relationName "accountDetails" -variableName "spinner"))
    (Get-Component -relationName "accountDetails" -variableName "spinner").BringToFront()
}

<#
    Add all of the Account Information - Related Elements to the Form at the start
#>
$baseForm.Controls.Add($header)
$baseForm.Controls.Add($thisGrid)

<#
    Register all of the Components to be referenced later in the respective callbacks
#>
Register-Component -relationName "accountDetails" -variableName "thisGrid" -valueOfVar $thisGrid

<#
    Create a Loading Spinner for this part of the Winform
#>
$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $thisGrid
Register-Component -relationName "accountDetails" -variableName "spinner" -valueOfVar $spinner

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(15, 300)) -dividerSize 265