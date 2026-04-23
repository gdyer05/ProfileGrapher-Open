[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<# 
    This is the User's Profile Picture. It has various functions associated with it in the Utils\PictureFunctions.ps1
#>
$profilePicture = [System.Windows.Forms.PictureBox]::new()                      # Create a Picture Box
$profilePicture.Location = [System.Drawing.Point]::new(15, 50)                  # LOcation of the Picture box on the Winform
$profilePicture.Size = [System.Drawing.Size]::new(64, 64)                   # Size of the Picture box on the Winform
$profilePicture.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom      # The image content will be scaled to fit in the PictureBox's size
$profilePicture.Image = (Get-UserPicture -displayName "?")                      # Create a Placeholder Image

<#
    This is the User's Display Name. It is normally shown as FirstName LastName, though there are certain exceptions...
#>
$displayName = [System.Windows.Forms.Label]::new()
$displayName.Location = [System.Drawing.Point]::new(90, 52)                                                     # Sets the Location of the Display Name label
$displayName.Size = [System.Drawing.Size]::new(200, 24)                                                         # Sets the Bounds in Size for the Text Label
$displayName.Font = [System.Drawing.Font]::new($displayName.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)  # Sets the User's Display Name to a Bold Font
$displayName.Text = "FirstName LastName"                                                                            # Displays a Placeholder Name

<#
    This is the Short Job Description listed under your profile
#>
$jobTitle = [System.Windows.Forms.Label]::new()
$jobTitle.Location = [System.Drawing.Point]::new(90, 74)        # This is the location on the Winform where the job title will show up
$jobTitle.Size = [System.Drawing.Size]::new(200, 16)            # This is the rough bounds for the text which displays the job title
$jobTitle.Text = "Sample Role Description"                          # Sample Text

<#
    This is the User Principal Name, most commonly identified as work email
#>
$principalName = [System.Windows.Forms.Label]::new()
$principalName.Location = [System.Drawing.Point]::new(90, 92)   # This is the location on the Winform where the principal name (email) will show up
$principalName.Size = [System.Drawing.Size]::new(200, 16)       # This is the rough bounds for the text which displays the principal name (email)
$principalName.Text = "sample@domain"               # Sample Text

<#
    This is the Callback for A User's Information being retrieved, including a reference to the User's Information
#>
Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    (Get-Component -relationName "profile" -variableName "displayName").Text = $user.displayName
    (Get-Component -relationName "profile" -variableName "principalName").Text = $user.userPrincipalName
    (Get-Component -relationName "profile" -variableName "jobTitle").Text = $user.jobTitle

    (Get-Component -relationName "profile" -variableName "profilePicture").Image = (Get-UserPicture -userId $user.id -displayName $user.displayName)

    $baseForm.Controls.Remove((Get-Component -relationName "profile" -variableName "spinner"))

    $baseForm.Controls.Add((Get-Component -relationName "profile" -variableName "displayName"))
    $baseForm.Controls.Add((Get-Component -relationName "profile" -variableName "principalName"))
    $baseForm.Controls.Add((Get-Component -relationName "profile" -variableName "jobTitle"))
}

<#
    This is the Callback for preparing the elements for the loading time while the user waits for their information to be found
#>
Register-EventCallback -EventName "AwaitData" -Callback {
    <#
        Remove/Hide the Elements that we are going to change and show later on
    #>
    $baseForm.Controls.Remove((Get-Component -relationName "profile" -variableName "displayName"))
    $baseForm.Controls.Remove((Get-Component -relationName "profile" -variableName "principalName"))
    $baseForm.Controls.Remove((Get-Component -relationName "profile" -variableName "jobTitle"))

    <#
        Show the Loading Spinner and Bring it to the front of the Form
    #>
    $baseForm.Controls.Add((Get-Component -relationName "profile" -variableName "spinner"))
    (Get-Component -relationName "profile" -variableName "spinner").BringToFront()

    (Get-Component -relationName "profile" -variableName "profilePicture").Image = (ConvertTo-RoundBitmap -bitmap (New-TemplatePicture -initials "..." -color ([System.Drawing.Color]::FromArgb(205, 205, 205)) -textColor ([System.Drawing.Color]::FromArgb(150, 150, 150))))
}

<#
    Add all of the Display Profile - Related Elements to the Form at the start
#>
$baseForm.Controls.Add($profilePicture)
$baseForm.Controls.Add($displayName)
$baseForm.Controls.Add($jobTitle)
$baseForm.Controls.Add($principalName)

<#
    Register all of the Components to be referenced later in the respective callbacks
#>
Register-Component -relationName "profile" -variableName "profilePicture" -valueOfVar $profilePicture
Register-Component -relationName "profile" -variableName "displayName" -valueOfVar $displayName
Register-Component -relationName "profile" -variableName "jobTitle" -valueOfVar $jobTitle
Register-Component -relationName "profile" -variableName "principalName" -valueOfVar $principalName

<#
    Create a Loading Spinner for this part of the Winform
#>
$spinner = Build-LoadingSpinner
$spinner.Location = [System.Drawing.Point]::new(135, 65)
Register-Component -relationName "profile" -variableName "spinner" -valueOfVar $spinner

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(15, 125)) -dividerSize 265