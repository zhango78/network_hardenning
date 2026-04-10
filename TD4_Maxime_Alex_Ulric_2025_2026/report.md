# TD4 — TLS Audit and Hardening : Report

**Date:** 2026-04-10  
**Target:** 10.10.20.20 (srv-web, nginx 1.18.0)  
**Client:** 10.10.10.50 (Kali Linux)

---

## 1. Threat Model

**Asset:** Service web nginx sur srv-web (10.10.20.20) — endpoint HTTP/HTTPS exposé en zone DMZ.

**Adversary:** Attaquant en position on-path sur le LAN/DMZ, ou scanner distant effectuant de la reconnaissance.

**Key threats:**
- Downgrade vers une version de protocole faible (TLS 1.0/1.1) permettant des attaques BEAST/POODLE.
- Négociation d'une suite de chiffrement sans forward secrecy (pas de clés éphémères).
- Certificat auto-signé ou expiré → l'utilisateur ignore les avertissements du navigateur.
- Configuration laxiste du edge → fuite d'information via les en-têtes ou pages d'erreur.
- Absence de limitation de débit → épuisement des ressources (DoS applicatif).

**Security goals:**
- Seules les versions TLS 1.2 et 1.3 sont proposées.
- La politique de chiffrement impose le forward secrecy (ECDHE).
- Le certificat est documenté et son empreinte vérifiée manuellement (modèle de confiance lab).
- Les contrôles de bord assurent la disponibilité de base et le filtrage de requêtes malveillantes.

---

## 2. TLS Profile

*Référence : NIST SP 800-52 Rev.2*

- **Minimum TLS Version : 1.2.** Conformément au NIST SP 800-52r2 §3.1, TLS 1.0 et 1.1 sont désactivés (vulnérables aux attaques BEAST/POODLE).
- **Cipher strategy : AEAD uniquement.** Utilisation de suites modernes (AES-GCM / ChaCha20) pour garantir intégrité et authenticité sans les faiblesses du mode CBC.
- **Forward Secrecy : obligatoire** via l'utilisation exclusive de clés éphémères (ECDHE). Conformément à NIST SP 800-52r2 §3.3.1.
- **HSTS :** Activé avec `max-age=300` pour forcer les clients à utiliser exclusivement HTTPS.
- **Trust model :** Certificat auto-signé pour l'environnement de lab (CN=td4.local, RSA 2048, SHA-256), validé manuellement via l'empreinte lors de l'audit.
- **Expiry monitoring :** Le certificat expire dans 7 jours — à renouveler avant expiration en production.
- **Rollback :** Conserver `nginx_before.conf` ; restauration via `cp config/nginx_before.conf /etc/nginx/sites-available/default && nginx -t && systemctl reload nginx`.

---

## 3. Before / After Comparison

| Item | Before (Baseline) | After (Hardened) | Evidence file |
|---|---|---|---|
| TLS 1.0 | Offered | **Not offered** | `evidence/after/failed_tls1.txt` |
| TLS 1.1 | Offered | **Not offered** | `evidence/after/failed_tls1_1.txt` |
| TLS 1.2 | Offered | **Offered (secure)** | `evidence/after/openssl_s_client.txt` |
| TLS 1.3 | Not offered | **Offered** | `evidence/after/tls_scan.txt` |
| Weak ciphers (CBC) | Present | **Removed (AEAD only)** | `evidence/after/tls_scan.txt` |
| Forward secrecy | Partial | **All suites ECDHE** | `evidence/after/openssl_s_client.txt` |
| HSTS | Absent | **Enabled (max-age=300)** | `evidence/after/curl_vk.txt` |
| Certificate | Self-signed, CN=td4.local | Self-signed, CN=td4.local (lab) | `evidence/after/openssl_s_client.txt` |

### Before profile table

