<#
    Add Type for a Custom Tab with No Border
#>
Add-Type -WarningAction "Ignore" -IgnoreWarnings -ReferencedAssemblies @("$($dependencyPath)\System.Windows.Forms.dll","$($dependencyPath)\System.Windows.Forms.Primitives.dll") -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class BorderlessTabControl : NativeWindow
{
    protected override void WndProc(ref Message m)
    {
        if ((m.Msg == TCM_ADJUSTRECT))
        {
            RECT rc = (RECT)m.GetLParam(typeof(RECT));
            //Adjust these values to suit, dependant upon Appearance
            rc.Left -= 4;
            rc.Right += 4;
            rc.Top -= 3;
            rc.Bottom += 3;
            Marshal.StructureToPtr(rc, m.LParam, true);
        }
        base.WndProc(ref m);
    }

    private const Int32 TCM_FIRST = 0x1300;
    private const Int32 TCM_ADJUSTRECT = (TCM_FIRST + 40);
    private struct RECT
    {
        public Int32 Left;
        public Int32 Top;
        public Int32 Right;
        public Int32 Bottom;
    }
}
"@

<#
    Function to easily add a new page to the TabControl using a Name and Script
#>
function Add-TabPage {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.TabControl]$tabControl,

        [Parameter(Mandatory = $true)]
        [string]$tabName,

        [Parameter(Mandatory = $true)]
        [string]$tabScript
    )

    $newForm = [System.Windows.Forms.TabPage]::new($tabName)
    $tabControl.TabPages.Add($newForm)

    Add-DividerLine -baseForm $newForm -dividerLocation ([System.Drawing.Point]::new(0, 8)) -dividerSize 380

    . "$tabScript" -baseForm $newForm
}