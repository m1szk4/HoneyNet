#!/bin/bash
# Setup iptables rules for honeypot data control

set -e

echo "Configuring firewall for honeynet..."

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# SSH from management IP only (CHANGE THIS!)
# iptables -A INPUT -p tcp --dport 22 -s YOUR_MANAGEMENT_IP -j ACCEPT

# Port forwarding to honeypots
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 22 -j DNAT --to-destination 172.20.0.10:2222
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 23 -j DNAT --to-destination 172.20.0.10:2223
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 2323 -j DNAT --to-destination 172.20.0.10:2223
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination 172.20.0.11:80
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 445 -j DNAT --to-destination 172.20.0.11:445
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 502 -j DNAT --to-destination 172.20.0.12:502

# CRITICAL: Block ALL outbound from honeypot network
iptables -A FORWARD -s 172.20.0.0/24 -j LOG --log-prefix "BLOCKED-OUTBOUND: " --log-level 4
iptables -A FORWARD -s 172.20.0.0/24 -j DROP

# Allow inbound to honeypots
iptables -A FORWARD -d 172.20.0.0/24 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4

echo "✓ Firewall configured successfully"
echo "⚠ Remember to update SSH rule with your management IP!"