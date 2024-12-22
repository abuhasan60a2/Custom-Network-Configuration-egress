# Custom Bridge Network with Egress Traffic Testing

This document outlines the setup and testing of a custom bridge network configuration that demonstrates network isolation and egress traffic capabilities.

## Components

1. Custom Bridge Network
   - Network Name: custom-bridge
   - Network Range: 172.20.0.0/24
   - Bridge IP: 172.20.0.1

2. Network Namespace
   - Namespace Name: egress-test
   - Container IP: 172.20.0.2
   - Connected via veth pair

3. Network Policies
   - IP forwarding enabled
   - NAT configuration for egress traffic
   - Forward chain rules for bridge traffic

## Setup Instructions

1. Ensure you have root/sudo privileges
2. Run the following commands:
   ```bash
   sudo make all
   ```

This will:
- Create the custom bridge network
- Set up the network namespace
- Configure the veth pairs
- Apply the necessary network policies
- Test the connection

## Testing Egress Traffic

The Makefile includes a test target that pings Google's DNS server (8.8.8.8) from within the network namespace. Expected output:

```
Testing connection to Google DNS (8.8.8.8)...
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=64 time=XX.XXX ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=64 time=XX.XXX ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=64 time=XX.XXX ms
64 bytes from 8.8.8.8: icmp_seq=4 ttl=64 time=XX.XXX ms
```

## Network Isolation

The configuration ensures:
- Traffic from the namespace can only exit through the bridge
- Direct access to host network interfaces is prevented
- NAT is properly configured for egress traffic

## Cleanup

To remove all network configurations:
```bash
sudo make cleanup
```

## Troubleshooting

If ping tests fail:
1. Verify IP forwarding is enabled: `sysctl net.ipv4.ip_forward`
2. Check NAT rules: `iptables -t nat -L -n -v`
3. Verify namespace configuration: `ip netns exec egress-test ip addr`
4. Check bridge interface: `ip addr show custom-bridge`