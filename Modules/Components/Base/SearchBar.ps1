[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    The Search Bar is Important as it Initializes All Data Requests using the Results of what it searches for.

    It will either work with an Email (user@domain.com) or with just the username which will autocorrect it for you (user -> user@domain.com)
#>

<# 
    This is the Input Bar, which is typed into when searching for a user by email
#>
$inputBar = [System.Windows.Forms.TextBox]::new()
$inputBar.Location = [System.Drawing.Point]::new(15, 8)     # Position on the Window
$inputBar.Size = [System.Drawing.Size]::new(200, 24)        # Size relative to the Window
$inputBar.PlaceholderText = "User Email or Name"                # The Text that shows up when nothing is filled in

<# 
    This is the Search Button, when pressed, it will take the Input Bar's text, search for the user with that email, and return it to the other components
#>
$searchButton = [System.Windows.Forms.Button]::new()
$searchButton.Location = [System.Drawing.Point]::new(220, 8)        # Position on the Window
$searchButton.Size = [System.Drawing.Size]::new(60, 24)             # Size relative to the Window
$searchButton.Text = "Search"                                       # The Text that shows up on the Button

<#
    This is the Submit Event related to pressing the Search Button
#>
$submitFunc = {
    param()

    Disconnect-AllJobs
    Reset-ProgressBar

    # Autocomplete email
    if ((Get-Component -relationName "search" -variableName "inputBar").Text -notmatch "@") {
        (Get-Component -relationName "search" -variableName "inputBar").Text = "$((Get-Component -relationName "search" -variableName "inputBar").Text)$($global:pg_projectJson.Organization.ProfileAutofill)"
    }

    $global:pg_lastSearchedUser = (Get-Component -relationName "search" -variableName "inputBar").Text

    # Disable the User's Search Button so they cannot search for multiple people at the same time
    (Get-Component -relationName "search" -variableName "searchButton").Enabled = $false
    (Get-Component -relationName "search" -variableName "inputBar").Enabled = $false

    # Tell every other component that it should start Loading in preparation for receiving new user data
    Send-EventCallback -EventName "AwaitData"

    # Start a Asynchronous Job with the Purpose of Getting the Microsoft Graph Information of the given user
    $job = Start-ThreadJob -ScriptBlock {
        param($searchName)

        # This function uses the Beta version of Get-MgUser to fetch more descriptive information about the given user
        Get-MgBetaUser -Filter "userPrincipalName eq '$($searchName)'" | Select-Object -First 1
    } -ArgumentList (Get-Component -relationName "search" -variableName "inputBar").Text

    # Once the Job is finished, run this code:
    Register-JobCompletion -Job $job -JobCb {
        param($e, $newUser)

        # If there was a valid user found, Tell every other component to update itself with the new data
        if ($null -ne $newUser) {
            Send-EventCallback -EventName "GetUser" -Args $newUser
        }

        # Reset the Input Bar's text entry and allow the user to search again
        (Get-Component -relationName "search" -variableName "inputBar").Text = ""
        (Get-Component -relationName "search" -variableName "searchButton").Enabled = $true
        (Get-Component -relationName "search" -variableName "inputBar").Enabled = $true
    }
}

<#
    Attach the Submit Function to the Button and the Enter Key
#>
$searchButton.Add_Click($submitFunc)
$inputBar.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Enter) {
        . $submitFunc                   # Execute the Callback
        $_.Handled = $true              # Help Prevent the Annoying Sound from Playing when you Press Enter
        $_.SuppressKeyPress = $true     # Help Prevent the Annoying Sound from Playing when you Press Enter (Again.)
    }
})

# Add the Input Bar and the Search Button to the Main Window
$baseForm.Controls.Add($inputBar)
$baseForm.Controls.Add($searchButton)

# Register the Two Components so that they may be referenced in Asynchronous Jobs (Powershell doesn't think they exist if you don't do this)
Register-Component -relationName "search" -variableName "searchButton" -valueOfVar $searchButton
Register-Component -relationName "search" -variableName "inputBar" -valueOfVar $inputBar

# Add a Line below the Search Bar Components
Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(15, 40)) -dividerSize 265