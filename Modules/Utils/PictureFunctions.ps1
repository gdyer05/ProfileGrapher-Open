<#
    This Function is used when creating random Hue Colors with the Same Saturation and Lightness
#>
function ConvertFrom-Hsl {
    [CmdletBinding()]
    param(
        $Hue,
        $Saturation,
        $Lightness, 
        # Return in ConEmu.xml ABGR hex format
        [Switch]$ABGR
    )
    
    function ToHex ($c) {
        $hex = [Convert]::ToString([Math]::Round($c * 255), 16).ToUpper()
        if ($hex.Length -eq 1) {
            "0$hex"
        } else {
            "$hex"
        }
    }

    $Hue = [double]($Hue / 360)
    if ($Saturation -gt 1) {
        $Saturation = [double]($Saturation / 100)
    }
    if ($Lightness -gt 1) {
        $Lightness = [double]($Lightness / 100)
    }
    
    if ($Saturation -eq 0) {
        # No color
        $red = $green = $blue = $Lightness
    } else {
        function HueToRgb ($p,$q,$t) {
            if ($t -lt 0) {
                $t++
            }
            if ($t -gt 1) {
                $t--
            } 
            if ($t -lt 1/6) {
                return $p + ($q - $p) * 6 * $t
            } 
            if ($t -lt 1/2) {
                return $q
            }
            if ($t -lt 2/3) {
                return $p + ($q - $p) * (2/3 - $t) * 6
            }
            return $p
        }
        $q = if ($Lightness -lt .5) {
            $Lightness * (1 + $Saturation)
        } else {
            $Lightness + $Saturation - $Lightness * $Saturation
        }
        $p = 2 * $Lightness - $q
        $red = HueToRgb $p $q ($Hue + 1/3)
        $green = HueToRgb $p $q $Hue
        $blue = HueToRgb $p $q ($Hue - 1/3)
    }
    
    if ($ABGR) {
        $b = ToHex $blue
        $g = ToHex $green
        $r = Tohex $red
        "$b$g$r"
    } else {
        [Ordered]@{
            Red = [Math]::Round($red * 255)
            Green = [Math]::Round($green * 255)
            Blue = [Math]::Round($blue * 255)
        }
    }
}

<#
    This function is used to create a Template Picture akin to Microsoft's Default Profile Pictures, used in place of no registered picture
#>
function New-TemplatePicture {
    [CmdletBinding()]
    param(
        [System.Drawing.Color]$color = [System.Drawing.Color]::FromArgb(150, 150, 150),
        [System.Drawing.Color]$textColor = [System.Drawing.Color]::FromArgb(100, 0, 0, 0),
        [string]$initials = ""
    )

    # Create a 512x512 image
    $bitmap = [System.Drawing.Bitmap]::new(512, 512)

    # Create the Graphics object through which the Bitmap is drawn to
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias   # Enable Anti-Aliasing to smooth out the edges
    $solidBrush = [System.Drawing.SolidBrush]::new($color)                      # Sets the Color for the background of the image as a Brush
    $graphics.FillRectangle($solidBrush, 0, 0, 512, 512)                            # Uses the Brush to draw a rectangle for the background

    # If there is actually text to include, draw it here
    if ($initials.Length -gt 0) {
        $font = [System.Drawing.Font]::new("Segoe UI", 128, [System.Drawing.FontStyle]::Bold)       # Sets up the font "Segoe UI", which is used by Microsoft
        $strFormat = [System.Drawing.StringFormat]::new()                                           # Creates a StringFormat
        $strFormat.Alignment = [System.Drawing.StringAlignment]::Center                             # Sets the text to Align Horizontally at the Center
        $strFormat.LineAlignment = [System.Drawing.StringAlignment]::Center                         # Sets the text to Align Vertically at the Center
        $graphics.DrawString($initials, $font, ([System.Drawing.SolidBrush]::new($textColor)), 256, 256, $strFormat)    # Draws the Text to the Image
    }

    # Returns the Image as a Bitmap
    return $bitmap
}

<#
    This function takes a 512x512 Bitmap and Applies a Cutout of a Circle onto it
