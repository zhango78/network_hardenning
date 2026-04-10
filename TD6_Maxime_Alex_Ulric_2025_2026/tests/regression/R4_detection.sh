#!/bin/bash
# R4: Verify IDS detects known test traffic
echo "=== R4 Detection Regression ==="

# Clear old alerts (optional — or use timestamps to filter)
BEFORE_COUNT=$(ssh admin1@10.10.20.50 "grep -c '9000001' /var/log/suricata/fast.log 2>/dev/null" || echo 0)

# Trigger custom rule
echo -n "P1: Trigger /admin detection... "
curl -s http://10.10.20.10/admin > /dev/null
sleep 3

AFTER_COUNT=$(ssh admin1@10.10.20.50 "grep -c '9000001' /var/log/suricata/fast.log 2>/dev/null" || echo 0)

if [ "$AFTER_COUNT" -gt "$BEFORE_COUNT" ]; then
    echo "PASS (new alerts: $((AFTER_COUNT - BEFORE_COUNT)))"
else
    echo "FAIL (no new alerts for sid:9000001)"
    exit 1
fi

echo "R4: All checks passed"