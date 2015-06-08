break

# Change Network Adapter on VM Version 10 and higher VMs (can't do it via web client)
Get-VM 'vmname' | Get-NetworkAdapter | Set-NetworkAdapter -Type VMXNET3