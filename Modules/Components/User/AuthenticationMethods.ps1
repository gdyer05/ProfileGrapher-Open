[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(0, 249)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Authentication Methods"

$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(0, 274)
$treeView.Size = [System.Drawing.Size]::new(380, 190)

# Images
$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 300))                                                            # Password Key
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 55))                                                             # Fido2 (Key)
$imgList.Images.Add((Import-UnlockedImage -imgPath "$(Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot)))\Assets\msAuthenticator.png"))   # MS Auth
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 15))                                                             # Email
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 170))                                                            # External
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 213))                                                            # Hardware Oauth
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 165))                                                            # Software Oauthd
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 42))                                                             # SMS
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 202))                                                            # Temporary Access
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 41))                                                             # Voice Access
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 168))                                                            # QR Code
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\dsuiext.dll" -Index 29))                                                              # x509 Cert
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 273))                                                            # Calendar
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 76))                                                             # Info
$imgList.Images.Add((Import-UnlockedImage -imgPath "$(Split-Path -Path (Split-Path -Path (Split-Path -Path $PSScriptRoot)))\Assets\windowsHello.png"))      # Windows Hello

$treeView.ImageList = $imgList

$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

Register-Component -relationName "authMethods" -variableName "treeView" -valueOfVar $treeView

Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "authMethods" -variableName "treeView")

    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    $job = Start-ThreadJob -ScriptBlock {
        param($userId)
        Get-MgBetaUserAuthenticationMethod -UserId $userId
    } -ArgumentList $user.Id

    Register-JobCompletion -Job $job -JobCb {
        param($user, $authMethods)

        $baseForm = (Get-Component -relationName "authMethods" -variableName "baseForm")
        $baseForm.Controls.Remove((Get-Component -relationName "authMethods" -variableName "spinner"))

        if ($null -ne $authMethods) {
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "authMethods" -variableName "treeView")
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()

            # Odata to Image
            $odataToIcon = @{
                "passwordAuthenticationMethod"               = 0
                "fido2AuthenticationMethod"                  = 1
                "microsoftAuthenticatorAuthenticationMethod" = 2
                "emailAuthenticationMethod"                  = 3
                "externalAuthenticationMethod"               = 4
                "hardwareOathAuthenticationMethod"           = 5
                "softwareOathAuthenticationMethod"           = 6
                "smsAuthenticationMethod"                    = 7
                "temporaryAccessPathAuthenticationMethod"    = 8
                "voiceAuthenticationMethod"                  = 9
                "qrCodePinAuthenticationMethod"              = 10
                "x509CertificateAuthenticationMethod"        = 11
                "windowsHelloForBusinessAuthenticationMethod"= 14
            }

            foreach ($auth in $authMethods) {
                # Create a new node for each authentication entry
                $nodeName = $auth['displayName']
                if (($null -eq $nodeName) -or ($auth['@odata.type'] -replace '^#microsoft\.graph\.', '' -replace 'AuthenticationMethod$', '' -eq "windowsHelloForBusiness")) {
                    # Strip Type -> camelCase Name -> TitleCase with Spaces Name
                    $nodeName = [System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($auth['@odata.type'] -replace '^#microsoft\.graph\.', '' -replace 'AuthenticationMethod$', '' -creplace '([a-z])([A-Z])', '$1 $2'))
                }
                $newNode = [System.Windows.Forms.TreeNode]::new($nodeName,$odataToIcon[$auth['@odata.type'] -replace '^#microsoft\.graph\.', ''],$odataToIcon[$auth['@odata.type'] -replace '^#microsoft\.graph\.', ''])
                $treeView.Nodes.Add($newNode)

                # Special Information
                if ($null -ne $auth['createdDateTime']) {
                    $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($auth['createdDateTime'], 12, 12))
                }

                $newNode.Nodes.Add([System.Windows.Forms.TreeNode]::new([System.Globalization.CultureInfo]::CurrentCulture.TextInfo.ToTitleCase(($auth['@odata.type'] -replace '^#microsoft\.graph\.', '' -replace 'AuthenticationMethod$', '' -creplace '([a-z])([A-Z])', '$1 $2')), 13, 13))
            }

            $treeView.EndUpdate()
        }
    }
}

Register-EventCallback -EventName "AwaitData" -Callback {
    $baseForm = (Get-Component -relationName "authMethods" -variableName "baseForm")

    (Get-Component -relationName "authMethods" -variableName "treeView").BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
    $baseForm.Controls.Add((Get-Component -relationName "authMethods" -variableName "spinner"))
    (Get-Component -relationName "authMethods" -variableName "spinner").BringToFront()
}

$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "authMethods" -variableName "spinner" -valueOfVar $spinner

Register-Component -relationName "authMethods" -variableName "baseForm" -valueOfVar $baseForm