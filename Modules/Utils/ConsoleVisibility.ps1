$signature = @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
}
"@
Add-Type -WarningAction "Ignore" -IgnoreWarnings $signature

# Get console window handle
$consolePtr = [Win32]::GetConsoleWindow() #(Get-Process -Id $PID).MainWindowHandle

function Hide-Console {
    [CmdletBinding()]
    Param()
    [Win32]::ShowWindow($consolePtr, 0) | Out-Null   # 0 = SW_HIDE
}

function Show-Console {
    [CmdletBinding()]
    Param()
    [Win32]::ShowWindow($consolePtr, 5) | Out-Null   # 5 = SW_SHOW
}

function Switch-ConsoleVisible {
    [CmdletBinding()]
    Param()
    if ([Win32]::IsWindowVisible($consolePtr)) {
        [Win32]::ShowWindow($consolePtr, 0) | Out-Null
    } else {
        [Win32]::ShowWindow($consolePtr, 5) | Out-Null
    }
}