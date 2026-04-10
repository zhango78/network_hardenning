# Test Cards — TD1 Network Baseline

---

## TD1-T01 — Client can reach srv-web on required service (HTTP)

**1) Claim**
Le client Kali (LAN) peut accéder au service Web (port 80) du serveur srv-web (DMZ) à travers la gateway.

**2) Preconditions**
- Kali (Client) : 10.10.10.50
- srv-web (Serveur) : 10.10.20.20
- Service Nginx actif sur srv-web (port 80)
- Routage IP activé sur gw-fw : `sysctl net.ipv4.ip_forward = 1`

**3) Configuration fragment**
```bash
# Vérification du routage sur gw-fw
sysctl net.ipv4.ip_forward
# net.ipv4.ip_forward = 1
```

**4) Test method**

*Positive test (should succeed)*
- Command: `curl -I http://10.10.20.20`
- Expected result: `HTTP/1.1 200 OK`

*Negative test (should fail)*
- Command: `curl -I http://10.10.20.20:81`
- Expected result: `curl: (7) Failed to connect to 10.10.20.20 port 81: Connection refused`

**5) Telemetry / evidence**
- Lieu : Capture tcpdump sur ens5 de gw-fw.
- Preuve : Paquets SYN/ACK observés entre 10.10.10.50 et 10.10.20.20 sur le port 80.

**6) Result**
- **PASS**
- Notes : La connectivité est totale. Le routage inter-zones fonctionne sans filtrage restrictif à ce stade (TD1 baseline — avant TD2).

**7) Artifacts**
- `tests/commands.txt`
- `evidence/baseline.pcap`

---

## TD1-T02 — Unexpected port on srv-web is closed or flagged as risk

**1) Claim**
Les ports inattendus (ex : SSH/22) sur srv-web sont ouverts et identifiés comme des risques de sécurité dans la matrice de flux.

**2) Preconditions**
- Scanner Nmap installé sur Kali
- srv-web accessible à l'adresse 10.10.20.20

**3) Configuration fragment**
N/A (État initial sans pare-feu actif).

**4) Test method**

*Positive test (should succeed — port is open and must be flagged)*
- Command: `nmap -sS -p 22 10.10.20.20`
- Expected result: `22/tcp open ssh`

*Negative test*
- N/A (Test de découverte et de documentation uniquement).

**5) Telemetry / evidence**
- Lieu : Sortie console Nmap.
- Preuve : `22/tcp open ssh OpenSSH 8.9p1`

**6) Result**
- **PASS** (Observation confirmée)
- Notes : Le port 22 est ouvert à tout le LAN. Flaggé comme risque majeur (Rang 1) dans la matrice de flux avec statut REVIEW.

**7) Artifacts**
- `evidence/nmap_srvweb.txt`

---

## TD1-T03 — Baseline capture includes HTTP and ICMP traffic

**1) Claim**
La capture de référence (baseline) contient bien le trafic HTTP et ICMP généré entre le client et le serveur.

**2) Preconditions**
- tcpdump actif sur l'interface ens5 de gw-fw
- Génération de trafic depuis Kali

**3) Configuration fragment**
```bash
sudo tcpdump -i ens5 -w evidence/baseline.pcap -nn
```

**4) Test method**

*Positive test (should succeed)*
- Commands: `ping -c 4 10.10.20.20` et `curl http://10.10.20.20`
- Expected result: Paquets enregistrés dans le fichier .pcap

*Negative test (should fail — HTTPS not configured)*
- Command: `tcpdump -r evidence/baseline.pcap port 443`
- Expected result: Aucune sortie (HTTPS non configuré à ce stade)

**5) Telemetry / evidence**
- Lieu : Fichier `evidence/baseline.pcap`
- Preuve : Analyse Wireshark montrant les flags TCP (port 80) et les ICMP Echo requests

**6) Result**
- **PASS**
- Notes : La capture confirme que le trafic traverse la gateway en clair. Aucune session TLS détectée (port 443 absent).

**7) Artifacts**
- `evidence/baseline.pcap`

---

## TD1-T04 — Topology diagram matches observed addressing and routes

**1) Claim**
Le diagramme de topologie correspond aux adresses IP et aux routes observées sur les machines réelles.

**2) Preconditions**
- Accès aux VMs pour vérifier l'adressage (ou sorties de commandes disponibles)

**3) Configuration fragment**
N/A (Documentation et vérification).

**4) Test method**

*Positive test (should succeed)*
- Command: `ip route` sur Kali
- Expected result: `default via 10.10.10.10 dev eth0` (gateway correcte)

*Negative test (should fail — no unexpected addresses)*
- Command: `ip addr show`
- Expected result: Aucune adresse en dehors des sous-réseaux 10.10.10.0/24 et 10.10.20.0/24

**5) Telemetry / evidence**
- Lieu : Sortie des commandes réseau sur chaque VM
- Preuve : Comparaison entre le README.md et les sorties de `ip addr` + `ip route`

**6) Result**
- **PASS**
- Notes : La topologie AWS a été correctement mappée. L'adaptation principale est l'absence du sensor-ids dédié (Suricata co-localisé sur gw-fw).

**7) Artifacts**
- `README.md`
- `diagram.pdf`
