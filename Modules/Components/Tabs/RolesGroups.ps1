[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This Tab is Dedicated to Viewing Users' Assigned Roles and Groups
#>

. "$modulePath\Components\User\Roles" -baseForm $baseForm               # Device List