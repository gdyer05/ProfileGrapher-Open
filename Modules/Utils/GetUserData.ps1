function Get-FullUserData {
    [CmdletBinding()]
    Param(
        [string] $userPrincipalName,
        [bool] $getAccountDetails = $false,
        [bool] $getLicenses = $false,
        [bool] $getDevices = $false,
        [bool] $getRolesGroups = $false,
        [bool] $getAuthenticationMethods = $false,
        [bool] $getRiskStatus = $false
    )

    $outInfo = [PSCustomObject]@{
        Name                  = $null
        UserPrincipalName     = $userPrincipalName
        UserId                = $null

        AccountDetails        = $null
        Licenses              = $null
        Devices               = $null
        RolesGroups           = $null
        AuthenticationMethods = $null
        RiskStatus            = $null
    }

    # 1. Get User Data and Account Details
    $getUser = (Get-MgBetaUser -Filter "userPrincipalName eq '$($userPrincipalName)'" | Select-Object -First 1)
    $outInfo.Name = $getUser.displayName
    $outInfo.UserId = $getUser.id
    if ($getAccountDetails) {
        $outInfo.AccountDetails = [PSCustomObject]@{
            AccountEnabled               = $getUser.accountEnabled
            CreationDate                 = $getUser.createdDateTime
            UserType                     = $getUser.userType
            OnPremisesSyncEnabled        = $getUser.onPremisesSyncEnabled
            OnPremisesSecurityIdentifier = $getUser.onPremisesSecurityIdentifier
            OnPremisesLastSyncDateTime   = $getUser.onPremisesLastSyncDateTime
        }
    }

    # 2. Get Licenses
    if ($getLicenses) {
        $allLics = (Get-MgBetaUserLicenseDetail -UserId $getUser.id)
        if ($null -ne $allLics) {
            $outInfo.Licenses = @{}
            foreach ($license in $allLics) {
                $outInfo.Licenses[$license.skuPartNumber] = $license.skuId
            }
            $outInfo.Licenses = [PSCustomObject]$outInfo.Licenses
        }
    }

    # 3. Get Devices
    if ($getDevices) {
        $allDevices = (Get-MgBetaUserRegisteredDevice -UserId $getUser.id)
        if ($null -ne $allDevices) {
            $outInfo.Devices = @{}
            foreach ($device in $allDevices) {
                $outInfo.Devices[$device["deviceId"]] = [PSCustomObject]@{
                    Name               = $device["displayName"]
                    Id                 = $device["deviceId"]
                    Model              = $device["model"]
                    OperatingSystem    = $device["operatingSystem"]
                    LastSignInDateTime = $device["approximateLastSignInDateTime"]
                    IsManaged          = $device["isManaged"]
                    IsCompliant        = $device["isCompliant"]
                }
            }
            $outInfo.Devices = [PSCustomObject]$outInfo.Devices
        }
    }

    # 4. Get Roles/Groups
    if ($getRolesGroups) {
        $allGroups = (Get-MgBetaUserMemberOf -UserId $getUser.id)
        if ($null -ne $allGroups) {
            $outInfo.RolesGroups = @{}
            foreach ($roleGroup in $allGroups) {
                $outInfo.RolesGroups[$roleGroup.Id] = [PSCustomObject]@{
                    Name            = ($null -ne $roleGroup["displayName"] ? $roleGroup["displayName"] : "[Directory Role]")
                    IsDirectoryRole = $roleGroup["@odata.type"] -eq "#microsoft.graph.directoryRole"
                    CreatedDateTime = $roleGroup["createdDateTime"]
                    Id              = $roleGroup.Id
                    Description     = $roleGroup["description"]
                }
            }
            $outInfo.RolesGroups = [PSCustomObject]$outInfo.RolesGroups
        }
    }

    # 5. Get Authentication Methods
    if ($getAuthenticationMethods) {
        $allAuthMethods = (Get-MgBetaUserAuthenticationMethod -UserId $getUser.id)
        if ($null -ne $allAuthMethods) {
            $outInfo.AuthenticationMethods = @{}
            foreach ($auth in $allAuthMethods) {
                $outInfo.AuthenticationMethods[$auth.Id] = [PSCustomObject]@{
                    Name            = ($null -ne $auth["displayName"] ? $auth["displayName"] : "Unknown Name")
                    Type            = ($auth['@odata.type'] -replace '^#microsoft\.graph\.', '' -replace 'AuthenticationMethod$', '')
                    CreatedDateTime = $auth['createdDateTime']
                    Id              = $auth.Id
                }
            }
            $outInfo.AuthenticationMethods = [PSCustomObject]$outInfo.AuthenticationMethods
        }
    }

    # 6. Get Risk Status
    if ($getRiskStatus) {
        $riskInfo = (Get-MgBetaRiskyUser -Top 1 -Filter "UserPrincipalName eq '$userId'")
        if ($null -ne $riskInfo) {
            $outInfo.RiskStatus = [PSCustomObject]@{
                Level               = $riskLog.RiskLevel
                LastUpdatedDateTime = $riskLog.RiskLastUpdatedDateTime
                State               = $riskLog.RiskState
                Detail              = $riskLog.RiskDetail
            }
        }
    }

    # Return
    return $outInfo
}

