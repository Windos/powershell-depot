powershell-depot
================

The place where I dump PowerShell cmdlets

Installation
============

To run any of these scripts you'll need Windows PowerShell installed 
(it is built in on Windows 7 and above), and you will need to set an
appropriate script execution policy, see: 
[TechNet](http://technet.microsoft.com/en-us/library/ee176961.aspx)

'VMware' cmdlets
================

To run any cmdlets stored under 'VMware' you will need to have 
[vSphere PowerCLI](https://my.vmware.com/web/vmware/details?downloadGroup=PCLI550&productId=352) 
installed (_link correct on 27/08/2014_).

All cmdlets that use PowerCLI will check to see if the needed PSSnapIns are 
loaded, and adds them if not. They will also connect to a VIServer 
(vSphere/vCenter) if the session they are running in does not have an active 
connection.

To set the server you want to connect to when using PowerCLI, replace 
**\_\_\_VCENTER\_SERVER\_\_\_** with the fully qualified domain name of your 
vSphere/vCenter server.

Conventions
===========

Where possible I will be following [Don Jones' Best 
Practices](http://windowsitpro.com/blog/my-12-powershell-best-practices) and
[Darkoperator's Style Guide](https://github.com/darkoperator/PSStyleGuide/blob/master/English.md).
