#!/usr/bin/env bash
# Shingle network firewall — only allow Anthropic API, npm registry, and DNS
set -euo pipefail

# Only run if iptables is available (skip on hosts without it)
if ! command -v iptables &>/dev/null; then
  echo "[firewall] iptables not found, skipping firewall setup"
  exit 0
fi

# Flush existing rules
iptables -F OUTPUT 2>/dev/null || true

# Allow loopback
iptables -A OUTPUT -o lo -j ACCEPT

# Allow DNS (UDP and TCP port 53)
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow established connections
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Resolve and allow specific hosts
for host in api.anthropic.com registry.npmjs.org statsig.anthropic.com www.federalregister.gov; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# Default: drop everything else
iptables -A OUTPUT -j DROP

echo "[firewall] Network locked down — only Anthropic API, npm, Federal Register, and DNS allowed"
