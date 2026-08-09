Import-Module ActiveDirectory

$DomainPath = "DC=IamLab,DC=Local"

# Create main Employees OU
if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Employees'" -ErrorAction SilentlyContinue)) {
    New-ADOrganizationalUnit `
        -Name "Employees" `
        -Path $DomainPath

    Write-Host "Created OU: Employees"
}

# Departments used in Employees.csv
$Departments = @(
    "IT",
    "HR",
    "Finance",
    "Operations"
)

foreach ($Department in $Departments) {

    $OUPath = "OU=$Department,OU=Employees,$DomainPath"

    $ExistingOU = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$Department'" `
        -SearchBase "OU=Employees,$DomainPath" `
        -ErrorAction SilentlyContinue

    if (-not $ExistingOU) {

        New-ADOrganizationalUnit `
            -Name $Department `
            -Path "OU=Employees,$DomainPath"

        Write-Host "Created Department OU: $Department"
    }
    else {
        Write-Host "OU already exists: $Department"
    }
}

# Other IAM OUs
$OtherOUs = @(
    "Groups",
    "Service Accounts",
    "Disabled Users"
)

foreach ($OU in $OtherOUs) {

    $ExistingOU = Get-ADOrganizationalUnit `
        -Filter "Name -eq '$OU'" `
        -SearchBase $DomainPath `
        -ErrorAction SilentlyContinue

    if (-not $ExistingOU) {

        New-ADOrganizationalUnit `
            -Name $OU `
            -Path $DomainPath

        Write-Host "Created OU: $OU"
    }
    else {
        Write-Host "OU already exists: $OU"
    }
}

Write-Host ""
Write-Host "OU creation completed."