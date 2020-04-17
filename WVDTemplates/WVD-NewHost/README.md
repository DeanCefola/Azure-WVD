# Windows Virtual Desktop Automated Deployment
This template will
- Allow you to select either a Windows Server or Windows Client VM for deployment
- Auto join your Active Directory Domain
- Download the latest WVD Installer Agent, Bootloader and FSLogix software
- Auto configure the new VM(s) to join your Host Pool
- Auto configure the new VM(s) to use a central storage location for WVD Profiles with FSLogix

----
----

# Requirements:

**Permissions:**
- Azure Active Directory Global Administrator
- Active Directory Administrator
- Account to join AD Domain (optional)

**Infrastructure:**
- Create WVD Tenant
- Create WVD HostPool
- Create Active Directory domain for the new VM(s) to join
- Create a central file share for WVD Profiles
- Generate HostPool Regestration Token

----
----

**New Session Host**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDeanCefola%2FAzure-WVD%2Fmaster%2FWVDTemplates%2FWVD-NewHost%2FWVD-NewHost.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDeanCefola%2FAzure-WVD%2Fmaster%2FWVDTemplates%2FWVD-NewHost%2FWVD-NewHost.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a>

----
----

**New Ephemeral Host**

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDeanCefola%2FAzure-WVD%2Fmaster%2FWVDTemplates%2FWVD-NewHost%2FWVD-NewEphemeralHost.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>
<a href="http://armviz.io/#/?load=https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FDeanCefola%2FAzure-WVD%2Fmaster%2FWVDTemplates%2FWVD-NewHost%2FWVD-NewEphemeralHost.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.png"/>
</a>

----
----

# **The Azure Academy**
## Watch the Windows Virtual Desktop Series
[![](https://tr1.cbsistatic.com/hub/i/2018/12/12/b685a2ae-3772-4214-9ba5-4205842dd50b/microsoft-wvdarchitecture.png)](https://www.youtube.com/playlist?list=PL-V4YVm6AmwXGvQ46W8mHkpvm6S5IIitK)


If you are new to Azure virtual machines, see:

- [Azure Virtual Machines](https://azure.microsoft.com/services/virtual-machines/).
- [Azure Linux Virtual Machines documentation](https://docs.microsoft.com/azure/virtual-machines/linux/)
- [Azure Windows Virtual Machines documentation](https://docs.microsoft.com/azure/virtual-machines/windows/)
- [Template reference](https://docs.microsoft.com/azure/templates/microsoft.compute/allversions)
- [Quickstart templates](https://azure.microsoft.com/resources/templates/?resourceType=Microsoft.Compute&pageNumber=1&sort=Popular)

If you are new to template deployment, see:

[Azure Resource Manager documentation](https://docs.microsoft.com/azure/azure-resource-manager/)
