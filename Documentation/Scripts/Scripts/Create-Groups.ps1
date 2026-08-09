Import-Module ActiveDirectory

$GroupsOU = "OU=Groups,DC=IamLab,DC=Local"

$Groups = @(
    "GG_ALL_EMPLOYEES",
    "GG_IT",
    "GG_HR",
    "GG_FINANCE",
    "GG_OPERATIONS",
    "BANK_APP_VIEWER",
    "BANK_APP_PROCESSOR",
    "BANK_APP_APPROVER"
)

foreach ($Group in $Groups) {

    $ExistingGroup = Get-ADGroup `
        -Filter "Name -eq '$Group'" `
        -ErrorAction SilentlyContinue

    if (-not $ExistingGroup) {

        New-ADGroup `
            -Name $Group `
            -SamAccountName $Group `
            -GroupCategory Security `
            -GroupScope Global `
            -Path $GroupsOU

        Write-Host "Created group: $Group"
    }
    else {
        Write-Host "Group already exists: $Group"
    }
}