# PiHole Kubernetes Setup

Dieses Verzeichnis enthält die Kubernetes-Konfiguration für PiHole DNS-Server.

## Dateien

- `pihole.yaml` - Hauptmanifest mit Deployment, Services und PVCs
- `ingress.yaml` - Ingress-Konfiguration für Web-Interface
- `values.yaml` - Helm-ähnliche Konfigurationswerte (zur Dokumentation)
- `install.sh` - Installationsskript
- `MIGRATION.md` - Detaillierte Migrationsanleitung von Docker

## Schnellstart

1. Stelle sicher, dass `CF_DOMAIN` in der `.env`-Datei gesetzt ist
2. Führe das Installationsskript aus:
   ```bash
   ./k8s-setup/pihole/install.sh
   ```

## Konfiguration

### Umgebungsvariablen

- `CF_DOMAIN` - Deine Hauptdomain (erforderlich)
- `CF_PIHOLE_DOMAIN` - PiHole-Subdomain (optional, Standard: pihole.$CF_DOMAIN)

### LoadBalancer IP

PiHole verwendet die IP `192.168.2.250` für den DNS-Service (Port 53 TCP/UDP).

### Web-Interface

Das Web-Interface ist über HTTPS erreichbar: `https://pihole.$CF_DOMAIN`

Standard-Passwort: `admin123` (bitte sofort ändern!)

## Services

- `pihole-dns-udp` - DNS Service (UDP, LoadBalancer)
- `pihole-dns-tcp` - DNS Service (TCP, LoadBalancer)  
- `pihole-web` - Web Interface (ClusterIP)

## Persistent Volumes

- `pihole-config-pvc` - PiHole-Konfiguration (5Gi)
- `pihole-dnsmasq-pvc` - dnsmasq-Konfiguration (1Gi)

## Sicherheit

- Läuft als root (erforderlich für DNS-Bindung an Port 53)
- Separater Namespace `pihole`
- ServiceAccount mit minimalen Berechtigungen
- TLS-Verschlüsselung für Web-Interface

## Überwachung

Health Checks sind konfiguriert:
- Liveness Probe: HTTP-Check auf /admin/
- Readiness Probe: HTTP-Check auf /admin/

## Troubleshooting

Siehe `MIGRATION.md` für detaillierte Troubleshooting-Schritte.

### Häufige Befehle

```bash
# Status überprüfen
kubectl get all -n pihole

# Logs anzeigen
kubectl logs -n pihole deployment/pihole

# In Pod einloggen
kubectl exec -it -n pihole deployment/pihole -- /bin/bash

# Service neustarten
kubectl rollout restart deployment/pihole -n pihole
```
