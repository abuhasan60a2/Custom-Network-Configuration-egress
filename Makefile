# Makefile for network configuration and testing
.PHONY: all create-network create-namespace apply-policy test-connection cleanup

# Variables
NAMESPACE=egress-test
NETWORK_NAME=custom-bridge
POD_NAME=test-pod

all: create-network create-namespace apply-policy test-connection

create-network:
	@echo "Creating custom bridge network..."
	ip link add $(NETWORK_NAME) type bridge
	ip link set $(NETWORK_NAME) up
	ip addr add 172.20.0.1/24 dev $(NETWORK_NAME)

create-namespace:
	@echo "Creating network namespace..."
	ip netns add $(NAMESPACE)
	# Create veth pair
	ip link add veth0 type veth peer name veth1
	# Move one end to namespace
	ip link set veth1 netns $(NAMESPACE)
	# Connect other end to bridge
	ip link set veth0 master $(NETWORK_NAME)
	# Configure interfaces
	ip link set veth0 up
	ip netns exec $(NAMESPACE) ip link set veth1 up
	ip netns exec $(NAMESPACE) ip addr add 172.20.0.2/24 dev veth1
	# Add default route in namespace
	ip netns exec $(NAMESPACE) ip route add default via 172.20.0.1

apply-policy:
	@echo "Applying network policy..."
	# Enable IP forwarding
	sysctl -w net.ipv4.ip_forward=1
	# Configure NAT for egress traffic
	iptables -t nat -A POSTROUTING -s 172.20.0.0/24 -j MASQUERADE
	# Allow forwarding
	iptables -A FORWARD -i $(NETWORK_NAME) -j ACCEPT
	iptables -A FORWARD -o $(NETWORK_NAME) -j ACCEPT

test-connection:
	@echo "Testing connection to Google DNS (8.8.8.8)..."
	ip netns exec $(NAMESPACE) ping -c 4 8.8.8.8

cleanup:
	@echo "Cleaning up network configuration..."
	ip link delete $(NETWORK_NAME)
	ip netns delete $(NAMESPACE)
	iptables -t nat -D POSTROUTING -s 172.20.0.0/24 -j MASQUERADE
	iptables -D FORWARD -i $(NETWORK_NAME) -j ACCEPT
	iptables -D FORWARD -o $(NETWORK_NAME) -j ACCEPT