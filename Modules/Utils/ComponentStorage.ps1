<#
    This is ComponentStorage, a Hashtable structure for referencing Elements on the WinForm GUI in Callbacks

    You can't use local variables since the Callbacks are in different Run Contexts

    You CAN However Read from Global Variables. This module adds functions to read and write to a singular Global Value 
    instead of using many unsorted Global Variables. Simply give it a Category Name, and a Variable Name.
#>
$StoredComponents = @{}

<#
    This function is used to Add a Variable to the Global Data Structure
#>
function Register-Component {
    [CmdletBinding()]
    Param(
        [string]$relationName,
        [string]$variableName,
        [Object]$valueOfVar
    )
    if (-not $StoredComponents.ContainsKey($relationName)) {
        $StoredComponents[$relationName] = @{}
    }
    $StoredComponents[$relationName][$variableName] = $valueOfVar
}

<#
    This function will return the Variable from the Global Data Structure
#>
function Get-Component {
    [CmdletBinding()]
    Param(
        [string]$relationName,
        [string]$variableName
    )
    if (-not $StoredComponents.ContainsKey($relationName)) {
        return $null
    }
    if (-not $StoredComponents[$relationName].ContainsKey($variableName)) {
        return $null
    }
    return $StoredComponents[$relationName][$variableName]
}

function Clear-ComponentCache {
    [CmdletBinding()]
    Param()

    Clear-Variable -Name "StoredComponents"
}