Import-Module ActiveDirectory
#Purpose: Read active employees from Employees.csv, create their AD accounts, 
#place them in the correct department OU, and assign their department and banking groups.
$EmployeeFile = "C:\IAM-Training-Lab\Config\Employees.csv"
$DomainPath = "DC=IamLab,DC=Local"

$TemporaryPassword = ConvertTo-SecureString `
    "Temp@12345" `
    -AsPlainText `
    -Force

$Employees = Import-Csv $EmployeeFile

foreach ($Employee in $Employees) {

    # Only provision active employees
    if ($Employee.Status -ne "Active") {
        Write-Host "Skipping EmployeeID $($Employee.EmployeeID): Status is $($Employee.Status)"
        continue
    }

    $FirstName  = $Employee.FirstName.Trim()
    $LastName   = $Employee.LastName.Trim()
    $Department = $Employee.Department.Trim()
    $JobTitle   = $Employee.JobTitle.Trim()
    $BankRole   = $Employee.BankRole.Trim().ToUpper()

    # Example:
    # Husain Alghamdi -> halghamdi
    $Username = (
        $FirstName.Substring(0,1) + $LastName
    ).ToLower()

    # Check if user already exists
    $ExistingUser = Get-ADUser `
        -Filter "SamAccountName -eq '$Username'" `
        -ErrorAction SilentlyContinue

    if ($ExistingUser) {
        Write-Host "User already exists: $Username"
        continue
    }

    # Determine user's OU
    $TargetOU = "OU=$Department,OU=Employees,$DomainPath"

    # Department group
    $DepartmentGroup = "GG_$($Department.ToUpper())"

    # Banking application group
    $BankGroup = "BANK_APP_$BankRole"

    try {

        # Create AD account
        New-ADUser `
            -Name "$FirstName $LastName" `
            -GivenName $FirstName `
            -Surname $LastName `
            -DisplayName "$FirstName $LastName" `
            -SamAccountName $Username `
            -UserPrincipalName "$Username@IamLab.Local" `
            -EmployeeID $Employee.EmployeeID `
            -Department $Department `
            -Title $JobTitle `
            -Description "Manager: $($Employee.Manager)" `
            -Path $TargetOU `
            -AccountPassword $TemporaryPassword `
            -Enabled $true `
            -ChangePasswordAtLogon $true

        # Birthright group
        Add-ADGroupMember `
            -Identity "GG_ALL_EMPLOYEES" `
            -Members $Username

        # Department RBAC group
        Add-ADGroupMember `
            -Identity $DepartmentGroup `
            -Members $Username

        # Banking application access
        Add-ADGroupMember `
            -Identity $BankGroup `
            -Members $Username

        Write-Host ""
        Write-Host "Created user successfully: $Username"
        Write-Host "Department: $Department"
        Write-Host "Department Group: $DepartmentGroup"
        Write-Host "Bank Group: $BankGroup"
        Write-Host "-----------------------------------"
    }

    catch {

        Write-Host "FAILED: $Username"
        Write-Host $_.Exception.Message
    }
}