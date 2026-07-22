# Phase 7: Azure Infrastructure Integration - Networking and Connectivity

## Phase Overview

This phase sets up secure hybrid connectivity between on-premises and Azure. It uses Site-to-Site VPN, network segmentation, and disaster recovery infrastructure.

**Duration**: 3 weeks  
**Key Objectives**: VPN Gateway configuration, Site-to-Site VPN establishment, network connectivity validation

---

## Task 1: Configure Azure Virtual Network

### Step 1.1: Create Virtual Network

1. Navigate to https://portal.azure.com
2. Go to **Virtual Networks**
3. Click **Create**
4. Configure:
   - **Subscription**: Select your subscription
   - **Resource Group**: Create new "rg-hybrid-infrastructure"
   - **Name**: "vnet-hybrid"
   - **Region**: Select region closest to on-premises (e.g., "East US")
   - **IPv4 Address Space**: 10.0.0.0/16 (non-overlapping with on-prem 192.168.0.0/16)
   - Click **Next: IP Addresses**

5. Configure subnets:
   - **Default subnet**: Rename to "subnet-management"
     - Address range: 10.0.1.0/24
   - Add subnet: "subnet-application"
     - Address range: 10.0.2.0/24
   - Add subnet: "subnet-database"
     - Address range: 10.0.3.0/24
   - Add subnet: "GatewaySubnet" (REQUIRED for VPN)
     - Address range: 10.0.0.0/27

6. Click **Create**

**PowerShell Creation:**
```powershell
# Create resource group
$location = "East US"
$resourceGroupName = "rg-hybrid-infrastructure"
New-AzResourceGroup -Name $resourceGroupName -Location $location

# Create virtual network
$vnetName = "vnet-hybrid"
$vnet = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName `
                             -Location $location `
                             -Name $vnetName `
                             -AddressPrefix 10.0.0.0/16

# Add subnets
Add-AzVirtualNetworkSubnetConfig -Name "subnet-management" `
                                 -VirtualNetwork $vnet `
                                 -AddressPrefix 10.0.1.0/24

Add-AzVirtualNetworkSubnetConfig -Name "subnet-application" `
                                 -VirtualNetwork $vnet `
                                 -AddressPrefix 10.0.2.0/24

Add-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" `
                                 -VirtualNetwork $vnet `
                                 -AddressPrefix 10.0.0.0/27

$vnet | Set-AzVirtualNetwork
```

### Step 1.2: Create Network Security Groups

NSGs implement stateful firewall rules for subnet-level filtering:

1. In Azure portal, go to **Network Security Groups**
2. Create NSG "nsg-management":
   - Inbound rules:
     - Allow RDP (3389) from trusted networks only
     - Allow WinRM (5985-5986) from trusted networks
   - Outbound rules: Allow all (default)

3. Create NSG "nsg-application":
   - Inbound rules:
     - Allow HTTP (80) from internet
     - Allow HTTPS (443) from internet
     - Allow RDP (3389) from management subnet
   - Outbound rules: Allow all

**PowerShell NSG Creation:**
```powershell
# Create rule for RDP with restricted source
$ruleRDP = New-AzNetworkSecurityRuleConfig -Name "AllowRDP" `
                                           -Priority 100 `
                                           -Direction Inbound `
                                           -Access Allow `
                                           -Protocol "Tcp" `
                                           -SourcePortRange "*" `
                                           -DestinationPortRange 3389 `
                                           -SourceAddressPrefix 192.168.0.0/16 `
                                           -DestinationAddressPrefix "*"

# Create NSG with rule
$nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName `
                                  -Location $location `
                                  -Name "nsg-management" `
                                  -SecurityRules $ruleRDP
```

---

## Task 2: Configure VPN Gateway

The VPN Gateway enables Site-to-Site VPN connection between on-premises and Azure.

### Step 2.1: Create Public IP for VPN Gateway

1. Go to **Public IP Addresses**
2. Click **Create**
3. Configure:
   - **Name**: "pip-vpn-gateway"
   - **SKU**: Standard
   - **Allocation**: Static
   - **Routing preference**: Microsoft network
4. Click **Create**

**PowerShell:**
```powershell
$pipName = "pip-vpn-gateway"
$pip = New-AzPublicIpAddress -Name $pipName `
                             -ResourceGroupName $resourceGroupName `
                             -Location $location `
                             -AllocationMethod Static `
                             -Sku Standard
```

### Step 2.2: Create VPN Gateway

1. Go to **Virtual Network Gateways**
2. Click **Create**
3. Configure:
   - **Name**: "vpn-gateway-hybrid"
   - **Gateway type**: VPN
   - **VPN type**: Route-based
   - **SKU**: VpnGw1 (1 Gbps; choose VpnGw2 or higher for production)
   - **Virtual Network**: vnet-hybrid
   - **Public IP address**: pip-vpn-gateway
   - **Enable Private Endpoint**: Disabled (unless additional security needed)
4. Click **Create** (takes 20-45 minutes)

**PowerShell:**
```powershell
# Create gateway IP configuration
$subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet
$ipconfig = New-AzVirtualNetworkGatewayIpConfig -Name "vnet-gw-config" `
                                               -SubnetId $subnet.Id `
                                               -PublicIpAddressId $pip.Id

# Create VPN gateway
$gateway = New-AzVirtualNetworkGateway -Name "vpn-gateway-hybrid" `
                                       -ResourceGroupName $resourceGroupName `
                                       -Location $location `
                                       -IpConfigurations $ipconfig `
                                       -GatewayType Vpn `
                                       -VpnType RouteBased `
                                       -GatewaySku VpnGw1

