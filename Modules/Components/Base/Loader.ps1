[CmdletBinding()]
Param()

<#
    This Module Handles all of the Visuals behind the Spinning Wheel shown when loading information

    This is Oddly a VERY Important Script Because it Re-Enables Multithreading when a WinForm is shown on the Main Thread
#>
$global:pg_loaderSpinners = [System.Collections.ArrayList]@()                              # A list of every Spinning Wheel so that it can be updated to display the new image
$global:pg_loaderBitmap = [System.Drawing.Bitmap]::new(512, 512)                       # The Image displayed on every Wheel
$global:pg_loaderGraphics = [System.Drawing.Graphics]::FromImage($global:pg_loaderBitmap)     # The Graphics Object associated with the Image

$bSize = 512                                                                            # The Size in Pixels associated with the Image

<#
    This is Specifically Code to Create a Circular Path for drawing the Spinning Wheel
#>
$global:pg_loaderPath = [System.Drawing.Drawing2D.GraphicsPath]::new()
$global:pg_loaderPath.AddArc([System.Drawing.Rectangle]::new(0, 0, $bSize, $bSize), 180, 90)
$global:pg_loaderPath.AddArc([System.Drawing.Rectangle]::new(512 - $bSize, 0, $bSize, $bSize), -90, 90)
$global:pg_loaderPath.AddArc([System.Drawing.Rectangle]::new(512 - $bSize, 512 - $bSize, $bSize, $bSize), 0, 90)
$global:pg_loaderPath.AddArc([System.Drawing.Rectangle]::new(0, 512 - $bSize, $bSize, $bSize), 90, 90)

<#
    This is done to help support the Color Mixing Mode
#>
$global:pg_loaderGraphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy

$global:pg_loaderAngle = 45                                        # This is the Angle in Degrees of the Rotating Wheel
    
$global:pg_loaderTimer = [System.Windows.Forms.Timer]::new()       # This is the Timer that keeps updating the Image
$global:pg_loaderTimer.Interval = 30                               # This interval is set to update every 30 milliseconds
$global:pg_loaderTimer.Enabled = $true                             # Activates the Timer

# When the Timer's Interval has passed
$global:pg_loaderTimer.add_Tick({
        # Rotate the Wheel slightly
        $global:pg_loaderAngle = ($global:pg_loaderAngle % 360) + 5

        # Draw the Gradient over the Circle
        $newGrad = [System.Drawing.Drawing2D.LinearGradientBrush]::new([System.Drawing.Rectangle]::new(0, 0, 512, 512), [System.Drawing.Color]::FromArgb(150, 150, 150), [System.Drawing.Color]::FromArgb(0, 0, 0), $global:pg_loaderAngle)
        $newColorBlend = [System.Drawing.Drawing2D.ColorBlend]::new()
        $newColorBlend.Positions = @(0, 0.66, 1)
        $newColorBlend.Colors = @([System.Drawing.Color]::FromArgb(175, 175, 175), [System.Drawing.Color]::FromArgb(0, 0, 0, 0), [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
        $newGrad.InterpolationColors = $newColorBlend

        # Draw the Path and Create the Loading Cutout
        $global:pg_loaderGraphics.FillPath($newGrad, ($global:pg_loaderPath))
        $global:pg_loaderGraphics.FillEllipse(([System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(0, 50, 50, 50))), [System.Drawing.Rectangle]::new(48, 48, 512 - 96, 512 - 96))
    
        # Replace the Image on every Spinning Wheel
        foreach ($imgBox in $global:pg_loaderSpinners) {
            $imgBox.Image = $global:pg_loaderBitmap
        }
    })
 
<#
    Properly Starts the Timer's Ticking
#>
$global:pg_loaderTimer.Start()

<#
    This will Set Up a basic Spinning Wheel for Use
#>
function Build-LoadingSpinner {
    $loadControl = [System.Windows.Forms.PictureBox]::new()
    $loadControl.Size = [System.Drawing.Size]::new(32, 32)
    $loadControl.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom

    $global:pg_loaderSpinners.Add($loadControl) | Out-Null

    return $loadControl
}

<#
     This Function will Automatically Center the Spinning Wheel on an Element
#>
function Move-LoaderToCenter {
    param (
        [System.Windows.Forms.PictureBox] $loadControl,
        [System.Windows.Forms.Control] $controlToCenter
    )

    $xPos = $controlToCenter.Location.X + ($controlToCenter.Size.Width/2) - 16
    $yPos = $controlToCenter.Location.Y + ($controlToCenter.Size.Height/2) - 16

    $loadControl.Location = [System.Drawing.Point]::new($xPos,$yPos)
}

<#
    This Function is used to Properly dispose of the Timer and prevent residual garbage from remaining after script execution
#>
function Disconnect-Loader {
    $global:pg_loaderTimer.Dispose()
    Clear-Variable -Scope Global -Name "pg_loaderTimer"
    Clear-Variable -Scope Global -Name "pg_loaderSpinners"
    Clear-Variable -Scope Global -Name "pg_loaderBitmap"
    Clear-Variable -Scope Global -Name "pg_loaderGraphics"
    Clear-Variable -Scope Global -Name "pg_loaderPath"
    Clear-Variable -Scope Global -Name "pg_loaderAngle"
}