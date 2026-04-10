# Failure Modes — TD4 TLS Audit and Hardening

| ID | Failure | Symptom | Fix |
|---|---|---|---|
| FM-01 | Nginx reload fails | `nginx -t` shows syntax error | Corriger la config ; toujours lancer `nginx -t` avant reload |
| FM-02 | Mauvais port (8443 vs 443) | `curl` : connection refused | Vérifier directive `listen` et mapping Docker |
| FM-03 | Certificate hostname mismatch | Scanner : "hostname mismatch" | Utiliser `-servername` avec SNI ; correspondre `server_name` |
| FM-04 | Chaîne de certificat incomplète | Scanner : "chain incomplete" | Concaténer le certificat intermédiaire dans le chain file |
| FM-05 | Avertissement self-signed | Attendu en lab | Documenter le modèle de confiance (lab CA ou self-signed) |
| FM-06 | Rate limit bloque le trafic légitime | Toutes les requêtes → 503 | Ajuster les paramètres `burst` et `rate` |
| FM-07 | Regex de filtrage crée des faux positifs | Requête légitime bloquée en 403 | Réduire la portée du match ; restreindre à des paths spécifiques |
| FM-08 | TLS 1.3 non supporté par le client | Handshake failure sur vieux OS | Vérifier que `TLSv1.2` reste activé comme fallback |
| FM-09 | HSTS verrouille un navigateur de test | Impossible d'accéder au site en HTTP après test | Utiliser `max-age=300` (5 min) en lab ; vider le cache HSTS du navigateur |
| FM-10 | Clé privée absente / mauvais chemin | nginx ne démarre pas, erreur SSL | Vérifier chemin `ssl_certificate_key` et permissions (chmod 600) |
