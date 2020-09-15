$ResourceGroup='rg-virtualgateway'
$Location='australiaeast'
$VNetName='vnet-extended-home'
$SubnetMyVmsName='snet-myvms'
$SubnetGatewayName='GatewaySubnet'
$VgwName='vgw-devtest'
$VgwPublicIpName='pip-vgw-devtest'
$VgwConnectionName='s2s-devtest-home'
$LgwName='lgw-home'
$NsgName='nsg-myvms'
$VNetCidr='192.168.3.0/24'
$SubnetMyVmsCidr='192.168.3.32/27'
$SubnetGatewayCidr='192.168.3.0/28'
$SubnetLocalGateway='192.168.1.0/24'
$SharedKey ='YourSecureSharedKey9'

$MyPublicIp = (Invoke-WebRequest -Uri icanhazip.com).Content.Trim()

New-AzResourceGroup -Name $ResourceGroup -Location $Location

$icmpRule = New-AzNetworkSecurityRuleConfig `
  -Name 'ICMP' `
  -Description 'Allow ICMP for ping commands' `
  -Access Allow `
  -Protocol ICMP `
  -Direction Inbound `
  -Priority 100 `
  -SourceAddressPrefix Internet `
  -SourcePortRange * `
  -DestinationAddressPrefix VirtualNetwork `
  -DestinationPortRange *

$NetworkSecurityGroup = New-AzNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroup `
  -Location $Location `
  -Name $NsgName `
  -SecurityRules $icmpRule

Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'
$SubNetMyVms   = New-AzVirtualNetworkSubnetConfig -Name $SubnetMyVmsName -AddressPrefix $SubnetMyVmsCidr -NetworkSecurityGroup $networkSecurityGroup
$SubNetGateway = New-AzVirtualNetworkSubnetConfig -Name $SubnetGatewayName -AddressPrefix $SubnetGatewayCidr 

$Vnet = New-AzVirtualNetwork -Location $Location `
  -Name $VNetName `
  -ResourceGroupName $ResourceGroup `
  -AddressPrefix $VNetCidr `
  -Subnet $SubNetMyVms, $SubNetGateway

$VgwPip = New-AzPublicIpAddress `
  -AllocationMethod Dynamic `
  -IpaddressVersion IPv4 `
  -Location $Location `
  -Name $VgwPublicIpName `
  -ResourceGroupName $ResourceGroup

$SubnetGateway = Get-AzVirtualNetworkSubnetConfig -Name $SubNetGatewayName -VirtualNetwork $Vnet  

$GwIpConfig = New-AzVirtualNetworkGatewayIpConfig `
  -Name 'GwIpConfig' `
  -Subnet $SubnetGateway `
  -PublicIpAddress $VgwPip

$Lgw = New-AzLocalNetworkGateway `
  -Name $LgwName `
  -Location $Location `
  -ResourceGroupName $ResourceGroup `
  -AddressPrefix $SubnetLocalGateway `
  -GatewayIpAddress $MyPublicIp

$Vgw = New-AzVirtualNetworkGateway `
  -Name $VgwName `
  -ResourceGroupName $ResourceGroup `
  -Location $Location `
  -IpConfigurations $GwIpConfig `
  -GatewayType Vpn `
  -VpnType RouteBased `
  -GatewaySku Basic
 
$Vgw = Get-AzVirtualNetworkGateway -Name $VgwName -ResourceGroupName $ResourceGroup
$Lgw = Get-AzLocalNetworkGateway -Name $LgwName -ResourceGroupName $ResourceGroup

New-AzVirtualNetworkGatewayConnection `
  -Name $VgwConnectionName `
  -ResourceGroupName $ResourceGroup `
  -VirtualNetworkGateway1 $Vgw `
  -LocalNetworkGateway2 $Lgw `
  -Location $Location `
  -ConnectionType IPsec 
  -SharedKey $SharedKey
