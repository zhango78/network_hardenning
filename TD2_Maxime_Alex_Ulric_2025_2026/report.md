# TD2 — Network Hardening Report

**Module:** Network Hardening (4th-year engineering)  
**Normative anchor:** NIST SP 800-41 Rev.1  
**Date:** 2026-04-10  
**Deliverable:** Evidence pack — config + test + telemetry

---

## 1. Topology Summary

| VM | Role | Zone | IP |
|---|---|---|---|
| gw-fw | Policy enforcement point (FORWARD chain) | NH-LAN + NH-DMZ | 10.10.10.1 / 10.10.20.1 |
| client | Traffic generator, test executor | NH-LAN | 10.10.10.50 |
| srv-web | DMZ target service | NH-DMZ | 10.10.20.20 |
| sensor-ids | Capture validation | NH-DMZ | 10.10.20.50 |

**Zone diagram:**

```
  NH-LAN (10.10.10.0/24)          NH-DMZ (10.10.20.0/24)
  ┌─────────────────┐              ┌──────────────────────┐
  │  client         │              │  srv-web (10.10.20.20)│
  │  (10.10.10.50)  │              │  nginx + TLS 1.2/1.3  │
  └────────┬────────┘              └──────────┬───────────┘
           │                                  │
           └──────────── gw-fw ───────────────┘
                    10.10.10.1 / 10.10.20.1
                    FORWARD: DROP (default)
                    INPUT: DROP (default)
```

---

## 2. Policy Statement

Reference: `config/policy.md`

The policy follows a **least-privilege, allow-list** approach:

- **Default FORWARD:** DROP — all inter-zone traffic is denied unless explicitly permitted
- **Default INPUT:** DROP — gw-fw is protected; only LAN SSH access is allowed
- **Allowed flows:** HTTP/80, HTTPS/443, SSH/22 from LAN to DMZ srv-web; ICMP (rate-limited)
- **TLS policy:** Only TLS 1.2 and TLS 1.3 accepted on srv-web; TLS 1.0/1.1, SSLv2/SSLv3 disabled
- **HTTP filtering:** nginx returns HTTP 403 for unrecognized virtual hosts

---

## 3. Implementation Notes

**Tool choice:** nftables (preferred per TD2 guidance)

**Key implementation decisions:**

1. **Stateful tracking first** — `ct state established,related accept` added before any per-flow rule to ensure return traffic is not blocked
2. **Loopback** — explicit `iif lo accept` in INPUT chain
3. **Rate-limited ICMP** — 5 packets/second limit on ICMP echo to DMZ to prevent ping floods
4. **Rate-limited deny logging** — 10 entries/minute to avoid syslog saturation (FM-06)
5. **TLS hardening on srv-web** — configured via nginx `ssl_protocols TLSv1.2 TLSv1.3` directive, not at firewall layer
6. **HTTP 403 filter** — nginx `server_name` matching rejects requests for unknown virtual hosts

**IP forwarding:** Confirmed enabled via `sysctl net.ipv4.ip_forward=1` on gw-fw.

---

## 4. Test Results

### 4.1 Positive Tests Summary

| Test | Description | Expected | Result | Evidence |
|---|---|---|---|---|
| P1 | HTTP to srv-web | HTTP 200 OK | PASS | curl_before.txt |
| P2 | HTTPS TLS 1.3 to srv-web | TLS_AES_256_GCM_SHA384 | PASS | curl_vk.txt |
| P3 | SSH to srv-web | Connection established | PASS | commands.txt |
| P4 | ICMP ping to srv-web | Reply received | PASS | commands.txt |
| P5 | SSH to gw-fw from LAN | Connection established | PASS | commands.txt |
| P6 | ICMP ping to gw-fw | Reply received | PASS | commands.txt |
| P7 | TLS 1.2 accepted | Handshake OK | PASS | openssl_s_client.txt |
| P8 | TLS 1.3 accepted | Handshake OK | PASS | curl_vk.txt |

### 4.2 Negative Tests Summary

| Test | Description | Expected | Result | Evidence |
|---|---|---|---|---|
| N1 | TCP 12345 to srv-web | Timeout / blocked | PASS | deny_logs.txt |
| N2 | TCP 3306 MySQL to srv-web | Timeout / blocked | PASS | deny_logs.txt |
| N3 | UDP 53 DNS to srv-web | Timeout / blocked | PASS | deny_logs.txt |
| N4 | TCP 23 Telnet to srv-web | Timeout / blocked | PASS | deny_logs.txt |
| N5 | TLS 1.0 to srv-web | SSL alert 70 | PASS | failed_tls1.txt |
| N6 | TLS 1.1 to srv-web | SSL alert 70 | PASS | failed_tls1_1.txt |
| N7 | HTTP 403 on unknown vhost | HTTP 403 Forbidden | PASS | curl_vk.txt, request_filter.txt |
| N8 | DMZ SSH to gw-fw | Blocked (INPUT DROP) | PASS | deny_logs.txt |

---

## 5. Counter Analysis

**Before tests:** All counters at 0 (baseline)  
**After tests:**

| Rule | Packets | Interpretation |
|---|---|---|
| forward A1-http | 8 | P1 HTTP test confirmed forwarded |
| forward A2-https | 24 | P2, P7, P8 HTTPS tests confirmed forwarded |
| forward A3-ssh | 3 | P3 SSH test confirmed forwarded |
| forward A4-icmp | 4 | P4 ICMP test confirmed forwarded |
| input A6-ssh | 3 | P5 SSH to gw-fw confirmed |
| forward NFT_FWD_DENY | 18 | N1-N4 + unlisted ports confirmed dropped |
| input NFT_IN_DENY | 6 | N8 + unauthorized INPUT confirmed dropped |

The deny counter incremented after each negative test, confirming enforcement is active.

Reference: `evidence/counters_before.txt`, `evidence/counters_after.txt`

---

## 6. Known Limitations

1. **No DMZ → LAN explicit logging:** Covered by default DROP but no dedicated log prefix for DMZ-originated forward traffic
2. **No egress filtering** on gw-fw OUTPUT chain
3. **Self-signed certificate** on srv-web — expires 2026-04-17; not trusted by default CA stores
4. **No IDS correlation** — sensor-ids deployed but not integrated into alert pipeline
5. **TLS filtering at application layer only** — deep packet inspection not implemented at gw-fw
6. **No IPv6 rules** — only inet (IPv4) table configured

---

## 7. Test Cards Reference

See `tests/TEST_CARDS.md` for 8 detailed test cards (TD2-T01 through TD2-T08).

---

## 8. Appendix

See `appendix/failure_modes.md` for documented failure modes and observed issues during TD2.
