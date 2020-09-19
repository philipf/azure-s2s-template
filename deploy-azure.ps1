## Set configuration variables
$SharedKey ='YourSecureSharedKey9' # <1>

# Azure (Left-side)
$ResourceGroup='rg-virtualgateway'
$Location='australiaeast'
$VNetName='vnet-extended-home'
$SubnetMyVmsName='snet-myvms'
$SubnetGatewayName='GatewaySubnet' # <2>
$VgwName='vgw-devtest'
$VgwPublicIpName='pip-vgw-devtest'
$VgwConnectionName='s2s-devtest-home'
$LgwName='lgw-home'
$NsgName='nsg-myvms'
$VNetCidr='192.168.3.0/24' # <3>
$SubnetMyVmsCidr='192.168.3.32/27' # <3>
$SubnetGatewayCidr='192.168.3.0/28'

# Local network (Right-side)
$SubnetLocalGateway='192.168.1.0/24' # <3>
$MyPublicIp = (Invoke-WebRequest -Uri icanhazip.com).Content.Trim()  # <4>

# Create a new resource group to deploy all the S2S resources to.
# Deleting this resource group removes all the S2S resource with it. 
New-AzResourceGroup -Name $ResourceGroup -Location $Location

# Create a firewall rule to allow ping traffic.  
# This is not required but help for connectivity testing and can be removed later
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

# Hides annoying deprecated warnings, unfortunately no replacements commands existed yet :(
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'true'

$SubNetMyVms = New-AzVirtualNetworkSubnetConfig -Name $SubnetMyVmsName `
  -AddressPrefix $SubnetMyVmsCidr `
  -NetworkSecurityGroup $networkSecurityGroup

$SubNetGateway = New-AzVirtualNetworkSubnetConfig -Name $SubnetGatewayName `
  -AddressPrefix $SubnetGatewayCidr 

  Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings 'false'

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

# Create the VGW, this step takes about 45 minutes
$Vgw = New-AzVirtualNetworkGateway `
  -Name $VgwName `
  -ResourceGroupName $ResourceGroup `
  -Location $Location `
  -IpConfigurations $GwIpConfig `
  -GatewayType Vpn `
  -VpnType RouteBased `
  -GatewaySku Basic # <5>
 
$Vgw = Get-AzVirtualNetworkGateway -Name $VgwName -ResourceGroupName $ResourceGroup
$Lgw = Get-AzLocalNetworkGateway -Name $LgwName -ResourceGroupName $ResourceGroup

# Create the S2S IPsec tunnel
New-AzVirtualNetworkGatewayConnection `
  -Name $VgwConnectionName `
  -ResourceGroupName $ResourceGroup `
  -VirtualNetworkGateway1 $Vgw `
  -LocalNetworkGateway2 $Lgw `
  -Location $Location `
  -ConnectionType IPsec `
  -SharedKey $SharedKey