function Convert-UserDataToSpreadsheet {
    [CmdletBinding()]
    Param(
        [PSCustomObject] $userInfo,
        [string] $outputPath,
        [Switch] $individualCsvFiles
    )

    $tempFolder = "$($env:TEMP)\ProfileExport"
    if (-not ((Test-Path -Path $tempFolder) -or $individualCsvFiles)) {
        New-Item -Path  $tempFolder -ItemType Directory
    }
    
    # 1. Account Details
    #    $userInfo.Name
    #    $userInfo.UserPrincipalName
    #    $userInfo.UserId
    #    $userInfo.AccountDetails = [PSCustomObject]@{
    #        AccountEnabled               = $getUser.accountEnabled
    #        CreationDate                 = $getUser.createdDateTime
    #        UserType                     = $getUser.userType
    #        OnPremisesSyncEnabled        = $getUser.onPremisesSyncEnabled
    #        OnPremisesSecurityIdentifier = $getUser.onPremisesSecurityIdentifier
    #        OnPremisesLastSyncDateTime   = $getUser.onPremisesLastSyncDateTime
    #    }
    if ($null -ne $userInfo.AccountDetails) {
        $accDetails = [System.Collections.ArrayList]::new()
        $accDetails.Add([PSCustomObject]@{
                Name                         = $userInfo.Name
                UserPrincipalName            = $userInfo.UserPrincipalName
                UserId                       = $userInfo.UserId
                AccountEnabled               = $userInfo.AccountDetails.AccountEnabled
                CreationDate                 = $userInfo.AccountDetails.CreationDate
                UserType                     = $userInfo.AccountDetails.UserType
                OnPremisesSyncEnabled        = $userInfo.AccountDetails.OnPremisesSyncEnabled
                OnPremisesSecurityIdentifier = $userInfo.AccountDetails.OnPremisesSecurityIdentifier
                OnPremisesLastSyncDateTime   = $userInfo.AccountDetails.OnPremisesLastSyncDateTime
            })

        $accDetails | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-AccountDetails.csv" : "$tempFolder\AccountDetails.csv") -Force
    }

    # 2. Licenses
    if ($null -ne $userInfo.Licenses) {
        $licenses = [System.Collections.ArrayList]::new()
        foreach ($lic in $userInfo.Licenses.PSObject.Properties) {
            $licenses.Add([PSCustomObject]@{
                    Name = $lic.Name
                    Id   = $lic.Value
                })
        }
        $licenses | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-Licenses.csv" : "$tempFolder\Licenses.csv") -Force
    }

    # 3. Devices
    #Name               = $device["displayName"]
    #Id                 = $device["deviceId"]
    #Model              = $device["model"]
    #OperatingSystem    = $device["operatingSystem"]
    #LastSignInDateTime = $device["approximateLastSignInDateTime"]
    #IsManaged          = $device["isManaged"]
    #IsCompliant        = $device["isCompliant"]
    if ($null -ne $userInfo.Devices) {
        $devices = [System.Collections.ArrayList]::new()
        foreach ($dev in $userInfo.Devices.PSObject.Properties) {
            $devices.Add($dev.Value)
        }
        $devices | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-Devices.csv" : "$tempFolder\Devices.csv") -Force
    }

    # 4. Roles and Groups
    #Name            = ($null -ne $roleGroup["displayName"] ? $roleGroup["displayName"] : "[Directory Role]")
    #IsDirectoryRole = $roleGroup["@odata.type"] -eq "#microsoft.graph.directoryRole"
    #CreatedDateTime = $roleGroup["createdDateTime"]
    #Id              = $roleGroup.Id
    #Description     = $roleGroup["description"]
    if ($null -ne $userInfo.RolesGroups) {
        $rolesGroups = [System.Collections.ArrayList]::new()
        foreach ($role in $userInfo.RolesGroups.PSObject.Properties) {
            $rolesGroups.Add($role.Value)
        }
        $rolesGroups | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-RolesGroups.csv" : "$tempFolder\RolesGroups.csv") -Force
    }

    # 5. Authentication Methods
    #Name            = ($null -ne $auth["displayName"] ? $auth["displayName"] : "Unknown Name")
    #Type            = ($auth['@odata.type'] -replace '^#microsoft\.graph\.', '' -replace 'AuthenticationMethod$', '')
    #CreatedDateTime = $auth['createdDateTime']
    #Id              = $auth.Id
    if ($null -ne $userInfo.AuthenticationMethods) {
        $authMethods = [System.Collections.ArrayList]::new()
        foreach ($method in $userInfo.AuthenticationMethods.PSObject.Properties) {
            $authMethods.Add($method.Value)
        }
        $authMethods | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-AuthenticationMethods.csv" : "$tempFolder\AuthenticationMethods.csv") -Force
    }

    # 6. Risk Status
    #Level               = $riskLog.RiskLevel
    #LastUpdatedDateTime = $riskLog.RiskLastUpdatedDateTime
    #State               = $riskLog.RiskState
    #Detail              = $riskLog.RiskDetail
    if ($null -ne $userInfo.RiskStatus) {
        $riskStat = [System.Collections.ArrayList]::new()
        $riskStat.Add([PSCustomObject]@{
                Name                = $userInfo.Name
                UserPrincipalName   = $userInfo.UserPrincipalName
                UserId              = $userInfo.UserId
                State               = $userInfo.RiskStatus.State
                Level               = $userInfo.RiskStatus.Level
                LastUpdatedDateTime = $userInfo.RiskStatus.LastUpdatedDateTime
                Detail              = $userInfo.RiskStatus.Detail
            })

        $riskStat | Export-Csv -NoTypeInformation -Path ($individualCsvFiles ? "$outputPath\Export-RiskStatus.csv" : "$tempFolder\RiskStatus.csv") -Force
    }

    # Combine Files
    if (-not $individualCsvFiles) {
        Merge-CsvFiles -CSVPath $tempFolder -XLOutput $outputPath
        Remove-Item $tempFolder -Force -Recurse
    }
}

