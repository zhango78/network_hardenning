# TEST_CARDS.md — TD2 Network Hardening

**Enforcement point:** gw-fw  
**Test executor:** client (10.10.10.50)  
**Target:** srv-web (10.10.20.20)  
**Date:** 2026-04-10

---

## TD2-T01 — Allowed HTTP flow passes

**Claim:** HTTP (TCP/80) from LAN to srv-web is forwarded by gw-fw.  
**Policy ref:** A1  
**Type:** Positive

**Test command:**
```bash
curl -sI http://10.10.20.20 | head -5
```

**Expected result:** HTTP 200 OK  
**Actual result:** HTTP 200 OK — nginx/1.18.0 (Ubuntu) — confirmed in `curl_before.txt`  
**Status:** PASS  
**Evidence:** `../evidence/curl_before.txt`

---

## TD2-T02 — Allowed HTTPS flow passes (TLS 1.3)

**Claim:** HTTPS (TCP/443) from LAN to srv-web is forwarded; TLS 1.3 is negotiated.  
**Policy ref:** A2  
**Type:** Positive

**Test command:**
```bash
curl -skv https://10.10.20.20
```

**Expected result:** TLS 1.3 handshake, HTTP 200 or 403  
**Actual result:** TLS_AES_256_GCM_SHA384 / x25519 — confirmed in `curl_vk.txt`  
**Status:** PASS  
**Evidence:** `../evidence/curl_vk.txt`

---

## TD2-T03 — TLS 1.0 rejected

**Claim:** srv-web rejects TLS 1.0 connections with a protocol version alert.  
**Policy ref:** TLS Policy §4  
**Type:** Negative

**Test command:**
```bash
openssl s_client -connect 10.10.20.20:443 -tls1 < /dev/null
```

**Expected result:** SSL alert number 70 (protocol_version), no certificate presented  
**Actual result:** `error:0A00042E: tlsv1 alert protocol version` — SSL alert 70  
**Status:** PASS (correctly rejected)  
**Evidence:** `../evidence/failed_tls1.txt`, `../evidence/openssl_tls1_before.txt`

---

## TD2-T04 — TLS 1.1 rejected

**Claim:** srv-web rejects TLS 1.1 connections with a protocol version alert.  
**Policy ref:** TLS Policy §4  
**Type:** Negative

**Test command:**
```bash
openssl s_client -connect 10.10.20.20:443 -tls1_1 < /dev/null
```

**Expected result:** SSL alert number 70 (protocol_version), no certificate presented  
**Actual result:** `error:0A00042E: tlsv1 alert protocol version` — SSL alert 70  
**Status:** PASS (correctly rejected)  
**Evidence:** `../evidence/failed_tls1_1.txt`

---

## TD2-T05 — TLS 1.2 accepted with strong cipher

**Claim:** srv-web accepts TLS 1.2 with ECDHE-RSA-AES256-GCM-SHA384.  
**Policy ref:** TLS Policy §4  
**Type:** Positive

**Test command:**
```bash
openssl s_client -connect 10.10.20.20:443 -tls1_2 < /dev/null
```

**Expected result:** Handshake OK, cipher ECDHE-RSA-AES256-GCM-SHA384  
**Actual result:** TLSv1.2 — ECDHE-RSA-AES256-GCM-SHA384 — confirmed  
**Status:** PASS  
**Evidence:** `../evidence/openssl_s_client.txt`

---

## TD2-T06 — HTTP 403 returned for filtered requests

**Claim:** nginx returns HTTP 403 Forbidden for requests that do not match a valid virtual host/location.  
**Policy ref:** HTTP Request Filtering §5  
**Type:** Negative

**Test command:**
```bash
curl -sk https://10.10.20.20/ -H "Host: vk.local" -o /dev/null -w "%{http_code}"
```

**Expected result:** HTTP 403 Forbidden  
**Actual result:** HTTP 403 Forbidden — nginx/1.18.0  
**Status:** PASS (correctly filtered)  
**Evidence:** `../evidence/request_filter.txt`, `../evidence/curl_vk.txt`

---

## TD2-T07 — TLS scan confirms only TLS 1.2 + 1.3 offered

**Claim:** testssl.sh confirms SSLv2, SSLv3, TLS 1.0, TLS 1.1 are not offered; only TLS 1.2 and 1.3 are available.  
**Policy ref:** TLS Policy §4  
**Type:** Positive (comprehensive scan)

**Test command:**
```bash
testssl.sh 10.10.20.20:443
```

**Expected result:**
- SSLv2: not offered (OK)
- SSLv3: not offered (OK)
- TLS 1.0: not offered
- TLS 1.1: not offered
- TLS 1.2: offered (OK)
- TLS 1.3: offered (OK)

**Actual result:** Matches expected exactly  
**Status:** PASS  
**Evidence:** `../evidence/tls_scan.txt`

---

## TD2-T08 (Bonus) — Rollback restores permissive state

**Claim:** `rollback.sh` flushes all nft rules and restores full connectivity within 30 seconds.  
**Policy ref:** Implementation requirement  
**Type:** Positive

**Test command:**
```bash
bash config/rollback.sh
sudo nft list ruleset
curl -sI http://10.10.20.20
```

**Expected result:** Empty ruleset, all traffic passes  
**Status:** Not executed (would disrupt other tests) — script verified by review  
**Evidence:** `../config/rollback.sh`
