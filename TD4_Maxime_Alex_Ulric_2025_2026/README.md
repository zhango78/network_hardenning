# TD4 — TLS Audit and Hardening

**Module:** Network Hardening (4th-year engineering)  
**Date:** 2026-04-10  
**Target:** srv-web (10.10.20.20) — nginx 1.18.0 (Ubuntu)

---

## Setup

### Environment

| VM | Role | Zone | IP |
|---|---|---|---|
| gw-fw | Boundary / logging | NH-LAN + NH-DMZ | 10.10.10.1 / 10.10.20.1 |
| client | Scanner / tester | NH-LAN | 10.10.10.50 |
| srv-web | TLS endpoint (nginx) | NH-DMZ | 10.10.20.20 |

### How to reproduce the tests

```bash
# From client (10.10.10.50)

# 1. Baseline TLS scan
testssl.sh --fast --warnings batch https://10.10.20.20:443 | tee evidence/before/tls_scan.txt

# 2. Curl verbose
curl -vk https://10.10.20.20:443/ 2>&1 | tee evidence/before/curl_vk.txt

# 3. OpenSSL TLS 1.0 test
openssl s_client -connect 10.10.20.20:443 -tls1 </dev/null

# 4. After hardening — same commands
testssl.sh --fast --warnings batch https://10.10.20.20:443 | tee evidence/after/tls_scan.txt
curl -vk https://10.10.20.20:443/ 2>&1 | tee evidence/after/curl_vk.txt

# 5. Edge controls — rate limit test
for i in $(seq 1 30); do curl -sk https://10.10.20.20/api; done | tee evidence/after/rate_limit_test.txt

# 6. Edge controls — request filter test
curl -sk -A "sqlmap/1.0" https://10.10.20.20/ | tee evidence/after/request_filtering_test.txt
```

### Nginx reload

```bash
nginx -t && sudo systemctl reload nginx
```

---

## Repository structure

```
TD4_deliverables/
  README.md
  report.md
  config/
    nginx_before.conf
    nginx_after.conf
    change_log.md
    TLS_Profile.md
  tests/
    TEST_CARDS.md
  evidence/
    before/       (scan outputs baseline)
    after/        (scan outputs post-hardening)
  appendix/
    failure_modes.md
```
