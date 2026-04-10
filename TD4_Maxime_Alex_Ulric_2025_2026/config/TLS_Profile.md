# TLS Security Profile — NIST SP 800-52r2 Compliance

**Target:** srv-web (10.10.20.20)  
**Reference:** NIST SP 800-52 Rev.2 (TLS configuration guidance) + RFC 8446 (TLS 1.3)

---

## Target Configuration

**Minimum TLS Version : 1.2**  
Conformément au NIST SP 800-52r2 §3.1, les versions TLS 1.0 et 1.1 sont désactivées car elles sont vulnérables (attaques type BEAST/POODLE). TLS 1.3 est activé en priorité.

**Cipher Strategy : AEAD uniquement**  
Utilisation de suites modernes (AES-GCM / ChaCha20) pour garantir l'intégrité et l'authenticité sans les faiblesses du mode CBC. Référence : NIST SP 800-52r2 §3.3.

```
ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!RC4
```

**Forward Secrecy : obligatoire**  
Via l'utilisation exclusive de clés éphémères (ECDHE). Si la clé privée du serveur est compromise, les sessions passées restent protégées. Référence : NIST SP 800-52r2 §3.3.1.

**HSTS (Strict Transport Security) : activé**  
`max-age=300` pour le lab (valeur courte pour éviter de verrouiller les navigateurs de test). En production : `max-age=31536000; includeSubDomains; preload`. Référence : NIST SP 800-52r2 §3.5.

**Trust Model : certificat auto-signé (lab)**  
CN=td4.local, RSA 2048 bits, sha256WithRSAEncryption, validité 7 jours. Acceptable en environnement de lab, validé manuellement par l'empreinte du certificat. En production : CA interne ou certificat Let's Encrypt.

**Operational checks :**
- Monitoring d'expiration : alerte à J-30 (production)
- Reload strategy : `nginx -t && systemctl reload nginx` (pas de downtime)
- Rollback plan : `nginx_before.conf` conservé, restauration en < 2 min

---

## Nginx directive summary

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE+AESGCM:ECDHE+CHACHA20:!aNULL:!MD5:!RC4;
ssl_prefer_server_ciphers on;
add_header Strict-Transport-Security "max-age=300" always;
```