#>
function ConvertTo-RoundBitmap {
    [CmdletBinding()]
    param(
        [System.Drawing.Bitmap]$bitmap
    )

    # Create a new Bitmap, deriving from the original's Size
    $destBitmap = [System.Drawing.Bitmap]::new($bitmap.Width, $bitmap.Height)
    $graphics = [System.Drawing.Graphics]::FromImage($destBitmap)   # Associate our Graphics object with the new Bitmap

    # Set the Quality and Smoothing of the Image to prevent rough, pixelated edges
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    # Create a Path that will be cut from the UI and draw it over the image to crop it into a circle.
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddEllipse(2, 2, $bitmap.Width - 6, $bitmap.Height - 6)
    $graphics.FillPath(([System.Drawing.TextureBrush]::new([System.Drawing.Image]$bitmap)), $path)
    $path.AddEllipse(0, 0, $bitmap.Width - 2, $bitmap.Height - 2)
    $graphics.DrawPath(([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(150, 0, 0, 0))), $path)

    # Return the Cutout image as a bitmap
    return $destBitmap
}

<#
    This function is used to Read a Image file from a path and import it as a System.Drawing.Image WITHOUT READ/WRITE LOCKING THE FILE.

    If this function was not put in use, temporary profile pictures would not properly delete as they are cached in Powershell's runtime until it closes

    TLDR: Very important method to load images and delete them afterwards
#>
function Import-UnlockedImage {
    [CmdletBinding()]
    param(
        [string]$imgPath
    )

    $ms = [System.IO.MemoryStream]::new([byte[]][System.IO.File]::ReadAllBytes($imgPath))
    return [System.Drawing.Image]::FromStream($ms);
}

<#
    This function uses the other Picture Functions and MsGraph to download a user's profile picture, or generate a Placeholder picture in the event they are missing one.
#>
function Get-UserPicture {
    [CmdletBinding()]
    param(
        [string]$userId = "",
        [string]$displayName = "?"
    )

    # If there is actually a user to search for, try and get their profile picture first
    if ($userId.Length -gt 0) {
        # Use MsGraph to download the picture of a user by ID to a temporary directory
        Get-MgBetaUserPhotoContent -UserId $userId -OutFile "$env:TEMP\gd_profile.png" -ErrorAction SilentlyContinue

        # If this File was created successfully, then load it onto the UI and delete it from the temporary path
        if (Test-Path -Path "$env:TEMP\gd_profile.png") {
            # Import the temporary download of the Profile Picture without Write-locking it
            $image = Import-UnlockedImage -imgPath "$env:TEMP\gd_profile.png"

            # Create a Bitmap from the image data, scaled to 512x512
            $bitmap = [System.Drawing.Bitmap]::new([System.Drawing.Bitmap]$image, ([System.Drawing.Size]::new(512, 512)))
        
            # Since we used the custom Import-UnlockedImage function, we can delete the image file after we create the $image variable
            Remove-Item -Path "$env:TEMP\gd_profile.png" -Force

            # Return the loaded image with rounded corners
            return ConvertTo-RoundBitmap -bitmap $bitmap
        }
    }

    # OTHERWISE, Create a template picture using the following information:
    
    # Get a Random Hue
    $hue = (Get-Random -Minimum 0 -Maximum 360)

    # Create a Default Background Color from the Hue
    $defColor = ConvertFrom-Hsl -Hue $hue -Saturation 100 -Lightness 85
    $defColor = [System.Drawing.Color]::FromArgb($defColor.Red, $defColor.Blue, $defColor.Green)

    # Create the Text Color from the Hue as well
    $textColor = ConvertFrom-Hsl -Hue $hue -Saturation 100 -Lightness 25
    $textColor = [System.Drawing.Color]::FromArgb($textColor.Red, $textColor.Blue, $textColor.Green)

    <#
        Breaking this down:

        0. Start with our name
            "John Doe"
        1. Split the individual words of the user's Display Name apart
            "John","Doe"
        2. For each word, replace itself with its first letter, capitalized
            "J","D"
        3. Finally, Combine them back into their Initials String
            "JD"
    #>
    $initials = ($displayName -split ' ' | ForEach-Object { ([string]$_[0]).ToUpper() }) -join ''

    # Create a Template Picture using the Initials and Colors, and then Round the corners.
    return (ConvertTo-RoundBitmap -bitmap (New-TemplatePicture -initials $initials -color $defColor -textColor $textColor))
}