| Item | Finding |
|---|---|
| Protocol versions offered | TLS 1.2 (TLS 1.0/1.1 présents initialement) |
| Cipher families | ECDHE-RSA-AES256-GCM-SHA384 (AEAD) |
| Forward secrecy | Partial (ECDHE présent mais non forcé) |
| Certificate subject + validity | CN=td4.local, 7 jours (10/04/2026 → 17/04/2026) |
| Key size + signature algorithm | RSA 2048, sha256WithRSAEncryption |
| Chain status | Self-signed (auto-signé, pas de CA) |
| Obvious risk | TLS 1.0/1.1 acceptés ; pas de HSTS ; certificat auto-signé non vérifié |

---

## 4. Edge Controls

### Control 1 — Rate Limiting (protection disponibilité)

Configuration dans `nginx_after.conf` :
```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=1r/s;

location / {
    limit_req zone=api_limit burst=5 nodelay;
    ...
}
```

**Preuve :** Envoi de 30 requêtes en rafale depuis 10.10.10.50 → retour de codes 503 après épuisement du burst.  
Voir : `evidence/after/rate_limit_test.txt`

### Control 2 — Request Filtering (WAF concept)

Blocage des User-Agents identifiés comme outils de scan/scripting :
```nginx
if ($http_user_agent ~* "curl|sqlmap|nikto") {
    return 403;
}
```

**Preuve :** Requête avec User-Agent `curl/8.18.0` → HTTP 403 Forbidden.  
Voir : `evidence/after/request_filter.txt` et `evidence/after/curl_vk.txt`

---

## 5. Triage Note

### 1. What happened?

Le serveur srv-web (10.10.20.20) a détecté et neutralisé une tentative de scan automatisé ou de déni de service (DoS) applicatif. Le système de défense périmétrique (Nginx Edge Controls) a réagi en deux temps : d'abord en identifiant une signature d'outil malveillant via le User-Agent (curl), puis en limitant le flux de requêtes excessives pour préserver la disponibilité des ressources.

### 2. What was the signal?

D'après les logs d'accès (`/var/log/nginx/access.log`) :

- **Source IP :** 10.10.10.50 (Kali Linux)
- **Path :** `/`
- **Status Code :** 403 Forbidden (filtrage User-Agent) puis 503 Service Unavailable (rate-limiting)
- **User-Agent :** `curl/8.18.0` (outil de scripting/scan identifié)

**Log line exacte (extrait) :**
```
10.10.10.50 - - [10/Apr/2026:11:15:03 +0000] "GET / HTTP/1.1" 403 162 "-" "curl/8.18.0"
```

### 3. Classification

**Classification : Abuse / Scan**  
Le comportement (rafale de requêtes avec un outil en ligne de commande) est caractéristique d'une phase de reconnaissance agressive ou d'une tentative d'épuisement des ressources.

### 4. Next steps in a real SOC

- **Shunning :** Ajouter 10.10.10.50 à une liste de blocage temporaire au niveau du firewall pour réduire la charge sur Nginx.
- **Investigation :** Rechercher dans les logs SIEM si cette IP a tenté d'autres accès sur d'autres ports (SSH, bases de données).
- **Enrichissement :** Vérifier la réputation de l'IP sur des bases de données de menaces (VirusTotal, AbuseIPDB).
- **Alerte :** Escalader l'incident si l'IP appartient à une plage d'adresses externes non autorisées.

---

## 6. Residual Risks

| Risque | Impact | Mitigation recommandée |
|---|---|---|
| Certificat auto-signé | Pas de validation PKI en production | Déployer une CA interne ou utiliser Let's Encrypt |
| Expiration du certificat (7 jours) | Interruption de service | Mettre en place un monitoring d'expiration (Prometheus, alertmanager) |
| WAF basique (regex User-Agent) | Facilement contournable par un attaquant | Déployer ModSecurity + OWASP CRS |
| Pas d'authentification upstream | Accès anonyme à l'API | Ajouter authentification (mTLS, JWT, API key) |
| HSTS max-age=300 faible | Protection HSTS limitée | Augmenter à 31536000 (1 an) en production après validation |
