<#
    Microsoft Graph's SDK Technically Works on Powershell 5, the default powershell installed with Windows

    This does not include the sign-in window. In order to support both MS Graph and Newer Conventions, this Function forces the user to use Powershell 7

    If the user does not have Powershell 7, then it will provide then with the Installer
#>
function Assert-PowershellSeven {
    [CmdletBinding()]
    Param()
    
    # If Powershell Runtime's Version is Below 7.0.0
    if (($PSVersionTable.PSVersion | Select-Object Major).Major -lt 7) {
        # Then Get the Full Length Version String
        $normalVersion = ($PSVersionTable.PSVersion | Select-Object Major, Minor, Build)
        $fancyVersion = [string]$normalVersion.Major + "." + [string]$normalVersion.Minor + "." + [string]$normalVersion.Build

        # ...and Show a WShell Popup prompting the user to run the script using Powershell 7, offering an installer as well.
        $wshell = New-Object -ComObject Wscript.Shell
        $Output = $wshell.Popup("Powershell Needs Version 7+ (Found $fancyVersion) `n `n Press Ok to Download the Latest Installer from Github.", 0, "Done", 0x1)
        if ($Output -eq 1) {
            [System.Diagnostics.Process]::Start(((Invoke-RestMethod -Uri (Invoke-RestMethod -Uri https://api.github.com/repos/PowerShell/PowerShell/releases/latest).assets_url).browser_download_url -match "https:\/\/github\.com\/PowerShell\/PowerShell\/releases\/download\/.*\/PowerShell-.*-win-x64\.msi")[0])
        }
        exit;
    }
}

<#
    This Function Automatically Elevates a Script to be Run as Administrator

    It WILL restart the script from the beginning, so it is best used sparingly.
#>
function Assert-Administrator {
    [CmdletBinding()]
    Param()

    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        # NOTE: This version of the Assert-Administrator Command ONLY Supports Powershell 7, as you can only launch 7 using "pwsh" and launch 5 using "powershell"
        $newProcess = New-Object System.Diagnostics.ProcessStartInfo "pwsh";
        $newProcess.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`"";
        $newProcess.Verb = "runAs";
        $newProcess.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($newProcess) | Out-Null;
        exit;
    }
}

<#
    Load Module With Auto-Install
#>
function Import-ModuleExtended {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$ReqVersion
    )

    if ((Get-Module -Name $Name)) {
        if ([string]::IsNullOrWhiteSpace($ReqVersion) -or (Get-Module -Name $Name).Version -eq $ReqVersion) {
            return
        }
    }

    # Check for Specific Version because Microsoft really does not like letting you get SPECIFIC VERSIONS.
    $found = $false
    foreach ($mod in (Get-Module -ListAvailable -Name $Name)) {
        if (-not [string]::IsNullOrWhiteSpace($ReqVersion)) {
            if ($mod.Version -eq $ReqVersion) {
                $found = $true
                Import-Module -Name $Name -RequiredVersion $ReqVersion -Force
                return
            }
        } else {
            $found = $true
            Import-Module -Name $Name -Force
            return
        }
    }

    if (-not $found) {
        if (-not [string]::IsNullOrWhiteSpace($ReqVersion)) {
            Install-Module -Name $Name -RequiredVersion $ReqVersion -Force
            Import-Module -Name $Name -RequiredVersion $ReqVersion -Force
        } else {
            Install-Module -Name $Name -Force
            Import-Module -Name $Name -Force
        }
    }
}