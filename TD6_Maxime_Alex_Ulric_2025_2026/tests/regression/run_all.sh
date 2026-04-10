#!/bin/bash
# Regression test suite — Network Hardening Final Pack
set -euo pipefail

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="tests/regression/results/${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

echo "=== Regression Suite — $TIMESTAMP ==="
PASS=0
FAIL=0

run_test() {
    local script="$1"
    local name="$2"
    echo -n "Running $name... "
    if bash "$script" > "$RESULTS_DIR/${name}.txt" 2>&1; then
        echo "PASS"
        ((PASS++))
    else
        echo "FAIL (see $RESULTS_DIR/${name}.txt)"
        ((FAIL++))
    fi
}

run_test tests/regression/R1_firewall.sh     "R1_firewall"
run_test tests/regression/R2_tls.sh          "R2_tls"
run_test tests/regression/R3_remote_access.sh "R3_remote_access"
run_test tests/regression/R4_detection.sh    "R4_detection"

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
echo "Outputs: $RESULTS_DIR/"

[ "$FAIL" -eq 0 ] && exit 0 || exit 1