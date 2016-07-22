### SPECIFY ESX SERVER TO DEPLOY ###
$vmserver = "LouPrEsx005.company.com"
 
# Add PowerCLI bits
Add-PSSnapin -Name "VMware.VimAutomation.Core" -ErrorAction SilentlyContinue
# Connect to Virtual Infrastructure
Connect-VIserver LouPrMgt011.company.com -WarningAction SilentlyContinue
 
# Rescan HBA for storage
Get-VMHost $vmserver | Get-VMHostStorage -RescanAllHba
 
# Set Multipath to use Round Robin load balancing
Get-VMHost $vmserver | Get-ScsiLun -LunType disk | where {$_.MultipathPolicy -ne "RoundRobin"} | Set-ScsiLun -MultipathPolicy RoundRobin
 
# Configure & Start NTP
Add-VmHostNtpServer -NTPServer ntp.company.com -VMhost $vmserver -ErrorAction SilentlyContinue
Get-VMHostService -VMhost $vmserver | where {$_.key -eq "ntpd"} | Set-VMHostService -Policy automatic
Get-VMHostService -VMhost $vmserver | where {$_.key -eq "ntpd"} | Start-VMHostService
 
# Suppress informational warnings related to SSH and ESXi shell access
Get-VMHost $vmserver | Get-AdvancedSetting -Name UserVars.SuppressShellWarning | Set-AdvancedSetting -Value 1 -Confirm:$false
 
# Configure syslog
Set-VMHostAdvancedConfiguration -VMHost $vmserver -Name Syslog.global.logDirUnique -Value $true
Set-VMHostAdvancedConfiguration -VMHost $vmserver -Name Syslog.global.logDir "[Templates_01]/syslogs/"
Set-VMHostAdvancedConfiguration -VMHost $vmserver -Name Syslog.global.logHost "tcp://10.10.230.31:514"
Get-VMHostFirewallException | Where {$_.Name -eq ësyslogí} | Set-VMHostFirewallException -Enabled:$true
 
# Configure max q depth
Get-VMHost $vmserver | Get-VMHostModule "qla2xxx" | Set-VMHostModule -Options "ql2xmaxqdepth=64"
 
# Set all nics in vSwitch to Active
$vSwitch0 = Get-VMHost $vmserver | Get-VirtualSwitch -Name vSwitch0
$vSwitch0 | Get-NicTeamingPolicy | Set-NicTeamingPolicy -MakeNicActive ($vSwitch0 | Select-Object -ExpandProperty Nic)
 
# Enable vMotion on the Management Network
Get-VMHost $vmserver | Get-VMHostNetworkAdapter -VMKernel | Set-VMHostNetworkAdapter -VMotionEnabled $True -Confirm:$false
