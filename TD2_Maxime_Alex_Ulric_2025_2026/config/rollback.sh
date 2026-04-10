#!/bin/bash
# rollback.sh — Emergency flush script for gw-fw
# Restores a permissive state within 30 seconds
# TD2 Network Hardening — config/rollback.sh

echo "[rollback] Flushing all nft rules..."
sudo nft flush ruleset

echo "[rollback] Removing inet filter table if exists..."
sudo nft delete table inet filter 2>/dev/null || true

echo "[rollback] Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1

echo "[rollback] Done. All traffic now permissive (no firewall rules)."
echo "[rollback] Verify with: sudo nft list ruleset"
echo "[rollback] Re-apply policy with: sudo nft -f config/firewall_ruleset.txt"