function Convert-BatchUsersToSpreadsheet {
    [CmdletBinding()]
    Param(
        [PSCustomObject] $userInfoList,
        [string] $outputPath,
        [bool] $getAccountDetails = $false,
        [bool] $getLicenses = $false,
        [bool] $getDevices = $false,
        [bool] $getRolesGroups = $false,
        [bool] $getAuthenticationMethods = $false,
        [bool] $getRiskStatus = $false
    )

    $tempFolder = "$($env:TEMP)\ProfileExport"
    if (-not (Test-Path -Path $tempFolder)) {
        New-Item -Path  $tempFolder -ItemType Directory
    }

    # 1. Account Details
    if ($getAccountDetails) {
        $accDetails = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $accDetails.Add([PSCustomObject]@{
                    Name                         = $thisUser.Name
                    UserPrincipalName            = $thisUser.UserPrincipalName
                    UserId                       = $thisUser.UserId
                    AccountEnabled               = $thisUser.AccountDetails.AccountEnabled
                    CreationDate                 = $thisUser.AccountDetails.CreationDate
                    UserType                     = $thisUser.AccountDetails.UserType
                    OnPremisesSyncEnabled        = $thisUser.AccountDetails.OnPremisesSyncEnabled
                    OnPremisesSecurityIdentifier = $thisUser.AccountDetails.OnPremisesSecurityIdentifier
                    OnPremisesLastSyncDateTime   = $thisUser.AccountDetails.OnPremisesLastSyncDateTime
                })
        }
        $accDetails | Export-Csv -NoTypeInformation -Path "$tempFolder\AccountDetails.csv" -Force
    }

    # 2. Licenses
    if ($getLicenses) {
        $lices = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $userLic = [System.Collections.ArrayList]::new()
            foreach ($lic in $thisUser.Licenses.PSObject.Properties) {
                $userLic.Add($lic.Name)
            }
            $lices.Add([PSCustomObject]@{
                    Name              = $thisUser.Name
                    UserPrincipalName = $thisUser.UserPrincipalName
                    UserId            = $thisUser.UserId
                    Licenses          = ($userLic -join ",")
                })
        }
        $lices | Export-Csv -NoTypeInformation -Path "$tempFolder\Licenses.csv" -Force
    }

    # 3. Devices
    if ($getDevices) {
        $devices = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $userDev = [System.Collections.ArrayList]::new()
            foreach ($dev in $thisUser.Devices.PSObject.Properties) {
                $userDev.Add($dev.Value.Name)
            }
            $devices.Add([PSCustomObject]@{
                    Name              = $thisUser.Name
                    UserPrincipalName = $thisUser.UserPrincipalName
                    UserId            = $thisUser.UserId
                    Devices           = ($userDev -join ",")
                })
        }
        $devices | Export-Csv -NoTypeInformation -Path "$tempFolder\Devices.csv" -Force
    }

    # 4. Roles
    if ($getRolesGroups) {
        $rolesGroups = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $userRoles = [System.Collections.ArrayList]::new()
            foreach ($roll in $thisUser.RolesGroups.PSObject.Properties) {
                $userRoles.Add($roll.Value.Name)
            }
            $rolesGroups.Add([PSCustomObject]@{
                    Name              = $thisUser.Name
                    UserPrincipalName = $thisUser.UserPrincipalName
                    UserId            = $thisUser.UserId
                    RolesGroups       = ($userRoles -join ",")
                })
        }
        $rolesGroups | Export-Csv -NoTypeInformation -Path "$tempFolder\RolesGroups.csv" -Force
    }

    # 5. Authentication Methods
    if ($getAuthenticationMethods) {
        $authMethods = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $userAuths = [System.Collections.ArrayList]::new()
            foreach ($authMethod in $thisUser.AuthenticationMethods.PSObject.Properties) {
                $userAuths.Add($authMethod.Value.Type)
            }
            $authMethods.Add([PSCustomObject]@{
                    Name                  = $thisUser.Name
                    UserPrincipalName     = $thisUser.UserPrincipalName
                    UserId                = $thisUser.UserId
                    AuthenticationMethods = ($userAuths -join ",")
                })
        }
        $authMethods | Export-Csv -NoTypeInformation -Path "$tempFolder\AuthenticationMethods.csv" -Force
    }

    # 6. Risk Status
    if ($getRiskStatus) {
        $riskStatuses = [System.Collections.ArrayList]::new()
        foreach ($thisUser in $userInfoList) {
            $riskStatuses.Add([PSCustomObject]@{
                    Name                = $thisUser.Name
                    UserPrincipalName   = $thisUser.UserPrincipalName
                    UserId              = $thisUser.UserId
                    State               = $thisUser.RiskStatus.State
                    Level               = $thisUser.RiskStatus.Level
                    LastUpdatedDateTime = $thisUser.RiskStatus.LastUpdatedDateTime
                    Detail              = $thisUser.RiskStatus.Detail
                })
        }
        $riskStatuses | Export-Csv -NoTypeInformation -Path "$tempFolder\RiskStatus.csv" -Force
    }

    Merge-CsvFiles -CSVPath $tempFolder -XLOutput $outputPath
    Remove-Item $tempFolder -Force -Recurse
}

