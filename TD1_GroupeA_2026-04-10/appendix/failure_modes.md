# Appendix — Failure Modes (TD1-specific)

Ce document liste les problèmes rencontrés, les causes identifiées et les résolutions appliquées.

---

## FM-01 — Suricata ne génère aucune alerte (fast.log vide)

**Symptôme :** Malgré du trafic présent, Suricata ne produit aucune entrée dans `/var/log/suricata/fast.log`.

**Cause identifiée :** TCP Checksum Offloading d'AWS. Les cartes réseau AWS ne calculent pas les sommes de contrôle au niveau OS. Suricata interprète ces paquets comme invalides et les rejette avant analyse.

**Résolution :** Modifier `/etc/suricata/suricata.yaml` :
```yaml
# Désactiver la vérification des checksums pour AWS
checksum-validation: no
```
Puis redémarrer : `sudo systemctl restart suricata`

---

## FM-02 — Absence de mode promiscuous (sensor-ids non opérationnel)

**Symptôme :** Impossible de capturer le trafic d'autres VMs sur le même segment depuis sensor-ids.

**Cause identifiée :** AWS VPC bloque le mode promiscuous sur les interfaces réseau. Le trafic ne peut pas être sniffé passivement depuis une VM tierce.

**Résolution :** Suricata a été installé directement sur gw-fw (point de passage obligatoire). Cette architecture garantit la visibilité de tout le trafic inter-zones (LAN ↔ DMZ), au prix de la visibilité intra-zone (East-West).

---

## FM-03 — ssh ubuntu@10.10.20.20 refusé en CLI

**Symptôme :** `Permission denied (publickey)` lors d'une tentative SSH depuis la ligne de commande Kali.

**Cause identifiée :** La connexion SSH au serveur est configurée par clé publique uniquement. La clé PuTTY (.ppk) utilisée via l'interface graphique n'a pas été exportée au format OpenSSH pour utilisation en CLI.

**Impact :** La commande `ssh ubuntu@10.10.20.20 "ss -tulpn"` n'a pas pu être exécutée directement. Les informations sur les services en écoute ont été obtenues via le scan Nmap (`evidence/nmap_srvweb.txt`).

**Résolution future :** Exporter la clé PuTTY au format OpenSSH avec `puttygen key.ppk -O private-openssh -o id_rsa`, puis `ssh -i id_rsa ubuntu@10.10.20.20`.

---

## FM-04 — VMs sur différents réseaux internes VirtualBox (si applicable)

**Symptôme :** Aucune communication entre les VMs malgré une configuration IP correcte.

**Cause identifiée :** VMs assignées à des noms de réseaux internes différents dans VirtualBox.

**Résolution :** Vérifier que toutes les VMs de la même zone utilisent exactement le même nom de réseau interne (`NH-LAN` ou `NH-DMZ`) dans les paramètres réseau VirtualBox.

---

## FM-05 — IP forwarding désactivé sur gw-fw

**Symptôme :** Le client ne peut pas atteindre srv-web bien que les IPs et routes soient correctes.

**Cause identifiée :** `net.ipv4.ip_forward = 0` — le noyau Linux ne route pas les paquets entre interfaces.

**Résolution :**
```bash
sudo sysctl -w net.ipv4.ip_forward=1
# Pour persistance :
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```
