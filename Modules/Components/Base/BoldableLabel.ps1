<#
    Add Type for a Custom Tab with No Border
#>
Add-Type -WarningAction "Ignore" -IgnoreWarnings -ReferencedAssemblies @("$($dependencyPath)\System.Windows.Forms.dll","$($dependencyPath)\System.ComponentModel.Primitives.dll","$($dependencyPath)\System.Windows.Forms.Primitives.dll","$($dependencyPath)\System.Drawing.Primitives.dll","$($dependencyPath)\System.Drawing.dll","$($dependencyPath)\System.Drawing.Common.dll","$($dependencyPath)\System.Private.Windows.Core.dll") -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Drawing;

public class BoldableLabel : Label
{
    public bool FlipOrder = false;

    public BoldableLabel() : base() {}
    public BoldableLabel(bool flipOrd) : base() {
        FlipOrder = flipOrd;
    }

    protected override void OnPaint(PaintEventArgs e) {
        Point drawPoint = new Point(0, 0);

        string[] ary = Text.Split(new char[] { '|' });
        if (ary.Length == 2) {
            Font normalFont = this.Font;

            Font boldFont = new Font(normalFont, FontStyle.Bold);

            Size boldSize = TextRenderer.MeasureText(ary[0], boldFont);
            Size normalSize = TextRenderer.MeasureText(ary[1], normalFont);

            Rectangle boldRect = new Rectangle(drawPoint, boldSize);
            Rectangle normalRect = new Rectangle(
                boldRect.Right, boldRect.Top, normalSize.Width, normalSize.Height);

            TextRenderer.DrawText(e.Graphics, ary[0], FlipOrder ? normalFont : boldFont, boldRect, ForeColor);
            TextRenderer.DrawText(e.Graphics, ary[1], FlipOrder ? boldFont : normalFont, normalRect, ForeColor);
        }
        else {

            TextRenderer.DrawText(e.Graphics, Text, Font, drawPoint, ForeColor);                
        }
    }
}
"@