function Request-SaveFileLocation {
    [CmdletBinding()]
    Param(
        [string]$userPrincipalName
    )

    $fileExportDialog = [System.Windows.Forms.SaveFileDialog]::new()
    $fileExportDialog.Filter = "Excel Workbook (*.xlsx)|*.xlsx|All files (*.*)|*.*"
    $fileExportDialog.FilterIndex = 1
    $fileExportDialog.FileName = "Export-$($userPrincipalName -Replace "@", "-" -Replace "\.","-").xlsx"
    $fileExportDialog.RestoreDirectory = $true
    if ($fileExportDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $fileExportDialog
    }
    return $null
}

function Request-FolderExportLocation {
    [CmdletBinding()]
    Param()

    $fileExportDialog = [System.Windows.Forms.FolderBrowserDialog]::new()
    $fileExportDialog.Description = "Select the Path to Export Files To"
    $fileExportDialog.UseDescriptionForTitle = $true
    if ($fileExportDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $fileExportDialog
    }
    return $null
}

function Request-UserListFile {
    [CmdletBinding()]
    Param()

    $fileImportDialog = [System.Windows.Forms.OpenFileDialog]::new()
    $fileImportDialog.Title = "Select the List of Emails. Cancel to Get All Users in Domain."
    $fileImportDialog.Filter = "CSV Spreadsheet (*.csv)|*.csv|Text Document (*.txt)|*.txt|All files (*.*)|*.*"
    $fileImportDialog.FilterIndex = 2
    if ($fileImportDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $fileImportDialog
    }
    return $null
}

