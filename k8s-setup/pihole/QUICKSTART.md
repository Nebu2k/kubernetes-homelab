# PiHole mit Unbound - Schnellstart

Dieses Setup installiert PiHole mit Unbound als rekursiven DNS-Resolver für maximale Privatsphäre und Sicherheit.

## 🚀 Schnelle Installation

```bash
# Vollständige Installation aller Komponenten (inkl. PiHole)
./install-all.sh

# Nur PiHole installieren
./k8s-setup/pihole/install.sh
```

## 🔧 Konfiguration

### .env Datei

```env
# Basis-Domain
CF_DOMAIN=example.com

# Optional: PiHole Admin-Passwort (wird automatisch generiert wenn nicht gesetzt)
PIHOLE_ADMIN_PASSWORD=mein_sicheres_passwort
```

## 📊 Zugriff

Nach der Installation:

```bash
# DNS Server: 192.168.2.250:5353 (Testport)
# Web Interface: http://192.168.2.250/admin
```

### Admin-Passwort abrufen

```bash
kubectl get secret pihole-admin-password -n pihole -o jsonpath="{.data.password}" | base64 -d
```

## 🧪 DNS Tests

```bash
# Normale DNS-Auflösung testen
nslookup google.com 192.168.2.250 -port=5353

# Ad-Blocking testen (sollte blockiert werden)
nslookup doubleclick.net 192.168.2.250 -port=5353

# Mit dig testen
dig @192.168.2.250 -p 5353 google.com
```

## 🔄 Von Test zu Produktion wechseln

Wenn du bereit bist, den Docker PiHole zu ersetzen:

1. **Docker PiHole stoppen**: `docker stop pihole`
2. **Konfiguration anpassen**: Port 5353 → 53 in `values.yaml` und `loadbalancer.yaml`
3. **Neu deployen**:
   ```bash
   helm upgrade pihole pihole/pihole --namespace pihole --values k8s-setup/pihole/values.yaml
   kubectl apply -f k8s-setup/pihole/loadbalancer.yaml
   ```
4. **Router konfigurieren**: DNS auf `192.168.2.250` (ohne Port) setzen

## 🛡️ Features

- ✅ **PiHole**: Netzwerk-weite Werbeblocker
- ✅ **Unbound**: Rekursiver DNS-Resolver
- ✅ **DNSSEC**: DNS-Sicherheit aktiviert
- ✅ **Privatsphäre**: Query Minimization und weitere Privacy-Features
- ✅ **Performance**: Optimierte Cache-Einstellungen
- ✅ **Persistent Storage**: Longhorn-Integration
- ✅ **LoadBalancer**: Saubere IP-basierte Konfiguration (192.168.2.250)
- ✅ **Test-Port**: DNS läuft auf Port 5353 (konfliktfrei mit vorhandenem Docker PiHole)

## 📚 Weitere Informationen

Siehe `k8s-setup/pihole/README.md` für detaillierte Dokumentation.
