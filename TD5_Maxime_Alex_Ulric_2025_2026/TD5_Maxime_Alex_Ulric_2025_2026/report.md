Report: Network Hardening Evidence Pack
1. Threat Model

Le modèle de menace repose sur la protection des communications entre deux sites distants via un réseau non fiable (Internet/WAN AWS).

    Menaces ciblées : Interception de données (Man-in-the-Middle), usurpation d'identité (Brute-force SSH), et accès non autorisé au serveur interne depuis le réseau local compromis.

    Périmètre : Le tunnel IPsec protège le segment WAN ; le Hardening SSH protège l'hôte final siteB-srv.

2. Policy Statement

    "L'accès administratif est restreint exclusivement à l'utilisateur admin1 via authentification par clé Ed25519. L'authentification par mot de passe et l'accès root sont désactivés. Tout trafic inter-sites entre le LAN (Site A) et la DMZ (Site B) doit être chiffré via un tunnel IPsec IKEv2. L'accès SSH au serveur final n'est autorisé que s'il provient du tunnel VPN."

3. SSH Configuration

    Excerpt : Voir config/sshd_config_excerpt.txt.

    Justification : Utilisation de clés asymétriques pour éliminer le risque de dictionnaire. Restriction Match Address pour lier la gestion du serveur à la présence du VPN (défense en profondeur).

4. IPsec Configuration

    Excerpt : Voir config/ipsec_siteA.conf.

    Design Choice : IKEv2 avec AES-GCM ou AES-CBC-256 pour un compromis optimal sécurité/performance. Authentification par PSK (simplification lab) documentée comme risque résiduel.

5. Test Plan

    Positive tests : SSH via tunnel (admin1), Ping inter-site.

    Negative tests : SSH via mot de passe (refusé), SSH depuis Gateway B (bloqué par Match Address), accès Root (refusé).

    References : Voir les fichiers dans evidence/.

6. Telemetry Proof

    Logs : evidence/authlog_excerpt.txt montrant les sessions acceptées/refusées.

    Tunnel Status : evidence/ipsec_status.txt confirmant l'état ESTABLISHED.

    Traffic : evidence/optional_esp_capture.txt prouvant l'encapsulation ESP.

7. Residual Risks

    PSK Leak : La clé partagée pourrait être compromise. Mitigation future : Migration vers certificats X.509.

    Key Rotation : Pas de mécanisme automatique de rotation des clés SSH.

    MFA : Absence d'authentification à double facteur pour le SSH.

    Device Posture : Pas de vérification de l'état de sécurité du client A avant l'accès au VPN.