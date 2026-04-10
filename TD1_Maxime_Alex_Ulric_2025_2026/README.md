# TD1 — Network Baseline for Hardening
**Module:** Network Hardening (4th-year engineering)
**Date:** 2026-04-10
**Group:** Groupe Alex - Maxime - Ulric

---

## 1. Team Members & Roles

| Name | Role |
|---|---|
| Alex Zhang | TD1-4 / Engineer |
| Maxime Senechal | TD5-6 / Engineer |
| Ulric Sieys | TD1-2 / Engineer |

---

## 2. Lab Topology Summary

> **Note d'adaptation :** Ce lab a été déployé sur AWS. En raison des limitations du mode promiscuous sur AWS VPC, le sensor-ids dédié n'a pas pu être instancié. Suricata (IDS) a été co-localisé directement sur la machine gw-fw, qui est le point de passage obligatoire de tout le trafic inter-zones.

| VM | Hostname | Interface(s) | IP Address | Zone | Role / Services |
|---|---|---|---|---|---|
| **Client** | kali | eth0 | 10.10.10.50 | NH-LAN | Auditeur, génération de trafic |
| **Gateway** | gw-fw | ens5 (LAN), ens6 (DMZ) | 10.10.10.10 / 10.10.20.10 | Trust Boundary | Routage, IDS (Suricata), Firewall (nftables) |
| **Srv-Web** | srv-web | ens5 | 10.10.20.20 | NH-DMZ | Serveur cible (Nginx 1.18.0, SSH OpenSSH 8.9p1) |

**Zones définies :**
- **NH-LAN** — 10.10.10.0/24 — Zone de confiance (client)
- **NH-DMZ** — 10.10.20.0/24 — Zone exposée (serveur web)
- **Trust Boundary** — gw-fw assure la séparation LAN ↔ DMZ

---

## 3. What Was Tested and How

1. **Routage inter-zones :** Validation de la communication LAN ↔ DMZ via la Gateway (tests ping et curl).
2. **Audit de visibilité (Port Scan) :** Analyse des ports ouverts sur srv-web depuis le client via `nmap -sS -sV`.
3. **Détection d'intrusion :** Simulation d'une attaque Directory Traversal (`/etc/passwd`) pour valider les signatures Suricata.
4. **Capture de baseline :** Analyse des flux réseau via `tcpdump` pour identifier les protocoles en clair (HTTP, SSH, ICMP).

---

## 4. Known Limitations

1. **Absence de sensor-ids dédié :** Le mode promiscuous étant bloqué par AWS VPC, la visibilité East-West intra-zone n'est pas assurée. L'IDS ne voit que le trafic traversant la Gateway.
2. **Checksums AWS :** Le TCP Checksum Offloading d'AWS nécessite la désactivation de `checksum-validation` dans `suricata.yaml` pour que Suricata traite les paquets.
3. **Filtrage stateless :** À ce stade (TD1), la Gateway agit comme un routeur ouvert. La politique par défaut est ACCEPT — vulnérabilité majeure adressée au TD2.
4. **HTTP en clair :** TLS/SSL n'est pas encore implémenté sur srv-web (adressé au TD4).
