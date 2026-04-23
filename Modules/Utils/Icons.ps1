# Add Win32 API Functions
Add-Type -AssemblyName System.Drawing
Add-Type -Namespace Win32API -Name Icon -MemberDefinition @'
    [DllImport("Shell32.dll", SetLastError=true)]
    public static extern int ExtractIconEx(string lpszFile, int nIconIndex, out IntPtr phiconLarge, out IntPtr phiconSmall, int nIcons);
 
    [DllImport("gdi32.dll", SetLastError=true)]
    public static extern bool DeleteObject(IntPtr hObject);
'@

# https://www.powershellgallery.com/packages/IconForGUI/1.5.2/Content/IconForGUI.psm1
Function Get-IconFromFile {
    [CmdletBinding()]
    Param(
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias("FullName")]
        [String[]]$Path,

        [Parameter(Position = 1)]
        [Int]$Index = 0,

        [Switch]$LargeIcon
    )

    Process {
        foreach ($p in $Path) {
            #Initialize variables for reference conversion
            $large, $small = 0, 0

            #Call Win32 API Function for handles
            [Win32API.Icon]::ExtractIconEx($p, $Index, [ref]$large, [ref]$small, 1) | Out-Null

            #If large icon desired store large handle, default to small handle
            $handle = if ($LargeIcon) { $large } else { $small }
    
            #Get the icon from the handle
            if ($handle) {
                [System.Drawing.Icon]::FromHandle($handle)
            }

            #If the handles are valid, delete them for good memory practice
            $large, $small, $handle | Where-Object { $_ } | ForEach-Object { [Win32API.Icon]::DeleteObject($_) } | Out-Null
        }
    }
}

# This function converts a System Icon to a usable size
function Convert-Icon-16 {
    [CmdletBinding()]
    param(
        [System.Drawing.Bitmap]$bitmapImage,
        [int]$leftPadding = 0
    )
    # Create a new bitmap with the desired dimensions
    $resizedImage = [System.Drawing.Bitmap]::new(($leftPadding + 16), 16)

    # Create a graphics object to perform the resizing
    $graphics = [System.Drawing.Graphics]::FromImage($resizedImage)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($bitmapImage, $leftPadding, 0, 16, 16)
    $graphics.Dispose()
    return $resizedImage
}