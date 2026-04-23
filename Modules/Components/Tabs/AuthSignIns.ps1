[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This Tab is Dedicated to Viewing Users' Authentication Methods and Recent Sign-In Attempt History
#>

. "$modulePath\Components\User\SignInHistory" -baseForm $baseForm               # Sign In History Log

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(0, 244)) -dividerSize 380

. "$modulePath\Components\User\AuthenticationMethods" -baseForm $baseForm       # Authentication Method List