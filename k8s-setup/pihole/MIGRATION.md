# PiHole Migration zu Kubernetes

Diese Anleitung hilft dir dabei, deine bestehende PiHole-Konfiguration von Docker zu Kubernetes zu migrieren.

## VLAN-Konfiguration

Diese PiHole-Installation ist für mehrere VLANs konfiguriert:

- **192.168.2.0/24** - Haupt-LAN
- **192.168.4.0/24** - VLAN 4
- **192.168.5.0/24** - VLAN 5

Alle VLANs verwenden den Router `192.168.2.1` für die Reverse-DNS-Auflösung und können Client-Namen aus der Domain `elmstreet79.de` auflösen.

### VLAN-Router-Konfiguration

Stelle sicher, dass deine VLAN-Router so konfiguriert sind:

**Unifi Dream Machine:**
1. Network Settings → VLANs
2. Für VLAN 4 und VLAN 5:
   - DHCP aktivieren
   - DNS Server: `192.168.2.250` (PiHole)
   - Domain Name: `elmstreet79.de`

**Alternative Router:**
- DNS Server: `192.168.2.250`
- Domain-Suffix: `elmstreet79.de`

## Voraussetzungen

- Kubernetes-Cluster läuft
- MetalLB ist installiert und konfiguriert
- NGINX Ingress Controller ist installiert
- cert-manager ist installiert (für TLS-Zertifikate)
- `.env` Datei im Root-Verzeichnis mit `CF_DOMAIN` Variable

## 1. Datensicherung erstellen

Bevor du beginnst, erstelle ein Backup deiner aktuellen PiHole-Daten:

```bash
# Backup erstellen
sudo cp -r /data/pihole /data/pihole-backup-$(date +%Y%m%d)
```

## 2. PiHole Container stoppen

Stoppe den aktuellen PiHole Container:

```bash
cd /path/to/your/docker-compose/directory
docker-compose down
```

## 3. Kubernetes-Deployment vorbereiten

### Admin-Passwort ändern

Editiere die Datei `k8s-setup/pihole/pihole.yaml` und ändere das Standard-Passwort:

```yaml
stringData:
  WEBPASSWORD: "dein-sicheres-passwort"  # Ändere dies!
```

### Domain konfigurieren

Stelle sicher, dass die `.env` Datei im Root-Verzeichnis existiert:

```bash
echo "CF_DOMAIN=deine-domain.de" >> .env
```

## 4. PiHole in Kubernetes installieren

```bash
# Aus dem Root-Verzeichnis des Homelab-Repos
cd /Users/speters/workspace/homelab
./k8s-setup/pihole/install.sh
```

## 5. Daten migrieren

### Option A: Automatische Migration (empfohlen)

Warte bis der PiHole Pod läuft, dann führe die Migration aus:

```bash
# Pod-Name ermitteln
POD_NAME=$(kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')

# Konfigurationsdaten kopieren
kubectl cp /data/pihole/etc-pihole/ pihole/$POD_NAME:/etc/pihole/
kubectl cp /data/pihole/etc-dnsmasq.d/ pihole/$POD_NAME:/etc/dnsmasq.d/

# Pod neustarten, um Änderungen zu übernehmen
kubectl rollout restart deployment/pihole -n pihole
```

### Option B: Manuelle Migration

Falls die automatische Migration nicht funktioniert:

```bash
# Einzelne wichtige Dateien kopieren
kubectl cp /data/pihole/etc-pihole/gravity.db pihole/$POD_NAME:/etc/pihole/gravity.db
kubectl cp /data/pihole/etc-pihole/custom.list pihole/$POD_NAME:/etc/pihole/custom.list
kubectl cp /data/pihole/etc-pihole/pihole-FTL.conf pihole/$POD_NAME:/etc/pihole/pihole-FTL.conf

# DNS-Konfiguration kopieren
kubectl cp /data/pihole/etc-dnsmasq.d/ pihole/$POD_NAME:/etc/dnsmasq.d/
```

## 6. Konfiguration überprüfen

### Web-Interface testen

1. Öffne https://pihole.deine-domain.de/admin
2. Logge dich mit deinem Passwort ein
3. Überprüfe die Statistiken und Einstellungen

### DNS-Funktionalität testen

```bash
# DNS-Auflösung testen
nslookup google.com 192.168.2.250

# Blockierte Domain testen (sollte 0.0.0.0 zurückgeben)
nslookup doubleclick.net 192.168.2.250

# VLAN-Reverse-DNS testen (ersetze IP mit echter Client-IP)
nslookup 192.168.2.10 192.168.2.250  # Haupt-LAN
nslookup 192.168.4.10 192.168.2.250  # VLAN 4
nslookup 192.168.5.10 192.168.2.250  # VLAN 5

# Client-Namen von verschiedenen VLANs auflösen
nslookup client-name.elmstreet79.de 192.168.2.250
```

## 7. Router/Client konfigurieren

Konfiguriere deine Geräte oder Router, um `192.168.2.250` als DNS-Server zu verwenden.

### Unifi Dream Machine

1. Gehe zu Settings → Networks
2. Wähle dein LAN-Netzwerk
3. Erweiterte Einstellungen → DHCP
4. DNS Server: `192.168.2.250`

## 8. Alten Container entfernen

Nachdem alles funktioniert:

```bash
# Docker-Container und Images entfernen
docker-compose down
docker rmi pihole/pihole:latest

# Alte Daten archivieren (optional)
sudo mv /data/pihole /data/pihole-archived-$(date +%Y%m%d)
```

## Troubleshooting

### Pod startet nicht

```bash
# Logs überprüfen
kubectl logs -n pihole deployment/pihole

# Events überprüfen
kubectl get events -n pihole
```

### DNS funktioniert nicht

```bash
# Service-Status überprüfen
kubectl get svc -n pihole

# LoadBalancer IP überprüfen
kubectl get svc pihole-dns-udp -n pihole -o wide
```

### Web-Interface nicht erreichbar

```bash
# Ingress überprüfen
kubectl get ingress -n pihole

# Zertifikat überprüfen
kubectl get certificate -n pihole
```

### Daten sind weg

```bash
# Persistent Volumes überprüfen
kubectl get pv,pvc -n pihole

# In Pod einloggen und Dateien überprüfen
kubectl exec -it -n pihole deployment/pihole -- /bin/bash
ls -la /etc/pihole/
```

## Deinstallation

Falls du PiHole wieder entfernen möchtest:

```bash
# Alle Ressourcen löschen
kubectl delete namespace pihole

# Persistent Volumes manuell löschen (falls nötig)
kubectl get pv | grep pihole
# kubectl delete pv <pv-name>
```

## Backup-Strategie

Erstelle regelmäßige Backups deiner PiHole-Konfiguration:

```bash
# Backup-Script
#!/bin/bash
DATE=$(date +%Y%m%d-%H%M%S)
POD_NAME=$(kubectl get pod -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')

mkdir -p /backups/pihole/$DATE
kubectl cp pihole/$POD_NAME:/etc/pihole/ /backups/pihole/$DATE/etc-pihole/
kubectl cp pihole/$POD_NAME:/etc/dnsmasq.d/ /backups/pihole/$DATE/etc-dnsmasq.d/
```
