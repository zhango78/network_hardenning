# Change Log — TLS Hardening TD4

**Date:** 2026-04-10  
**Target:** 10.10.20.20 (nginx 1.18.0)

| Action de Durcissement | État Initial (Before) | État Final (After) | Référence NIST SP 800-52r2 |
|---|---|---|---|
| **Désactivation TLS 1.0/1.1** | `TLSv1 TLSv1.1 TLSv1.2` activés | **`TLSv1.2 TLSv1.3` uniquement** | §3.1 — SHALL NOT support TLS 1.0/1.1 |
| **Sélection des Ciphers** | `HIGH:MEDIUM` (CBC autorisé) | **`ECDHE+AESGCM:ECDHE+CHACHA20` (AEAD only)** | §3.3 — Prefer AEAD cipher suites |
| **Forward Secrecy** | Optionnel (non forcé) | **Obligatoire (ECDHE exclusif)** | §3.3.1 — Use Ephemeral Keys |
| **En-tête HSTS** | Absent | **`Strict-Transport-Security: max-age=300`** | §3.5 — SHOULD enable HSTS |
| **ssl_prefer_server_ciphers** | Off (non défini) | **On** | §3.3 — Server controls cipher negotiation |
| **Edge Control — Rate Limit** | Aucun | **1 req/s, burst=5 (zone api_limit)** | NIST SP 800-53 (Availability) |
| **Edge Control — Request Filter** | Aucun | **Blocage User-Agent curl/sqlmap/nikto** | NIST SP 800-53 (Access Control) |
| **Redirection HTTP→HTTPS** | Absent | **`return 301 https://`** | Bonne pratique |

## Détail des changements ligne par ligne

### 1. `ssl_protocols`
```diff
- ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
+ ssl_protocols TLSv1.2 TLSv1.3;
```
**Raison :** TLS 1.0/1.1 sont obsolètes (RFC 8996) et vulnérables (BEAST, POODLE). NIST SP 800-52r2 §3.1 impose leur désactivation.

### 2. `ssl_ciphers`
```diff
- ssl_ciphers HIGH:MEDIUM:!aNULL:!MD5;
+ ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!RC4;
```
**Raison :** Suppression des suites CBC (vulnérables LUCKY13, BEAST). Conservation exclusive des suites AEAD avec forward secrecy. NIST SP 800-52r2 §3.3.

### 3. `ssl_prefer_server_ciphers`
```diff
+ ssl_prefer_server_ciphers on;
```
**Raison :** Permet au serveur d'imposer sa politique de chiffrement plutôt que de laisser le client choisir.

### 4. HSTS header
```diff
+ add_header Strict-Transport-Security "max-age=300" always;
```
**Raison :** Force les clients à utiliser HTTPS. `max-age=300` (5 min) adapté au lab pour éviter de verrouiller un navigateur de test.

### 5. Rate limiting
```diff
+ limit_req_zone $binary_remote_addr zone=api_limit:10m rate=1r/s;
  location / {
+     limit_req zone=api_limit burst=5 nodelay;
  }
```
**Raison :** Protection contre les rafales de requêtes (DoS applicatif).

### 6. Request filtering
```diff
+ if ($http_user_agent ~* "curl|sqlmap|nikto|masscan|nmap") {
+     return 403;
+ }
```
**Raison :** Blocage des User-Agents d'outils de scan connus. Démonstration du concept WAF (edge enforcement).
