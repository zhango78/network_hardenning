#!/bin/bash
# R1: Verify firewall still enforces policy
echo "=== R1 Firewall Regression ==="

# Positive: HTTP to srv-web should work
echo -n "P1: HTTP → srv-web... "
STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://10.10.20.10)
[ "$STATUS" = "200" ] && echo "PASS" || { echo "FAIL (got $STATUS)"; exit 1; }

# Positive: SSH to srv-web should work  
echo -n "P2: SSH → srv-web... "
ssh -o ConnectTimeout=3 -o BatchMode=yes admin1@10.10.20.10 "echo ok" > /dev/null 2>&1 \
  && echo "PASS" || { echo "FAIL"; exit 1; }

# Negative: Random port should timeout
echo -n "N1: Port 12345 → srv-web... "
nc -vz -w 3 10.10.20.10 12345 > /dev/null 2>&1 \
  && { echo "FAIL (should be blocked)"; exit 1; } || echo "PASS (blocked)"

# Negative: MySQL should timeout
echo -n "N2: Port 3306 → srv-web... "
nc -vz -w 3 10.10.20.10 3306 > /dev/null 2>&1 \
  && { echo "FAIL (should be blocked)"; exit 1; } || echo "PASS (blocked)"

echo "R1: All checks passed"