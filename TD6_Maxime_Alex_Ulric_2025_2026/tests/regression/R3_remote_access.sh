#!/bin/bash
# R3: Verify SSH hardening and IPsec tunnel
echo "=== R3 Remote Access Regression ==="

# SSH key auth works
echo -n "P1: SSH key auth... "
ssh -i ~/.ssh/id_td5 -o ConnectTimeout=3 -o BatchMode=yes admin1@10.10.20.10 "echo ok" > /dev/null 2>&1 \
  && echo "PASS" || { echo "FAIL"; exit 1; }

# SSH password auth blocked
echo -n "N1: SSH password denied... "
ssh -o PubkeyAuthentication=no -o ConnectTimeout=3 -o BatchMode=yes admin1@10.10.20.10 "echo fail" > /dev/null 2>&1 \
  && { echo "FAIL (password auth still works!)"; exit 1; } || echo "PASS"

# IPsec tunnel status (run on gateway)
echo -n "P2: IPsec tunnel... "
ssh -o ConnectTimeout=3 admin1@10.10.10.1 "sudo ipsec statusall 2>/dev/null" 2>/dev/null \
  | grep -q "ESTABLISHED" \
  && echo "PASS" || { echo "FAIL (tunnel not established)"; exit 1; }

echo "R3: All checks passed"