# Get public IP of gateway
$pip | Select-Object IpAddress  # Note this IP for on-premises VPN endpoint configuration
```

---

## Task 3: Configure Local Network Gateway (On-Premises Representation)

The Local Network Gateway represents your on-premises network in Azure:

1. Go to **Local Network Gateways**
2. Click **Create**
3. Configure:
   - **Name**: "lng-onprem"
   - **IP address**: Public IP of on-premises VPN endpoint (e.g., 203.0.113.45)
   - **Address space**: On-premises network CIDR (e.g., 192.168.0.0/16)
   - **Resource group**: Same as VPN gateway
   - **Location**: Same as VPN gateway
4. Click **Create**

**PowerShell:**
```powershell
$lngName = "lng-onprem"
$lng = New-AzLocalNetworkGateway -Name $lngName `
                                -ResourceGroupName $resourceGroupName `
                                -Location $location `
                                -GatewayIpAddress "203.0.113.45" `
                                -AddressPrefix @("192.168.0.0/16")
```

---

## Task 4: Create VPN Connection

1. Go to **Connections**  
2. Click **Create**
3. Configure:
   - **Name**: "conn-onprem-azure"
   - **Connection type**: Site-to-Site (S2S)
   - **Virtual Network Gateway**: vpn-gateway-hybrid
   - **Local Network Gateway**: lng-onprem
   - **Shared Key (PSK)**: Complex shared secret (example: "P@ssw0rd!Azure2024")
   - **Protocol**: IKEv2
   - **Custom Policy**: (leave default for now)
4. Click **Create**

**PowerShell:**
```powershell
# Create VPN connection
$connName = "conn-onprem-azure"
$connection = New-AzVirtualNetworkGatewayConnection -Name $connName `
                                                    -ResourceGroupName $resourceGroupName `
                                                    -VirtualNetworkGateway1 $gateway `
                                                    -LocalNetworkGateway2 $lng `
                                                    -ConnectionType IPsec `
                                                    -SharedKey "P@ssw0rd!Azure2024" `
                                                    -IkeVersion IKEv2
```

---

## Task 5: Configure On-Premises VPN Endpoint

### Step 5.1: Set Up On-Premises VPN

On-premises VPN endpoint (firewall, router, or dedicated appliance):

**Configuration Parameters (from Azure):**
- Azure VPN Gateway IP: [From pip-vpn-gateway public IP]
- Azure VNet Address: 10.0.0.0/16
- Shared Key: P@ssw0rd!Azure2024
- IPsec/IKEv2 protocols

On-premises VPN configuration (example for Fortinet FortiGate):
```
config vpn ipsec phase1-interface
  edit "azure-vpn"
    set interface "wan1"     # outbound interface
    set peertype one
    set peer 52.168.45.123   # Azure VPN Gateway public IP
    set proposal "aes128-sha256"
    set psk "P@ssw0rd!Azure2024"
    set keylife 28800
    set keepalive 10
end

config vpn ipsec phase2-interface
  edit "azure-vpn"
    set phase1name "azure-vpn"
    set proposal "aes128-sha256"
    set pfs enable
    set replay off
    set keylifeseconds 3600
end

config firewall address
  edit "azure-vnet"
    set subnet 10.0.0.0 255.255.0.0
end
```

### Step 5.2: Verify VPN Connection Status

1. In Azure portal, go to **Connections** → "conn-onprem-azure"
2. **Status**: Should show "Connected" (may take 5-10 minutes)
3. If "Not Connected", check:
   - On-premises VPN configuration
   - Shared Key matches exactly
   - Public IPs correct

**PowerShell Verification:**
```powershell
# Check connection status
Get-AzVirtualNetworkGatewayConnection -Name $connName `
                                      -ResourceGroupName $resourceGroupName | `
  Select-Object Name, ConnectionStatus

# Expected output: Status = "Connected"
```

---

## Task 6: Test Hybrid Connectivity

### Step 6.1: Test Network Communication

1. Deploy test VM in Azure (subnet-application):
   - Name: "vm-test-cloud"
   - OS: Windows Server 2022
   - IP: 10.0.2.10

2. From on-premises network, ping Azure VM:
```cmd
# From on-premises machine
ping 10.0.2.10

# Expected: Reply from 10.0.2.10: bytes=32 time<1ms
```

3. RDP to Azure VM from on-premises:
```cmd
# From on-premises machine
mstsc.exe /v:10.0.2.10  # Launch Remote Desktop
# Should authenticate to Azure VM
```

### Step 6.2: Test Azure to On-Premises

1. From Azure VM, access on-premises resources:
```powershell
# From Azure VM PowerShell
Test-NetConnection -ComputerName 192.168.1.10 -Port 3389  # DC
# Expected: TcpTestSucceeded = True

# Verify AD replication (Phase 6)
nltest.exe /dsgetdc:contoso.local
```

---

## Validation Checklist

- [ ] Virtual Network created with correct address space (10.0.0.0/16)
- [ ] Subnets created (management, application, database, gateway)
- [ ] Network Security Groups created and rules applied
- [ ] VPN Gateway created (status: "Succeeded")
- [ ] Local Network Gateway created with on-prem IP and network CIDR
- [ ] VPN Connection created and status shows "Connected"
- [ ] Ping from on-prem to Azure VM successful
- [ ] RDP from on-prem to Azure VM successful
- [ ] Bidirectional traffic flowing across VPN

---

*Phase 7 Completion Date: ___________*
*Document Version: 1.0*
*Last Updated: March 2, 2026*
