# Failure Modes — TD2 Network Hardening

**Appendix:** failure_modes.md  
**Date:** 2026-04-10

---

## Known Failure Modes

| ID | Failure | Symptom | Fix |
|---|---|---|---|
| FM-01 | IP forwarding disabled | LAN↔DMZ traffic never arrives at dst | `sysctl -w net.ipv4.ip_forward=1` on gw-fw |
| FM-02 | Default DROP before allow rules | Everything breaks instantly | Add essential allows first, THEN change policy |
| FM-03 | Loopback forgotten | Local services on gw-fw fail | `nft add rule inet filter input iif lo accept` |
| FM-04 | Stateful rule missing | Return traffic blocked; one-way flows only | Add `ct state established,related counter accept` |
| FM-05 | Rules on wrong chain | INPUT vs FORWARD confusion | FORWARD = transit traffic; INPUT = traffic to gw-fw |
| FM-06 | Logging noise | Syslog flooded, VM sluggish | Rate-limit log rules (`limit rate 10/minute`) |
| FM-07 | Rules too broad | `0.0.0.0/0` allows unintended traffic | Scope each rule to specific src/dst/port |
| FM-08 | NAT confusion | Unexpected address translation | Do not add NAT unless explicitly required |
| FM-09 | TLS version mismatch | Legitimate clients rejected | Confirm client supports TLS 1.2+ before disabling old versions |
| FM-10 | Self-signed certificate warnings | curl/browser rejects connection | Use `-k` flag in testing; deploy real cert in production |
| FM-11 | nginx filter too aggressive | Valid clients get 403 | Check nginx `server_name` and `location` blocks |

---

## Observed Issues During TD2

### Issue 1 — nmap baseline missed HTTPS (port 443)

**Observation:** The initial nmap scan (`nmap_srvweb.txt`) only shows ports 22/SSH and 80/HTTP open. Port 443/HTTPS does not appear.  
**Root cause:** nmap was run before TLS/HTTPS was configured on srv-web.  
**Impact:** Baseline scan is not representative of the hardened state.  
**Mitigation:** Re-run nmap after hardening to confirm 443 appears and legacy ports are closed.

### Issue 2 — Self-signed certificate in use

**Observation:** Certificate CN=td4.local, valid only 7 days (Apr 10–17 2026), self-signed (issuer = subject).  
**Root cause:** Lab environment certificate, not issued by a trusted CA.  
**Impact:** All curl and browser tests require `-k` (insecure) flag; certificate verification fails.  
**Mitigation:** Accept for lab context. In production, deploy a CA-signed certificate.

### Issue 3 — TLS 1.0/1.1 rejection at application layer, not firewall layer

**Observation:** TLS 1.0 and TLS 1.1 rejection (SSL alert 70) is handled by nginx, not by nftables rules.  
**Impact:** No NFT_FWD_DENY log entry for these protocols; they reach the server before being rejected.  
**Mitigation:** This is the correct architecture. Application-layer TLS enforcement is valid hardening. Firewall-layer TLS filtering would require deep packet inspection.

---

## Limitations

- **DMZ → LAN not explicitly blocked at firewall layer:** The FORWARD chain DROP policy covers this, but no specific logging rule exists for DMZ-originated traffic.
- **No egress filtering from gw-fw OUTPUT chain:** gw-fw can initiate any outbound connection.
- **No IDS/IPS integration:** sensor-ids VM is deployed but not actively correlated in this TD.
- **Certificate management:** The self-signed cert expires in 7 days; no automated renewal.
