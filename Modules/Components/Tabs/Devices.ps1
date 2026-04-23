[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This Tab is Dedicated to Viewing Computers and Devices related to a Specific User
#>

. "$modulePath\Components\User\DeviceList" -baseForm $baseForm               # Device List