# Firewall Policy — TD2 Network Hardening

**Version:** 1.0  
**Date:** 2026-04-10  
**Owner:** Lab Group  
**Review date:** End of TD2 session

---

## 1. Zones

| Zone | Network | Assets |
|---|---|---|
| LAN (trusted) | NH-LAN 10.10.10.0/24 | client (10.10.10.50) |
| DMZ (semi-trusted) | NH-DMZ 10.10.20.0/24 | srv-web (10.10.20.20), sensor-ids (10.10.20.50) |
| Gateway | Both interfaces | gw-fw (10.10.10.1 / 10.10.20.1) |

---

## 2. Allow-list (derived from TD1 flow matrix)

| # | Direction | Protocol/Port | Purpose | Source |
|---|---|---|---|---|
| A1 | LAN → DMZ srv-web | TCP/80 (HTTP) | Web access | TD1 baseline |
| A2 | LAN → DMZ srv-web | TCP/443 (HTTPS) | Secure web access | TD1 baseline |
| A3 | LAN → DMZ srv-web | TCP/22 (SSH) | Admin access during lab | TD1 baseline |
| A4 | LAN → DMZ | ICMP echo | Diagnostics (rate-limited) | TD1 baseline |
| A5 | ALL | established/related | Return traffic (stateful) | Implementation requirement |
| A6 | LAN → gw-fw | TCP/22 (SSH) | Gateway admin access | Security requirement |

**Not allowed (implicit deny):**
- DMZ → LAN (any direction reversal)
- Any port not listed above (e.g., 3306/MySQL, 23/Telnet, 12345/custom)
- TLS 1.0 and TLS 1.1 (rejected at application layer by nginx)
- SSLv2, SSLv3 (rejected at application layer by nginx)

---

## 3. Default stance

| Chain | Policy | Rationale |
|---|---|---|
| FORWARD | DROP | Deny by default between zones; only explicit allows pass |
| INPUT on gw-fw | DROP | Protect the gateway itself |
| OUTPUT from gw-fw | ACCEPT | Gateway can reach both subnets for management |

---

## 4. TLS Policy (srv-web application layer)

Enforced via nginx `ssl_protocols` directive:

| Protocol | Status |
|---|---|
| SSLv2 | Disabled |
| SSLv3 | Disabled |
| TLS 1.0 | Disabled (SSL alert 70 returned) |
| TLS 1.1 | Disabled (SSL alert 70 returned) |
| TLS 1.2 | Enabled — ECDHE-RSA-AES256-GCM-SHA384 |
| TLS 1.3 | Enabled — TLS_AES_256_GCM_SHA384 / x25519 |

Evidence: `../evidence/tls_scan.txt`, `../evidence/failed_tls1.txt`, `../evidence/failed_tls1_1.txt`

---

## 5. HTTP Request Filtering

nginx returns **HTTP 403 Forbidden** for requests that do not match an allowed virtual host or location rule.  
Evidence: `../evidence/request_filter.txt`, `../evidence/curl_vk.txt`

---

## 6. Logging strategy

- Log all denied FORWARD traffic with prefix `NFT_FWD_DENY` (rate-limited: 10/minute)
- Log all denied INPUT traffic with prefix `NFT_IN_DENY` (rate-limited: 10/minute)
- Log SSH access to gw-fw (prefix `NFT_SSH_ALLOW`)
- Logs readable via: `journalctl -k | grep NFT_FWD_DENY`

---

## 7. Exception process

1. Exceptions must be requested in writing with a business justification
2. Each exception references a specific flow from the TD1 flow matrix
3. Review frequency: end of each lab session
4. No rule without a traceable origin in the flow matrix
