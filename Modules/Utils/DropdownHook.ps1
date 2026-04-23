$signature = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    public const int WM_SYSCOMMAND = 0x112;
    public const int MF_STRING = 0x0;
    public const long MF_CHECKED = 0x00000008L;
    
    public const int MF_SEPARATOR = 0x800;

    [DllImport("user32.dll")]
    public static extern IntPtr GetSystemMenu(IntPtr hWnd, bool bRevert);

    [DllImport("user32.dll")]
    public static extern bool AppendMenu(IntPtr hMenu, int uFlags, int uIDNewItem, string lpNewItem);
}
"@

Add-Type -WarningAction "Ignore" -IgnoreWarnings $signature