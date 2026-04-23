<#
    EventCallbacks is a Module which adds support for Asynchronous Callbacks for simulated Multi-Threading on WinForms

    These functions allow for Code to be run whilst the Main Thread is Locked by WinForm.ShowDialog()

    They also allow for code to be run after an Async Job is completed, including Clean-Up Afterwards.
#>
$global:pg_EventRegistry = @{}
$global:pg_JobRegistry = [System.Collections.ArrayList]::new()
$global:pg_ProgressTotal = 0
$global:pg_ProgressCurrent = 0

<#
    This Function Sets up a Callback Function, associating the ScriptBlock with a friendly Name
#>
function Register-EventCallback {
    [CmdletBinding()]
    Param(
        [string]$EventName,
        [ScriptBlock]$Callback
    )
    if (-not $global:pg_EventRegistry.ContainsKey($EventName)) {
        $global:pg_EventRegistry[$EventName] = @()
    }
    $global:pg_EventRegistry[$EventName] += $Callback
}

<#
    This Function runs all ScriptBlocks with the same friendly name that is passed through itself
#>
function Send-EventCallback {
    [CmdletBinding()]
    Param(
        [string]$EventName,
        [Parameter(ValueFromRemainingArguments = $true)]
        $Args
    )
    if ($global:pg_EventRegistry.ContainsKey($EventName)) {
        foreach ($callback in $global:pg_EventRegistry[$EventName]) {
            & $callback @Args
        }
    }
}

<#
    This Function will attach a Callback ScriptBlock to run after an Asynchronous Job is completed
#>
function Register-JobCompletion {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Job] $Job,

        [Parameter(Mandatory)]
        [ScriptBlock] $JobCb,

        [System.Object] $UserPassthrough = $null
    )

    # This is used to Track the Upper-Right Progress Bar for Asynchronous Tasks
    $global:pg_ProgressTotal += 1
    $global:pg_JobRegistry.Add($Job)

    # Register the Object Event for Job Completion
    Register-ObjectEvent -InputObject $Job -EventName StateChanged -MessageData $UserPassthrough,$JobCb -Action {
        $state = $Event.SourceEventArgs.JobStateInfo.State
        if ($state -eq 'Completed' -or $state -eq 'Failed' -or $state -eq 'Stopped') {
            #Write-Host "Job $($Event.Sender.Id) completed with state: $state"

            $result = Receive-Job -Job $Event.Sender

            & $Event.MessageData[1] $Event.MessageData[0] $result

            # Increment the Progress Counter
            $global:pg_ProgressCurrent += 1
            if ($global:pg_EventRegistry.ContainsKey("UpdateProgress")) {
                foreach ($callback in $global:pg_EventRegistry["UpdateProgress"]) {
                    & $callback
                }
            }

            # Clean up
            Unregister-Event -SourceIdentifier $Event.SourceIdentifier
            Remove-Job -Job $Event.Sender -Force
            $global:pg_JobRegistry.Remove($Event.Sender)
        }
    }
    Send-EventCallback -EventName "UpdateProgress"
}

<#
    This Function will cancel any incomplete Jobs, which will help prevent incorrect data showing on rapid requests
#>
function Disconnect-AllJobs {
    $allJobs = [System.Collections.ArrayList]::new()
    foreach ($job in $global:pg_JobRegistry) {
        $allJobs.Add($job)
    }
    foreach ($job in $allJobs) {
        Stop-Job -Job $job
    }
    $global:pg_JobRegistry = [System.Collections.ArrayList]::new()
}
function Clear-AllJobs {
    Disconnect-AllJobs
    Clear-Variable -Scope Global -Name "pg_JobRegistry"
    Clear-Variable -Scope Global -Name "pg_ProgressTotal"
    Clear-Variable -Scope Global -Name "pg_ProgressCurrent"
    Clear-Variable -Scope Global -Name "pg_EventRegistry"
}

<#
    This Function resets the Total Progress Stored in the Upper Right Progress Bar
#>
function Reset-ProgressBar {
    $global:pg_ProgressTotal = 0
    $global:pg_ProgressCurrent = 0
    Send-EventCallback -EventName "UpdateProgress"
}