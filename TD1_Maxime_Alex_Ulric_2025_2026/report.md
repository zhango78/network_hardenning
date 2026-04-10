# TD1 — Evidence Pack Report

## 1. Topology Summary

L'architecture réseau repose sur une Gateway (gw-fw) segmentant le trafic entre un réseau de confiance (LAN) et une zone exposée (DMZ).

| VM | Hostname | Interface(s) | IP Address | Zone |
|---|---|---|---|---|
| **Client** | kali | eth0 | 10.10.10.50 | NH-LAN |
| **Gateway** | gw-fw | ens5, ens6 | 10.10.10.10 / 10.10.20.10 | Trust Boundary |
| **Srv-Web** | srv-web | ens5 | 10.10.20.20 | NH-DMZ |

> Note : L'IDS Suricata est co-localisé sur la Gateway en raison des contraintes AWS VPC (pas de mode promiscuous).

---

## 2. Annotated Observations (Baseline Capture)

---

**Observation ID:** O1

- **Time range:** Lors des tests curl HTTP (Part D)
- **Flow reference (row ID):** F01 (LAN → DMZ TCP/80)
- **What I saw (facts):** Paquets TCP sur le port 80 avec en-têtes HTTP visibles en clair dans le pcap (ex : `GET / HTTP/1.1`, `Server: nginx/1.18.0`).
- **Why it matters:** Toute interception sur le LAN ou la Gateway permet de lire le contenu du trafic ou de voler des cookies de session sans aucun outil avancé.
- **Proposed control:** Migration vers HTTPS (port 443) avec redirection automatique du port 80 vers 443. Implémenter TLS 1.2+ (NIST SP 800-52r2). Adressé au TD4.
- **Evidence pointer:** `evidence/baseline.pcap` — filtrer avec `http` dans Wireshark. Premier paquet `GET`.

---

**Observation ID:** O2

- **Time range:** Lors des tests de connexion SSH (Part C/D)
- **Flow reference (row ID):** F02 (LAN → DMZ TCP/22)
- **What I saw (facts):** Initialisation d'une session SSH (Three-way handshake TCP sur le port 22). La version du serveur `OpenSSH 8.9p1` est transmise en clair lors de la négociation de bannière.
- **Why it matters:** Le service est accessible à tout le segment 10.10.10.0/24, augmentant considérablement le risque de brute-force depuis n'importe quel poste LAN.
- **Proposed control:** Restreindre l'accès au port 22 via nftables à une seule IP de gestion. Adressé au TD2.
- **Evidence pointer:** `evidence/baseline.pcap` — filtre Wireshark `tcp.port == 22`. `evidence/nmap_srvweb.txt` ligne `22/tcp open ssh`.

---

**Observation ID:** O3

- **Time range:** Lors des tests de connectivité ping (Part D)
- **Flow reference (row ID):** F04 (LAN → DMZ ICMP)
- **What I saw (facts):** Requêtes Echo (ping request) et réponses Echo (ping reply) entre 10.10.10.50 et 10.10.20.20 transitant librement via la gateway.
- **Why it matters:** Le ping non restreint permet à un attaquant de cartographier facilement les machines actives dans la DMZ en quelques secondes.
- **Proposed control:** Limiter l'ICMP echo-request à une fréquence maximale (rate limiting 5/sec) et bloquer les autres types ICMP non nécessaires. Adressé au TD2.
- **Evidence pointer:** `evidence/baseline.pcap` — filtre Wireshark `icmp`.

---

**Observation ID:** O4

- **Time range:** Lors du test d'alerte IDS (Part C)
- **Flow reference (row ID):** N/A (Attaque simulée)
- **What I saw (facts):** Requête HTTP contenant la chaîne `/etc/passwd`. Suricata a généré une alerte dans `fast.log` : `ET EXPLOIT Directory Traversal`. La requête a tout de même atteint le serveur web.
- **Why it matters:** Cela prouve que des requêtes malveillantes peuvent atteindre le serveur web sans filtrage préalable au niveau de la Gateway. L'IDS détecte mais ne bloque pas.
- **Proposed control:** Configurer Suricata en mode IPS (Inline) ou implémenter un WAF (Web Application Firewall) en frontal de Nginx. Adressé au TD3/TD4.
- **Evidence pointer:** `/var/log/suricata/fast.log` — ligne `ET EXPLOIT Directory Traversal`.

