[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<#
    This Tab is used to Display the list of Changes made to/by this account
#>

. "$modulePath\Components\User\AuditsTo" -baseForm $baseForm                # Audits Affecting this Account

Add-DividerLine -baseForm $baseForm -dividerLocation ([System.Drawing.Point]::new(0, 244)) -dividerSize 380

. "$modulePath\Components\User\AuditsInitiatedBy" -baseForm $baseForm       # Audits Caused by this Account