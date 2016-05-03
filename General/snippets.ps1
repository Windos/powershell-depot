# List of small snippets that I go back to from time to time
# Too small for their own script file each

break

# Quickly enable all disabled 'training' generic accounts
Get-ADUser -Filter {Enabled -eq $false -and Name -like 'Training*'} | Enable-ADAccount

# And disable them again... except for that one that someone insists on leaving for testing
Get-ADuser -Filter {Enabled -eq $true -and Name -like 'Training*' -and Name -notlike '*8'} | Disable-ADAccount
