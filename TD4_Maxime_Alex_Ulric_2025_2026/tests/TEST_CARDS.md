# Test Cards — TD4 TLS Audit and Hardening

**Reference:** TD4 Network Hardening  
**Date:** 2026-04-10

---

## TD4-T01 — Baseline offers legacy TLS versions

**Claim:** The baseline endpoint offers TLS 1.0 and TLS 1.1 (documented weakness).

**Preconditions:**
- `nginx_before.conf` deployed on srv-web (10.10.20.20)
- `ssl_protocols TLSv1 TLSv1.1 TLSv1.2;` active

**Configuration fragment:**
```nginx
ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
```

**Test method:**

*Positive test (should succeed):*
```bash
openssl s_client -connect 10.10.20.20:443 -tls1 </dev/null
# Expected: connection succeeds, Protocol: TLSv1
```

*Negative test (should fail with hardened config):*
```bash
openssl s_client -connect 10.10.20.20:443 -tls1 </dev/null
# Expected: SSL alert number 70 (protocol_version)
```

**Telemetry / evidence:**
- File: `evidence/before/tls_scan.txt` — testssl.sh showing `TLS 1 offered`
- File: `evidence/before/openssl_tls1_before.txt` — successful TLS 1.0 handshake

**Result:** PASS

**Artifacts:**
- `evidence/before/tls_scan.txt`
- `evidence/before/openssl_tls1_before.txt`

---

## TD4-T02 — After hardening, legacy TLS versions are rejected

**Claim:** TLS 1.0 and TLS 1.1 are rejected after hardening (SSL alert 70).

**Preconditions:**
- `nginx_after.conf` deployed on srv-web
- `ssl_protocols TLSv1.2 TLSv1.3;` active

**Configuration fragment:**
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

**Test method:**

*Positive test (should succeed — TLS 1.2):*
```bash
openssl s_client -connect 10.10.20.20:443 -tls1_2 </dev/null
# Expected: connection succeeds, Protocol: TLSv1.2
```

*Negative test (should fail — TLS 1.0):*
```bash
openssl s_client -connect 10.10.20.20:443 -tls1 </dev/null
# Expected: error:0A00042E — SSL alert number 70
```

*Negative test (should fail — TLS 1.1):*
```bash
openssl s_client -connect 10.10.20.20:443 -tls1_1 </dev/null
# Expected: error:0A00042E — SSL alert number 70
```

**Telemetry / evidence:**
- File: `evidence/after/failed_tls1.txt` — SSL alert 70 for TLS 1.0
- File: `evidence/after/failed_tls1_1.txt` — SSL alert 70 for TLS 1.1
- File: `evidence/after/tls_scan.txt` — testssl.sh showing `TLS 1 not offered`, `TLS 1.1 not offered`

**Result:** PASS

**Artifacts:**
- `evidence/after/failed_tls1.txt`
- `evidence/after/failed_tls1_1.txt`
- `evidence/after/tls_scan.txt`

---

## TD4-T03 — Cipher policy enforces forward secrecy

**Claim:** All negotiated cipher suites provide forward secrecy (ECDHE).

**Preconditions:**
- `nginx_after.conf` deployed
- `ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!RC4;` active

**Configuration fragment:**
```nginx
ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!RC4;
ssl_prefer_server_ciphers on;
```

**Test method:**

*Positive test:*
```bash
openssl s_client -connect 10.10.20.20:443 </dev/null 2>&1 | grep -E "Cipher|Protocol"
# Expected: Cipher is ECDHE-RSA-AES256-GCM-SHA384 or TLS_AES_256_GCM_SHA384
```

*Negative test (weak cipher — should be refused):*
```bash
openssl s_client -connect 10.10.20.20:443 -cipher "AES128-SHA" </dev/null
# Expected: handshake failure (no matching cipher)
```

**Telemetry / evidence:**
- File: `evidence/after/openssl_s_client.txt` — `Cipher is ECDHE-RSA-AES256-GCM-SHA384`
- File: `evidence/after/tls_scan.txt` — testssl.sh showing ECDHE suites only

**Result:** PASS

**Artifacts:**
- `evidence/after/openssl_s_client.txt`
- `evidence/after/tls_scan.txt`

---

## TD4-T04 — Certificate matches lab trust model

**Claim:** Certificate subject, validity, and chain match the documented trust model (self-signed, CN=td4.local, RSA 2048).

**Preconditions:**
- Certificate deployed at `/etc/nginx/certs/server.crt`
- Self-signed lab certificate

**Test method:**

*Positive test:*
```bash
openssl s_client -connect 10.10.20.20:443 </dev/null 2>&1 | openssl x509 -noout -subject -dates -issuer
# Expected:
#   subject=CN=td4.local
#   notBefore=Apr 10 09:36:29 2026 GMT
#   notAfter=Apr 17 09:36:29 2026 GMT
#   issuer=CN=td4.local
```

**Telemetry / evidence:**
- File: `evidence/after/openssl_s_client.txt` — certificate chain, subject CN=td4.local
- File: `evidence/after/curl_vk.txt` — `subject: CN=td4.local`, `issuer: CN=td4.local`

**Result:** PASS

**Artifacts:**
- `evidence/after/openssl_s_client.txt`
- `evidence/after/curl_vk.txt`

---

## TD4-T05 — Rate limiting triggers on burst traffic

**Claim:** Burst requests exceeding the configured limit return 503 Service Unavailable after the burst threshold.

**Preconditions:**
- `nginx_after.conf` deployed
- `limit_req_zone` zone: 1r/s, burst=5

**Configuration fragment:**
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=1r/s;
location / {
    limit_req zone=api_limit burst=5 nodelay;
}
```

**Test method:**

*Positive test (single request — should succeed):*
```bash
curl -sk https://10.10.20.20/
# Expected: HTTP 200 (or 403 if User-Agent filtered)
```

*Negative test (burst — rate limit should trigger):*
```bash
for i in $(seq 1 30); do curl -sk -A "legit-browser/1.0" https://10.10.20.20/; done
# Expected: first 5-6 requests 200, then 503 Service Unavailable
```

**Telemetry / evidence:**
- File: `evidence/after/rate_limit_test.txt` — mix of 200 and 503 responses

**Result:** PASS

**Artifacts:**
- `evidence/after/rate_limit_test.txt`

---

## TD4-T06 — Request filtering blocks malicious pattern

**Claim:** Requests with scan tool User-Agents (curl, sqlmap, nikto) are blocked with HTTP 403 Forbidden.

**Preconditions:**
- `nginx_after.conf` deployed
- User-Agent filter active: `if ($http_user_agent ~* "curl|sqlmap|nikto")`

**Configuration fragment:**
```nginx
if ($http_user_agent ~* "curl|sqlmap|nikto|masscan|nmap") {
    return 403;
}
```

**Test method:**

*Positive test (legitimate User-Agent — should succeed):*
```bash
curl -sk -A "Mozilla/5.0" https://10.10.20.20/
# Expected: HTTP 200
```

*Negative test (scan tool User-Agent — should be blocked):*
```bash
curl -sk -A "sqlmap/1.0" https://10.10.20.20/
# Expected: HTTP 403 Forbidden

curl -sk https://10.10.20.20/    # curl default UA
# Expected: HTTP 403 Forbidden
```

**Telemetry / evidence:**
- File: `evidence/after/request_filter.txt` — `HTTP/1.1 403 Forbidden`
- File: `evidence/after/curl_vk.txt` — 403 response with `curl/8.18.0` User-Agent

**Result:** PASS

**Artifacts:**
- `evidence/after/request_filter.txt`
- `evidence/after/curl_vk.txt`
