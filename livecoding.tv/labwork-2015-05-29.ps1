# $newUsers = @()
# 
# for ($i = 1; $i -lt 4; $i++) { 
#     $newUsers += Import-Csv -Path "C:\temp\dataMay-29-2015-$i.csv"
# }

# $standardPassword = 'Chang3Me' | ConvertTo-SecureString -AsPlainText -Force
# 
# foreach ($newUser in $newUsers) {
#     $samAccountName = $newUser.GivenName[0] + $newUser.Surname
#     $displayName = "$($newUser.GivenName) $($newUser.Surname)"
# 
#     $test = Get-ADUser -Identity $samAccountName -ErrorAction SilentlyContinue
# 
#     if ($test -eq $null) {
#         $Params = @{'AccountPassword' = $standardPassword;
#                     'ChangePasswordAtLogon' = $true;
#                     'City' = $newUser.City;
#                     'Company' = $newUser.Company;
#                     'Department' = $newUser.Department;
#                     'DisplayName' = $displayName;
#                     'Name' = $displayName;
#                     'Enabled' = $true;
#                     'GivenName' = $newUser.GivenName;
#                     'OfficePhone' = $newUser.OfficePhone;
#                     'SamAccountName' = $samAccountName;
#                     'Surname' = $newUser.Surname
#         }
#     
#         New-ADUser @Params
#     }
# }

# $users = Get-ADUser -SearchBase 'OU=staff,OU=users,OU=kingdom,DC=king,DC=geek,DC=nz' -filter * -Properties Department
# 
# $departments = ($users | Group-Object -Property Department).Name

# New-Item -ItemType Directory -Path \\fs1\E$\Group

# $parent = '\\fs1\E$\Group'
# 
# foreach ($department in $departments) {
#     $departmentString = $department.replace(' ', '').replace('and', '')
#     $departmentPath = Join-Path -Path $parent -ChildPath $departmentString
#     New-Item -ItemType Directory -Path $departmentPath
# }

# New-Item -ItemType Directory -Path \\fs1\E$\Group\Common

# foreach ($department in $departments) {
#     $departmentString = $department.replace(' ', '').replace('and', '')
#     $deptRO = 'acl_' + $departmentString + '_RO'
#     $deptRW = 'acl_' + $departmentString + '_RW'
#     
#     New-ADGroup -Name $deptRO -DisplayName $deptRO -Path 'OU=acl,OU=groups,OU=kingdom,DC=king,DC=geek,DC=nz' -GroupScope Global
#     New-ADGroup -Name $deptRW -DisplayName $deptRW -Path 'OU=acl,OU=groups,OU=kingdom,DC=king,DC=geek,DC=nz' -GroupScope Global
# }

# foreach ($department in $departments) {
#     $departmentString = $department.replace(' ', '').replace('and', '')
#     $deptRW = 'acl_' + $departmentString + '_RW'
#     
#     $users = Get-ADUser -SearchBase 'OU=staff,OU=users,OU=kingdom,DC=king,DC=geek,DC=nz' -filter {Department -eq $department}
# 
#     Get-ADGroup -Identity $deptRW | Add-ADGroupMember -Members $users
# }

# New-SmbShare -Name Group$ -path 'E:\Group' -FullAccess Everyone -FolderEnumerationMode AccessBased -CachingMode None -CimSession fs1

# foreach ($department in $departments) {
#     $departmentString = $department.replace(' ', '').replace('and', '')
#     $departmentPath = Join-Path -Path 'E:\Group' -ChildPath $departmentString
#     New-SmbShare -Name "$departmentString$" -path $departmentPath -FullAccess Everyone -FolderEnumerationMode AccessBased -CachingMode None -CimSession fs1
# }

# $acl = Get-Acl \\fs1\e$\group\techsupport
# $permission = "domain\user","FullControl","Allow"
# $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
# $acl.SetAccessRule($accessRule)
# $acl | Set-Acl c:\temp
# 
# $acl = get-acl "C:\temp"
# $acl.SetAccessRuleProtection($true,$true)
# $acl | set-acl

# $parent = '\\fs1\e$\group'
# foreach ($department in $departments) {
#     $departmentString = $department.replace(' ', '').replace('and', '')
#     $deptRW = 'KING\acl_' + $departmentString + '_RW'
#     $deptRO = 'KING\acl_' + $departmentString + '_RO'
#     $departmentPath = Join-Path -Path $parent -ChildPath $departmentString
# 
#     $acl = Get-Acl $departmentPath
#     $acl.SetAccessRuleProtection($true,$true)
#     $acl | set-acl
#     $acl = $null
#     $acl = Get-Acl $departmentPath
#     $permission1 = "BUILTIN\Users","ReadAndExecute, Synchronize","Allow"
#     $accessRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission1
#     $permission2 = "BUILTIN\Users","AppendData","Allow"
#     $accessRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission2
#     $permission3 = "BUILTIN\Users","CreateFiles","Allow"
#     $accessRule3 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission3
#     $acl.RemoveAccessRule($accessRule1)
#     $acl.RemoveAccessRule($accessRule2)
#     $acl.RemoveAccessRule($accessRule3)
# 
#     $permission4 = $deptRW,"Modify","ContainerInherit,ObjectInherit","None","Allow"
#     $accessRule4 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission4
#     $permission5 = $deptRO,"ReadAndExecute","ContainerInherit,ObjectInherit","None","Allow"
#     $accessRule5 = New-Object System.Security.AccessControl.FileSystemAccessRule $permission5
#     $acl.SetAccessRule($accessRule4)
#     $acl.SetAccessRule($accessRule5)
#     $acl | set-acl
# }

#New-Item -ItemType Directory -Path \\fs1\E$\User
#New-SmbShare -Name User$ -path 'E:\User' -FullAccess Everyone -FolderEnumerationMode AccessBased -CachingMode None -CimSession fs1
New-SmbShare -Name Common$ -path 'E:\Group\Common' -FullAccess Everyone -FolderEnumerationMode AccessBased -CachingMode None -CimSession fs1