# PiHole Kubernetes Setup

Dieses Verzeichnis enthält die Kubernetes-Konfiguration für PiHole DNS-Server mit Multi-VLAN-Unterstützung.

## Features

- DNS-Server für mehrere VLANs (192.168.2.0/24, 192.168.4.0/24, 192.168.5.0/24)
- Conditional Forwarding für lokale Namensauflösung
- Web-Interface über NodePort (nur interner Zugang)
- Persistent Storage für Konfiguration und Logs
- LoadBalancer-Integration mit MetalLB für DNS-Service
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
- `values.yaml` - Helm-ähnliche Konfigurationswerte (zur Dokumentation)
- `install.sh` - Installationsskript
- `MIGRATION.md` - Detaillierte Migrationsanleitung von Docker

## Schnellstart

1. Führe das Installationsskript aus:

   ```bash
   ./k8s-setup/pihole/install.sh
   ```

2. **Wichtig:** Setze nach der Installation das Admin-Passwort (siehe Abschnitt oben)

## Konfiguration

### LoadBalancer IP

Pi-hole verwendet die IP `192.168.2.250` für den DNS-Service (Port 53 TCP/UDP).

### Web-Interface Zugang

Das Web-Interface ist **nur intern** über NodePort erreichbar:

- **URL**: `http://<beliebige-node-ip>:30081/admin`
- **Beispiel**: `http://192.168.2.7:30081/admin`
- **Kein Standardpasswort**: Muss manuell nach Installation gesetzt werden!

## Services

- `pihole-dns` - DNS Service (TCP/UDP, LoadBalancer auf IP 192.168.2.250)
- `pihole-web` - Web Interface (NodePort 30081 für internen Zugang)

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

### Häufige Verwaltungsbefehle

```bash
# Status überprüfen  
kubectl get all -n pihole

# Logs anzeigen
kubectl logs -n pihole deployment/pihole

# In Pod einloggen
kubectl exec -it -n pihole deployment/pihole -- /bin/bash

# Service neustarten
kubectl rollout restart deployment/pihole -n pihole

# Passwort zurücksetzen (siehe auch Abschnitt oben)
kubectl exec -n pihole <POD_NAME> -it -- pihole setpassword

# Pi-hole Status prüfen
kubectl exec -n pihole <POD_NAME> -- pihole status

# Gravity-Listen aktualisieren
kubectl exec -n pihole <POD_NAME> -- pihole -g
```

## Sicherheitshinweise

- **Kein Standardpasswort**: Nach Installation MUSS ein Passwort manuell gesetzt werden
- **Nur interner Zugang**: Web-Interface ist nur über NodePort (Port 30081) im internen Netzwerk erreichbar
- **Minimal-Berechtigungen**: ServiceAccount mit minimalen Kubernetes-Berechtigungen
- **Persistent Storage**: Konfiguration überlebt Pod-Neustarts
