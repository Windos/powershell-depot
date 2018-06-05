# Get your Trello Developer API Key here: https://trello.com/app-key

Import-Module -Name 'TrellOps'          # https://github.com/MethosNL/TrellOps
Import-Module -Name 'CredentialManager' # https://github.com/davotronic5000/PowerShell_Credential_Manager

$Token = @{
    Token     = (Get-StoredCredential -Target TrelloToken).GetNetworkCredential().Password
    AccessKey = (Get-StoredCredential -Target TrelloKey).GetNetworkCredential().Password
}

# Make sure PowerShell is using TLS 1.2 as TLS 1.0 won't work
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Get Board

# Get List

# Get Cards

# Sort cards on number of votes

# Find unprocessed cards

# Get requested categories

# Increment vote count for requested categories
