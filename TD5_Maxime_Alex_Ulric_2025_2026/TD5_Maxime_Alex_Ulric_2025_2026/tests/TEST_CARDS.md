# 📋 Test Cards Pack - TD5 Network Hardening

## TD5-T01 — SSH password auth is disabled
**Claim:** Password-based SSH login is rejected.
* **Test (positive):** Key-based login succeeds for `admin1`.
* **Test (negative):** `ssh -o PubkeyAuthentication=no admin1@10.10.20.10` → "Permission denied (publickey)".
* **Evidence:** `evidence/ssh_tests.txt`, `evidence/authlog_excerpt.txt`

---

## TD5-T02 — Root login via SSH is disabled
**Claim:** Direct root SSH login is blocked to enforce administrative accountability.
* **Test (negative):** `ssh root@10.10.20.10` → Access denied by server configuration.
* **Evidence:** `evidence/ssh_tests.txt`

---

## TD5-T03 — Only intended admin user can connect with key
**Claim:** `AllowUsers` restricts SSH access exclusively to the designated `admin1` account.
* **Test (negative):** Attempt SSH as a different system user → Access denied.
* **Evidence:** `evidence/authlog_excerpt.txt`

---

## TD5-T04 — SSH logs provide audit trail
**Claim:** `/var/log/auth.log` records both accepts and denies with username, method, and source IP.
* **Test:** Inspect `auth.log` after performing positive and negative tests.
* **Evidence:** `evidence/authlog_excerpt.txt`

---

## TD5-T05 — IKEv2 tunnel establishes
**Claim:** `ipsec statusall` shows IKE_SA ESTABLISHED and CHILD_SA INSTALLED.
* **Test (positive):** Run `ipsec statusall` on both gateways after service restart.
* **Evidence:** `evidence/ipsec_status.txt`

---

## TD5-T06 — Traffic passes over tunnel
**Claim:** Traffic from `siteA-client` to `siteB-srv` is encapsulated within the IPsec tunnel.
* **Test (positive):** `ping -c 4 10.10.20.10` from `siteA-client` succeeds.
* **Telemetry:** `tcpdump` on the WAN interface shows ESP packets (Protocol 50), confirming no cleartext ICMP is present on the WAN.
* **Evidence:** `evidence/tunnel_ping.txt`, `evidence/optional_esp_capture.txt`

---

## TD5-T07 — Tunnel is scoped to intended subnets
**Claim:** IPsec configuration strictly limits traffic to LAN (10.10.10.0/24) ↔ DMZ (10.10.20.0/24).
* **Test:** Verify `leftsubnet` and `rightsubnet` parameters in the configuration files.
* **Evidence:** `config/ipsec_siteA.conf`, `config/ipsec_siteB.conf`

---

## TD5-T08 — Firewall permits only required IPsec ports on WAN
**Claim:** Only UDP 500 (IKE) and UDP 4500 (NAT-T) are permitted on the WAN segment for negotiation.
* **Test (positive):** Tunnel establishes successfully with these ports open.
* **Test (negative):** Blocking UDP 500 results in a failure to negotiate the IKE_SA.
* **Evidence:** `evidence/ipsec_status.txt` (verification of status after port check)