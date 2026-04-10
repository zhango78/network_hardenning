# Phase 1 — Security Claims Table

Every claim listed below corresponds to a specific configuration snippet, a repeatable test, and a telemetry artifact providing proof of enforcement.

| Claim ID | Claim (one sentence) | Control location | Proof artifact |
| :--- | :--- | :--- | :--- |
| **C01** | The firewall enforces a default-deny policy, allowing only TCP/443 and ICMP from the Internet. | `controls/firewall/` | `evidence/after/firewall_drops.txt` |
| **C02** | SSH is restricted to `admin1` via Ed25519 keys; password auth and root login are disabled. | `controls/remote_access/` | `evidence/after/ssh_tests.txt` |
| **C03** | TLS configuration supports only version 1.2 and 1.3 with secure cipher suites. | `controls/tls_edge/` | `evidence/after/tls_scan.txt` |
| **C04** | All traffic between Site A and Site B is encrypted via a Site-to-Site IPsec IKEv2 tunnel. | `controls/remote_access/` | `evidence/after/ipsec_status.txt` |
| **C05** | The IDS (Suricata) detects unauthorized access attempts to restricted paths like `/admin`. | `controls/ids/` | `evidence/after/ids_alerts.txt` |
| **C06** | HSTS is enabled to enforce secure HTTPS connections for all web clients. | `controls/tls_edge/` | `evidence/after/tls_scan.txt` |
| **C07** | Only TCP 80, 443, 22 and ICMP echo are permitted to cross the gateway firewall. | `controls/firewall/` | `evidence/after/counters.txt` |
| **C08** | Rate limiting is active on the edge to block burst or DoS-like traffic patterns. | `controls/tls_edge/` | `evidence/after/rate_limit.txt` |

---
**Note:** Each proof artifact can be re-generated using the automated regression suite located in `tests/regression/`.