function Get-UserListFromFile {
    [CmdletBinding()]
    Param(
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    $extension = (Get-Item $Path).Extension.ToLower()

    switch ($extension) {
        ".txt" {
            # TXT: assume one name per line
            $raw = Get-Content $Path
        }
        ".csv" {
            # CSV: detect if it's a single column or multiple
            $raw = Import-Csv $Path | ForEach-Object {
                $_.PSObject.Properties.Value
            }
        }
        default {
            throw "Unsupported file type: $extension. Use TXT or CSV."
        }
    }

    # Normalize: flatten, split on commas/newlines, trim, remove blanks
    $names = ($raw -join ",") -split "," |
    ForEach-Object { $_.Trim() } |
    Where-Object { $_ -ne "" }

    return $names
}


Function Merge-CsvFiles {
    [CmdletBinding()]
    Param(
        $CSVPath = "C:\CSV", ## Soruce CSV Folder
        $XLOutput = "c:\temp.xlsx" ## Output file name
    )

    # Get a list of the CSV Files
    $csvFiles = Get-ChildItem ("$CSVPath\*") -Include *.csv

    # Create EXCEL Instance
    $Excel = [Activator]::CreateInstance([type]::GetTypeFromProgID("Excel.Application"))
    $Excel.sheetsInNewWorkbook = $csvFiles.Count
    $workbooks = $Excel.Workbooks.Add()
    $CSVSheet = 1

    Foreach ($CSV in $Csvfiles) {
        # Creates 
        $worksheets = $workbooks.worksheets

        # Get CSV Name
        $CSVFullPath = $CSV.FullName
        $SheetName = ($CSV.name -split "\.")[0]

        $worksheet = $worksheets.Item($CSVSheet)
        $worksheet.Name = $SheetName
        $TxtConnector = ("TEXT;" + $CSVFullPath)
        $CellRef = $worksheet.Range("A1")
        $Connector = $worksheet.QueryTables.add($TxtConnector, $CellRef)
        $worksheet.QueryTables.item($Connector.name).TextFileCommaDelimiter = $True
        $worksheet.QueryTables.item($Connector.name).TextFileParseType = 1
        $worksheet.QueryTables.item($Connector.name).Refresh()
        $worksheet.QueryTables.item($Connector.name).delete()
        $worksheet.UsedRange.EntireColumn.AutoFit()

        # Increase Sheet Count
        $CSVSheet++
    }

    $workbooks.SaveAs($XLOutput, 51)
    $workbooks.Saved = $true
    $workbooks.Close()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbooks) | Out-Null
    $Excel.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel) | Out-Null
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}