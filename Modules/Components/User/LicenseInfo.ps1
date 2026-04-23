[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [System.Windows.Forms.Control]$baseForm
)

<# 
    7. License and Subscription Information (Get-MgUserLicenseDetail)

    Retrieve: skuPartNumber, disabledPlans.
#>

<#
    This is the Label for the Account Details Section, shown just below the Display Profile
#>
$header = [System.Windows.Forms.Label]::new()
$header.Location = [System.Drawing.Point]::new(15, 305)
$header.Size = [System.Drawing.Size]::new(250, 24)
$header.Font = [System.Drawing.Font]::new($header.Font.FontFamily, 12, [System.Drawing.FontStyle]::Bold)
$header.Text = "Licenses"

<#
    This is the TreeView for the License Data. Tree Views are drop-down lists akin to a File Browser
#>
$treeView = [System.Windows.Forms.TreeView]::new()
$treeView.Location = [System.Drawing.Point]::new(15, 330)
$treeView.Size = [System.Drawing.Size]::new(265, 220)

<#
    This isn't THAT important, but TreeViews support Icons, so this is a small list of Icons taken from Windows' System32 DLLs
#>
$imgList = [System.Windows.Forms.ImageList]::new()
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\dsuiext.dll" -Index 29))      # Certificate   0
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 230))    # Disabled      1
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 233))    # Enabled       2
$imgList.Images.Add((Get-IconFromFile -Path "$env:SystemRoot\System32\imageres.dll" -Index 77))     # Key           3
$treeView.ImageList = $imgList

<#
    This is the Callback for A User's Information being retrieved, including a reference to the User's Information
#>
Register-EventCallback -EventName "GetUser" -Callback {
    param($user)

    # Load the TreeView back into our ScriptContext
    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "licenseInfo" -variableName "treeView")

    # Update the Tree to be cleared of all data
    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    # Start an Asynchronous Job to Fetch the License Information associated with the User Found by the original Query
    $job = Start-ThreadJob -ScriptBlock {
        param($userId)

        Get-MgBetaUserLicenseDetail -UserId $userId
    } -ArgumentList $user.id

    # Once the License Query is Complete, Fill the table with data.
    Register-JobCompletion -Job $job -UserPassthrough $user -JobCb {
        param($user, $detail)

        # Hide the spinning wheel
        $baseForm.Controls.Remove((Get-Component -relationName "licenseInfo" -variableName "spinner"))

        # Make sure that there was actual data received by the Job
        if ($null -ne $detail) {
            # Load the TreeView back into our ScriptContext (again...)
            $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "licenseInfo" -variableName "treeView")

            # Start an Update to the List, and Clear any data that for some reason might be there
            $treeView.BeginUpdate()
            $treeView.Nodes.Clear()
            
            # Create a Root node for "Licenses" with a Certificate Icon
            $licenseDetailNode = [System.Windows.Forms.TreeNode]::new("Licenses", 0, 0)
            $treeView.Nodes.Add($licenseDetailNode)

            # Hashtable for Getting Disabled Plans relative to License ID
            $skuToDisabledPlans = @{}
            foreach ($plan in $user.assignedLicenses) {
                $skuToDisabledPlans[$plan.skuId] = $plan.disabledPlans
            }
            # Hashtable for Converting Plan ID to Plan
            $planIdHashtable = @{}
            foreach ($plan in $user.assignedPlans) {
                $planIdHashtable[$plan.servicePlanId] = $plan
            }

            # Loop through all of the License Information from the Request
            foreach ($license in $detail) {
                # Create This License's Root Node
                $licenseNode = [System.Windows.Forms.TreeNode]::new($license.skuPartNumber, 0, 0)
                $licenseDetailNode.Nodes.Add($licenseNode)

                # Add the ID as a Child Node
                $licenseNode.Nodes.Add([System.Windows.Forms.TreeNode]::new($license.skuId, 3, 3))

                # If there are Plans Disabled by this License, include a dropdown to view them
                if ($skuToDisabledPlans[$license.skuId].Count -gt 0) {
                    # Create the Child Node for Disabled Plans
                    $disabledPlansNode = [System.Windows.Forms.TreeNode]::new("Disabled Plans", 1, 1)
                    $licenseNode.Nodes.Add($disabledPlansNode)

                    # For each plan disabled by this license
                    foreach ($disabledId in $skuToDisabledPlans[$license.skuId]) {
                        # Create a new Disabled Plan Child Node
                        $disabledNode = [System.Windows.Forms.TreeNode]::new($planIdHashtable[$disabledId].service, 0, 0)
                        $disabledPlansNode.Nodes.Add($disabledNode)

                        $disabledNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Assigned: $($planIdHashtable[$disabledId].assignedDateTime)", 99, 99))
                        $disabledNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($planIdHashtable[$disabledId].servicePlanId)", 3, 3))
                    }
                }
            }

            # Loop through the Active Plans returned from the original User Beta Query
            $activeNode = [System.Windows.Forms.TreeNode]::new("Assigned Plans", 0, 0)
            $treeView.Nodes.Add($activeNode)
            foreach ($plan in $user.assignedPlans) {
                # Create the Root Child Node for the Plan, and change the icon to show whether it is Enabled or Disabled
                $evNode = [System.Windows.Forms.TreeNode]::new($plan.service, ($plan.capabilityStatus -eq "Enabled") ? 2 : 1, ($plan.capabilityStatus -eq "Enabled") ? 2 : 1)
                $activeNode.Nodes.Add($evNode)

                # Add the Status, Assigned Date, and ID to the Root Child
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Status: $($plan.capabilityStatus)", 99, 99))
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("Assigned: $($plan.assignedDateTime)", 99, 99))
                $evNode.Nodes.Add([System.Windows.Forms.TreeNode]::new("$($plan.servicePlanId)", 3, 3))
            }

            # Finish Updating the TreeView and Re-add it to the Window
            $treeView.EndUpdate()
            $treeView.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255)
        }
    }
}

<#
    This is the Callback for preparing the elements for the loading time while the user waits for their information to be found
#>
Register-EventCallback -EventName "AwaitData" -Callback {
    <#
        Clear out the data from the TreeView
    #>
    $treeView = [System.Windows.Forms.TreeView](Get-Component -relationName "licenseInfo" -variableName "treeView")
    $treeView.BeginUpdate()
    $treeView.Nodes.Clear()
    $treeView.EndUpdate()

    # Set the TreeView's background color to gray
    $treeView.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)

    <#
        Show the Loading Spinner and Bring it to the front of the Form
    #>
    $baseForm.Controls.Add((Get-Component -relationName "licenseInfo" -variableName "spinner"))
    (Get-Component -relationName "licenseInfo" -variableName "spinner").BringToFront()
}

<#
    Add all of the License Info - Related Elements to the Form at the start
#>
$baseForm.Controls.Add($header)
$baseForm.Controls.Add($treeView)

<#
    Register all of the Components to be referenced later in the respective callbacks
#>
Register-Component -relationName "licenseInfo" -variableName "treeView" -valueOfVar $treeView

<#
    Create a Loading Spinner for this part of the Winform
#>
$spinner = Build-LoadingSpinner
Move-LoaderToCenter -loadControl $spinner -controlToCenter $treeView
Register-Component -relationName "licenseInfo" -variableName "spinner" -valueOfVar $spinner