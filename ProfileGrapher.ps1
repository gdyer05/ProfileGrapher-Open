<#
    Paths
#>
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope='Function')]
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "Modules"
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope='Function')]
$dependencyPath = Join-Path -Path $PSScriptRoot -ChildPath "Dependencies"

<# 
    Add Types
#>
Add-Type -AssemblyName System.Windows.Forms
Add-Type -Path "$dependencyPath\Markdig.dll"

<#
    Load Project JSON
#>
$global:pg_projectJson = (Get-Content -Path "$PSScriptRoot\project.json" -Raw | ConvertFrom-Json -AsHashtable)

<#
    Modules
#>
. "$modulePath\Utils\AppHook"                     # Functions to assign Custom Dynamic App IDs to Powershell Forms
. "$modulePath\Utils\ConsoleVisibility"
. "$modulePath\Utils\DropdownHook"
. "$modulePath\Utils\Icons"                     # Functions used to convert DLL paths to Image Icons
. "$modulePath\Utils\ComponentStorage"          # Handles Components across Powershell Jobs/Asynchronous Tasks
. "$modulePath\Utils\EventCallbacks"            # Handles Receiving Information and Executing Scripts after Graph Requests
. "$modulePath\Utils\PictureFunctions"          # Useful functions for handling image-related components
. "$modulePath\Utils\PowershellVersion"         # Used to Enforce Specific Run Conditions in Powershell
. "$modulePath\Utils\GetUserData"               # Used for Quicker Batch-Based Fetching of User Data in a continuous stream

<#
    Force the User to Use Powershell 7+ in order to avoid the Broken Sign-In Window issue with Powershell 5
#>
Assert-PowershellSeven

<#
    Load the Launcher Window
#>
. "$modulePath\Components\Windows\Launcher"
if ($null -eq $global:pg_userPermissions) {
    Exit
}

<#
    Graph Dependencies
#>
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Users"
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Users.Functions"
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Identity.SignIns"
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Identity.Governance"
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Reports"
Import-ModuleExtended -Name "Microsoft.Graph.Beta.Identity.DirectoryManagement"

<#
    Connect User to Graph
#>
Connect-MgGraph -NoWelcome -Scopes $global:pg_userPermissions
if ($null -eq (Get-MgContext)) {
    Disconnect-Loader
    Clear-Variable -Scope Global -Name "pg_userPermissions"
    Clear-Variable -Scope Global -Name "pg_projectJson"
    Get-EventSubscriber | Unregister-Event
    Get-Job | Remove-Job -Force
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    Exit
}

<#
    Load the Main Window
#>
. "$modulePath\Components\Windows\MainWindow"

<#
    Garbage Collection
#>
Disconnect-Loader
Clear-ComponentCache
Clear-AllJobs
Clear-Variable -Scope Global -Name "pg_userPermissions"
Clear-Variable -Scope Global -Name "pg_projectJson"
Get-EventSubscriber | Unregister-Event
Get-Job | Remove-Job -Force
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()
[System.GC]::Collect()