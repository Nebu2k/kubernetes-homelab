# Migration von Docker PiHole zu Kubernetes PiHole

Diese Anleitung beschreibt den Umstieg von einem Docker-basierten PiHole zu der Kubernetes-Version mit Unbound.

## 🔄 Migrationsstrategie

### Phase 1: Parallel-Betrieb (Testen)
- Kubernetes PiHole läuft auf Port 5353
- Docker PiHole läuft weiter auf Port 53
- Beide Systeme können parallel betrieben werden

### Phase 2: Umstellung (Produktion)
- Docker PiHole stoppen
- Kubernetes PiHole auf Port 53 umstellen
- Router-Konfiguration anpassen

## 📋 Schritt-für-Schritt Migration

### Schritt 1: Kubernetes PiHole installieren

```bash
# Installation mit Test-Port 5353
./k8s-setup/pihole/install.sh
```

### Schritt 2: Testen der Kubernetes-Version

```bash
# DNS-Tests durchführen
nslookup google.com 192.168.2.250 -port=5353
nslookup doubleclick.net 192.168.2.250 -port=5353

# Web-Interface testen
# http://192.168.2.250/admin
```

### Schritt 3: Konfiguration übertragen (optional)

Wenn du deine bestehenden Block-Listen und Einstellungen übertragen möchtest:

#### 3a: Backup vom Docker PiHole erstellen

```bash
# In das Docker PiHole-Verzeichnis wechseln
cd /pfad/zu/deinem/docker-pihole

# Backup der wichtigsten Dateien
docker exec pihole cat /etc/pihole/adlists.list > backup_adlists.list
docker exec pihole cat /etc/pihole/blacklist.txt > backup_blacklist.txt
docker exec pihole cat /etc/pihole/whitelist.txt > backup_whitelist.txt
docker exec pihole cat /etc/pihole/regex.list > backup_regex.list
```

#### 3b: Konfiguration in Kubernetes PiHole importieren

```bash
# Pod-Name ermitteln
PIHOLE_POD=$(kubectl get pods -n pihole -l app=pihole -o jsonpath='{.items[0].metadata.name}')

# Dateien in den Pod kopieren
kubectl cp backup_adlists.list pihole/$PIHOLE_POD:/tmp/
kubectl cp backup_blacklist.txt pihole/$PIHOLE_POD:/tmp/
kubectl cp backup_whitelist.txt pihole/$PIHOLE_POD:/tmp/
kubectl cp backup_regex.list pihole/$PIHOLE_POD:/tmp/

# Im Pod die Dateien übernehmen
kubectl exec -n pihole $PIHOLE_POD -- cp /tmp/adlists.list /etc/pihole/
kubectl exec -n pihole $PIHOLE_POD -- cp /tmp/blacklist.txt /etc/pihole/
kubectl exec -n pihole $PIHOLE_POD -- cp /tmp/whitelist.txt /etc/pihole/
kubectl exec -n pihole $PIHOLE_POD -- cp /tmp/regex.list /etc/pihole/

# PiHole neu starten um Konfiguration zu laden
kubectl rollout restart deployment/pihole -n pihole
```

### Schritt 4: Produktions-Umstellung

Wenn du mit der Kubernetes-Version zufrieden bist:

#### 4a: Docker PiHole stoppen

```bash
# Docker PiHole Container stoppen
docker stop pihole

# Optional: Container entfernen
docker rm pihole

# Optional: Autostart deaktivieren (je nach Setup)
# systemctl disable docker-pihole  # falls als Service konfiguriert
```

#### 4b: Kubernetes PiHole auf Port 53 umstellen

```bash
# values.yaml bearbeiten
sed -i 's/port: 5353/port: 53/g' k8s-setup/pihole/values.yaml

# loadbalancer.yaml bearbeiten  
sed -i 's/port: 5353/port: 53/g' k8s-setup/pihole/loadbalancer.yaml
sed -i 's/targetPort: 5353/targetPort: 53/g' k8s-setup/pihole/loadbalancer.yaml

# Neu deployen
helm upgrade pihole pihole/pihole --namespace pihole --values k8s-setup/pihole/values.yaml
kubectl apply -f k8s-setup/pihole/loadbalancer.yaml
```

#### 4c: DNS-Konfiguration prüfen

```bash
# Neue Konfiguration testen
nslookup google.com 192.168.2.250
dig @192.168.2.250 google.com

# LoadBalancer-Status prüfen
kubectl get svc -n pihole pihole-dns
```

### Schritt 5: Router/DHCP konfigurieren

```bash
# Router-DNS von alter IP auf neue IP umstellen
# Alte Konfiguration: <docker-host-ip>:53
# Neue Konfiguration: 192.168.2.250:53
```

## 🔧 Troubleshooting

### Problem: Port-Konflikt beim Umstellen

```bash
# Prüfen, ob Docker PiHole noch läuft
docker ps | grep pihole

# Prüfen, welcher Prozess Port 53 belegt
sudo netstat -tulpn | grep :53
sudo lsof -i :53
```

### Problem: DNS-Auflösung funktioniert nicht

```bash
# Pod-Status prüfen
kubectl get pods -n pihole

# Pod-Logs prüfen
kubectl logs -n pihole deployment/pihole -f

# Service-Status prüfen
kubectl get svc -n pihole
kubectl describe svc pihole-dns -n pihole
```

### Problem: Web-Interface nicht erreichbar

```bash
# LoadBalancer-IP prüfen
kubectl get svc pihole-web -n pihole

# Port-Forward als Fallback
kubectl port-forward -n pihole svc/pihole-web 8080:80
# Dann: http://localhost:8080/admin
```

## 🎯 Rollback-Plan

Falls Probleme auftreten:

```bash
# 1. Kubernetes PiHole auf Test-Port zurück
sed -i 's/port: 53/port: 5353/g' k8s-setup/pihole/values.yaml
sed -i 's/port: 53/port: 5353/g' k8s-setup/pihole/loadbalancer.yaml
sed -i 's/targetPort: 53/targetPort: 5353/g' k8s-setup/pihole/loadbalancer.yaml

# 2. Neu deployen
helm upgrade pihole pihole/pihole --namespace pihole --values k8s-setup/pihole/values.yaml
kubectl apply -f k8s-setup/pihole/loadbalancer.yaml

# 3. Docker PiHole wieder starten
docker start pihole

# 4. Router-DNS zurück auf Docker PiHole
```

## 📊 Vorteile der Kubernetes-Version

- ✅ **Hochverfügbarkeit**: Kubernetes startet PiHole automatisch neu
- ✅ **Unbound Integration**: Bessere Privacy und Performance
- ✅ **Persistent Storage**: Daten bleiben bei Pod-Neustarts erhalten
- ✅ **LoadBalancer**: Saubere IP-Adresse ohne Port-Forwarding
- ✅ **Monitoring**: Integration in Kubernetes-Monitoring möglich
- ✅ **Backup**: Kubernetes-native Backup-Strategien
- ✅ **Updates**: Managed über Helm Charts

## 📈 Performance-Vergleich

Nach der Migration kannst du die Performance vergleichen:

```bash
# Response-Zeit testen
time nslookup google.com 192.168.2.250
time nslookup google.com <alte-docker-ip>

# Query-Performance im Web-Interface vergleichen
# Kubernetes: http://192.168.2.250/admin
# Docker: http://<alte-ip>/admin
```
