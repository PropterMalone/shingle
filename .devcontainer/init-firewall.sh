#!/usr/bin/env bash
# Shingle network firewall — allowlist for Anthropic services, auth, npm, and data sources
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

# Anthropic API and telemetry
for host in api.anthropic.com statsig.anthropic.com sentry.io; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# OAuth / Claude subscription login (Claude Pro/Max)
for host in claude.ai accounts.anthropic.com auth.anthropic.com console.anthropic.com; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# npm registry (for vite and package installs)
for host in registry.npmjs.org; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# Data sources (practice-area specific)
for host in www.federalregister.gov; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# GitHub (for ed3d plugin updates and potential future marketplace)
for host in github.com raw.githubusercontent.com; do
  for ip in $(dig +short "$host" 2>/dev/null); do
    iptables -A OUTPUT -d "$ip" -p tcp --dport 443 -j ACCEPT
  done
done

# Default: drop everything else
iptables -A OUTPUT -j DROP

echo "[firewall] Network locked down — Anthropic, auth, npm, Federal Register, and GitHub allowed"