---

**Observation ID:** O5

- **Time range:** Lors du scan Nmap (Part C)
- **Flow reference (row ID):** N/A (Observation d'infrastructure)
- **What I saw (facts):** Résultat Nmap : `Not shown: 998 closed tcp ports (reset)`. Les ports fermés répondent avec un TCP RST, confirmant que la Gateway laisse passer les paquets vers des ports non ouverts et que le serveur répond directement.
- **Why it matters:** La Gateway se comporte comme un routeur simple et non comme un pare-feu. Elle confirme à l'attaquant que la machine existe même si le port est fermé. Aucune politique Default DENY n'est en place.
- **Proposed control:** Appliquer une politique Default DROP sur la Gateway (nftables). Les scans apparaîtront comme "Filtered" (pas de réponse), ralentissant l'attaquant. Adressé au TD2.
- **Evidence pointer:** `evidence/nmap_srvweb.txt` — ligne `Not shown: 998 closed tcp ports (reset)`.

---

## 3. Risk List

| Rang | Risque | Impact | Facilité d'exploitation | Description |
|---|---|---|---|---|
| **1** | SSH exposé au LAN | Critique | Élevée | Port 22 ouvert à tout 10.10.10.0/24. Risque de brute-force ou d'accès non autorisé. |
| **2** | Default Policy ACCEPT | Critique | Élevée | La Gateway laisse passer tout flux non filtré. Un attaquant peut scanner et attaquer n'importe quel service DMZ. |
| **3** | Divulgation de version | Moyen | Très Élevée | Nginx 1.18.0 et OpenSSH 8.9p1 visibles via Nmap, facilitant la recherche d'exploits ciblés (CVE). |
| **4** | Absence de chiffrement HTTP | Élevée | Élevée | Communications (ID F01) en clair sur port 80. Risque d'interception de données. |
| **5** | Absence de segmentation admin | Moyen | Élevée | Le trafic SSH d'administration et le trafic HTTP applicatif partagent les mêmes interfaces. |
| **6** | Absence de Firewall Log | Moyen | Moyenne | Aucun log généré sur paquet "Closed", empêchant la détection de tentatives de scan. |
| **7** | Directory Traversal | Élevée | Moyenne | Le serveur Web accepte des requêtes suspectes (/etc/passwd) détectées par l'IDS mais non bloquées. |
| **8** | Reconnaissance ICMP | Faible | Très Élevée | Le ping est autorisé partout, permettant de mapper la topologie réseau en quelques secondes. |
| **9** | Outbound non restreint | Moyen | Moyenne | Le serveur DMZ peut contacter n'importe quel site Internet (risque d'exfiltration de données). |
| **10** | Version Suricata (6.0.4) | Faible | Faible | Version non à jour, pouvant manquer de nouvelles signatures. |

---

## 4. Quick Wins

| # | Quick-Win | Impact | Justification |
|---|---|---|---|
| **1** | Politique Default DROP | Critique | Transformer la Gateway en pare-feu actif en bloquant par défaut tout ce qui n'est pas explicitement autorisé. |
| **2** | Restriction SSH (Port 22) | Élevé | Utiliser nftables pour n'autoriser le SSH vers la DMZ que depuis l'IP spécifique du poste administrateur. |
| **3** | Logging "Deny" sur GW | Moyen | Ajouter une règle de log nftables pour tout paquet rejeté afin de gagner en visibilité sur les attaques. |
| **4** | Masquage des bannières | Moyen | Désactiver `server_tokens` dans Nginx pour cacher la version logicielle aux scanners automatisés. |
| **5** | Filtrage Outbound explicite | Moyen | N'autoriser le serveur DMZ à sortir que vers des dépôts de mise à jour spécifiques (DNS/Apt). |
