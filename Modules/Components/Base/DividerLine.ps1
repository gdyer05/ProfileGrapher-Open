<#
    This Element is a Simple Horizontal or Vertical Line used to divide information into sections
#>
function Add-DividerLine {
    [CmdletBinding()]
    Param(
        [System.Windows.Forms.Control]$baseForm,
        [System.Drawing.Point]$dividerLocation,
        [int]$dividerSize,
        [Switch]$isVertical
    )

    $divider = [System.Windows.Forms.Label]::new()
    $divider.BorderStyle = "Fixed3D"
    $divider.Location = $dividerLocation
    $divider.Size = [System.Drawing.Size]::new($dividerSize, 2)
    if ($isVertical) {
        $divider.Size = [System.Drawing.Size]::new(2, $dividerSize)
    }

    $baseForm.Controls.Add($divider)
}