[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This Tab is Dedicated to Viewing Users' Risk Events
#>
. "$modulePath\Components\User\RiskOverview"    -baseForm $baseForm               # Risk Overview

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(0, 95)) -dividerSize 380

. "$modulePath\Components\User\FlaggedActivity" -baseForm $baseForm               # Risk History