# Documentation du Durcissement SSH (SSH Hardening)

Dans le cadre du TD5, j'ai appliqué une posture de sécurité "Bastion" sur le serveur `siteB-srv`. Les modifications suivantes ont été effectuées :

### Modifications Appliquées et Justifications
1. **Désactivation de l'authentification par mot de passe (`PasswordAuthentication no`)**
   - **Pourquoi :** Élimine les risques d'attaques par force brute et par dictionnaire. L'accès est désormais restreint aux détenteurs de clés privées Ed25519.

2. **Interdiction de l'accès Root (`PermitRootLogin no`)**
   - **Pourquoi :** Réduit la surface d'attaque en empêchant un attaquant de cibler directement le compte le plus privilégié du système.

3. **Restriction à l'utilisateur `admin1` (`AllowUsers admin1`)**
   - **Pourquoi :** Application du principe de moindre privilège. Seul l'utilisateur dédié à l'administration est autorisé à initier une session SSH.

4. **Limitation des tentatives (`MaxAuthTries 3`)**
   - **Pourquoi :** Déconnecte automatiquement les tentatives suspectes après 3 échecs, limitant l'impact des outils de scan automatisés.

5. **Réduction du délai de connexion (`LoginGraceTime 30`)**
   - **Pourquoi :** Libère les ressources du service SSH plus rapidement en fermant les connexions qui ne s'authentifient pas dans les 30 secondes.

### Validation du Service
La configuration a été validée avec la commande `sudo sshd -t` avant le redémarrage du service pour garantir la disponibilité de l'accès.