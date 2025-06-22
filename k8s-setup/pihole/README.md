# PiHole Kubernetes Setup

Dieses Verzeichnis enthält die Kubernetes-Konfiguration für PiHole DNS-Server mit Multi-VLAN-Unterstützung.

## Features

- DNS-Server für mehrere VLANs (192.168.2.0/24, 192.168.4.0/24, 192.168.5.0/24)
- Conditional Forwarding für lokale Namensauflösung
- HTTPS Web-Interface mit automatischen TLS-Zertifikaten
- Persistent Storage für Konfiguration und Logs
- LoadBalancer-Integration mit MetalLB
- **Sicheres Passwort-Management**: Kein Standardpasswort - manuelles Setup erforderlich

## ⚠️ Wichtig: Passwort-Setup nach Installation

**Nach der ersten Installation MUSS das Pi-hole Admin-Passwort manuell gesetzt werden:**

1. **Pi-hole Pod finden:**
   ```bash
   kubectl get pods -n pihole
   ```

2. **Passwort interaktiv setzen:**
   ```bash
   kubectl exec -n pihole <POD_NAME> -it -- pihole setpassword
   ```
   
3. **Oder Passwort ohne Interaktion setzen:**
   ```bash
   kubectl exec -n pihole <POD_NAME> -- pihole setpassword 'IhrSicheresPasswort'
   ```

4. **Passwort deaktivieren (nicht empfohlen):**
   ```bash
   kubectl exec -n pihole <POD_NAME> -- pihole setpassword ''
   ```

**Hinweis:** Das Passwort wird persistent gespeichert und überlebt Pod-Neustarts.

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
