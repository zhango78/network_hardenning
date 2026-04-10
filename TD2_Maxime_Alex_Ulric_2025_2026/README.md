# TD2 — Network Hardening: Firewall Policy Evidence Pack

**Group:** Lab Group  
**Date:** 2026-04-10  
**Module:** Network Hardening (4th-year engineering)  
**Normative anchor:** NIST SP 800-41 Rev.1

---

## Topology

| VM | Role | Zone | IP |
|---|---|---|---|
| gw-fw | Policy enforcement point (FORWARD chain) | NH-LAN + NH-DMZ | 10.10.10.10 / 10.10.20.10 |
| client | Traffic generator, test executor | NH-LAN | 10.10.10.50 |
| srv-web | DMZ target service (HTTP, HTTPS, SSH) | NH-DMZ | 10.10.20.20 |
| sensor-ids | Capture validation | NH-DMZ | 10.10.20.50 |

## How to reproduce

1. Boot the 4-VM lab environment (VirtualBox)
2. Apply the firewall ruleset: `sudo nft -f config/firewall_ruleset.txt`
3. Run verification tests from `tests/commands.txt`
4. Collect evidence via `nft list ruleset` and `journalctl`

## Rollback

In case of lockout:
```bash
bash config/rollback.sh
```

## Key findings (summary)

- **HTTPS hardening confirmed:** TLS 1.0 and TLS 1.1 rejected by srv-web (see `evidence/`)
- **TLS 1.2 + 1.3 only** accepted (testssl.sh scan)
- **HTTP filter active:** Requests to srv-web without valid host header return HTTP 403
- **Nmap baseline:** srv-web exposes SSH/22 and HTTP/80 pre-hardening; HTTPS/443 added post-hardening
