# K3s High Availability (HA) Setup Guide

Dieses Dokument beschreibt, wie du dein aktuelles K3s Setup von einem Single Master zu einer echten HA-Konfiguration umwandelst.

## 🔍 Aktueller Status (Problematisch)

```bash
kubectl get nodes -o wide
NAME      STATUS   ROLES                  AGE     VERSION        INTERNAL-IP   
prodesk   Ready    control-plane,master   5d1h    v1.32.5+k3s1   192.168.2.7   # Einziger Control Plane
raspi3    Ready    worker                 3d10h   v1.32.5+k3s1   192.168.2.3   # Nur Worker
raspi4    Ready    worker                 3d10h   v1.32.5+k3s1   192.168.2.2   # Nur Worker  
raspi5    Ready    worker                 3d10h   v1.32.5+k3s1   192.168.2.9   # Nur Worker
```

**Problem**: Wenn `prodesk` ausfällt, ist nichts mehr erreichbar, weil:
- API Server läuft nur auf `prodesk`
- etcd Datenbank läuft nur auf `prodesk`
- Controller Manager läuft nur auf `prodesk`
- Scheduler läuft nur auf `prodesk`

## 🎯 Ziel: HA-Konfiguration (3 Control Planes)

```bash
# Nach der Umstellung:
NAME      STATUS   ROLES                  AGE     VERSION        INTERNAL-IP
prodesk   Ready    control-plane,master   5d1h    v1.32.5+k3s1   192.168.2.7   # Control Plane 1
raspi4    Ready    control-plane,master   3d10h   v1.32.5+k3s1   192.168.2.2   # Control Plane 2  
raspi5    Ready    control-plane,master   3d10h   v1.32.5+k3s1   192.168.2.9   # Control Plane 3
raspi3    Ready    worker                 3d10h   v1.32.5+k3s1   192.168.2.3   # Worker Node
```

**Vorteil**: Cluster bleibt verfügbar, solange mindestens 2 von 3 Control Planes laufen.

**Load Balancer**: Kube-VIP auf IP 192.168.2.249 für API-Server Zugriff.

## 📋 Voraussetzungen

- Alle Nodes müssen sich gegenseitig erreichen können
- Mindestens 2GB RAM pro Control Plane Node (Raspberry Pi 4/5 reichen)
- Persistent Storage für etcd (auf allen Control Planes)
- Load Balancer IP für API Server Zugriff (192.168.2.249)

## 🔧 Schritt-für-Schritt Anleitung

### Schritt 1: Load Balancer mit Kube-VIP vorbereiten

**DNS Problem:** Da die Server direkt 1.1.1.1 als DNS verwenden, funktioniert `api.elmstreet79.de` nicht. Daher verwenden wir direkt die IP 192.168.2.249.

**Kube-VIP Lösung:**
- Virtuelle IP 192.168.2.249 wird zwischen Control Planes geteilt
- Automatisches Failover bei Node-Ausfall
- Keine manuelle Router-Konfiguration nötig

### Schritt 2: K3s auf prodesk mit HA-Konfiguration neu starten

```bash
# Auf prodesk (aktueller Master):
sudo systemctl stop k3s

# K3s mit HA-Konfiguration neu starten
sudo k3s server \
  --cluster-init \
  --tls-san 192.168.2.249 \
  --tls-san prodesk.elmstreet79.de \
  --tls-san 192.168.2.7 \
  --disable traefik \
  --write-kubeconfig-mode 644
```

### Schritt 3: Token für neue Control Planes abrufen

```bash
# Auf prodesk:
sudo cat /var/lib/rancher/k3s/server/node-token
# Notiere diesen Token - du brauchst ihn für die anderen Nodes
```

### Schritt 4: raspi4 zu Control Plane umwandeln

```bash
# Auf raspi4:
# Zuerst K3s Agent stoppen
sudo systemctl stop k3s-agent
sudo systemctl disable k3s-agent

# K3s Server mit Cluster-Join installieren
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://192.168.2.7:6443 \
  --token K10xxx...xxx \
  --tls-san 192.168.2.249 \
  --tls-san raspi4.elmstreet79.de \
  --tls-san 192.168.2.2 \
  --disable traefik \
  --write-kubeconfig-mode 644

# Service starten
sudo systemctl enable k3s
sudo systemctl start k3s
```

### Schritt 5: raspi5 zu Control Plane umwandeln

```bash
# Auf raspi5:
# Zuerst K3s Agent stoppen
sudo systemctl stop k3s-agent
sudo systemctl disable k3s-agent

# K3s Server mit Cluster-Join installieren
curl -sfL https://get.k3s.io | sh -s - server \
  --server https://192.168.2.7:6443 \
  --token K10xxx...xxx \
  --tls-san 192.168.2.249 \
  --tls-san raspi5.elmstreet79.de \
  --tls-san 192.168.2.9 \
  --disable traefik \
  --write-kubeconfig-mode 644

# Service starten
sudo systemctl enable k3s
sudo systemctl start k3s
```

### Schritt 6: Kube-VIP für Load Balancing installieren

```bash
# Auf allen Control Plane Nodes (prodesk, raspi4, raspi5):
# Kube-VIP Manifest erstellen
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

# Kube-VIP DaemonSet mit IP 192.168.2.249 erstellen
cat << EOF | kubectl apply -f -
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-vip-ds
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: kube-vip-ds
  template:
    metadata:
      labels:
        name: kube-vip-ds
    spec:
      hostNetwork: true
      nodeSelector:
        node-role.kubernetes.io/control-plane: "true"
      containers:
      - args:
        - manager
        env:
        - name: vip_arp
          value: "true"
        - name: port
          value: "6443"
        - name: vip_interface
          value: eth0
        - name: vip_cidr
          value: "32"
        - name: cp_enable
          value: "true"
        - name: cp_namespace
          value: kube-system
        - name: vip_ddns
          value: "false"
        - name: svc_enable
          value: "true"
        - name: vip_leaderelection
          value: "true"
        - name: vip_leaseduration
          value: "5"
        - name: vip_renewdeadline
          value: "3" 
        - name: vip_retryperiod
          value: "1"
        - name: address
          value: "192.168.2.249"
        image: ghcr.io/kube-vip/kube-vip:v0.6.4
        imagePullPolicy: Always
        name: kube-vip
        resources: {}
        securityContext:
          capabilities:
            add:
            - NET_ADMIN
            - NET_RAW
      serviceAccountName: kube-vip
      tolerations:
      - effect: NoSchedule
        operator: Exists
      - effect: NoExecute
        operator: Exists
EOF
```

### Schritt 7: Cluster Status überprüfen

```bash
# Auf einem Control Plane Node:
kubectl get nodes -o wide

# Kube-VIP Status prüfen
kubectl get pods -n kube-system | grep kube-vip

# etcd Cluster Status
kubectl get endpoints kube-scheduler -n kube-system -o yaml

# Control Plane Pods
kubectl get pods -n kube-system | grep -E "(kube-apiserver|kube-controller|kube-scheduler|etcd)"

# Virtuelle IP testen
ping 192.168.2.249
```

### Schritt 8: Node Labels anpassen

```bash
# Nach der Migration müssen die Labels angepasst werden:

# raspi3 bleibt Worker (Label sollte schon stimmen)
kubectl label node raspi3 node-role.kubernetes.io/worker=true arch=arm64 zone=pi-shelf --overwrite

# raspi4 ist jetzt Control Plane - Worker Label entfernen!
kubectl label node raspi4 node-role.kubernetes.io/worker- arch=arm64 zone=pi-shelf --overwrite

# raspi5 ist jetzt Control Plane - Worker Label entfernen!
kubectl label node raspi5 node-role.kubernetes.io/worker- arch=arm64 zone=pi-shelf --overwrite

# prodesk sollte schon die richtigen Labels haben, aber zur Sicherheit:
kubectl label node prodesk arch=amd64 zone=office --overwrite

# Labels überprüfen
kubectl get nodes --show-labels
```

### Schritt 9: kubeconfig aktualisieren

```bash
# Lokale kubeconfig auf Load Balancer IP umstellen
# ~/.kube/config oder /etc/rancher/k3s/k3s.yaml
apiVersion: v1
clusters:
- cluster:
    server: https://192.168.2.249:6443  # Load Balancer IP
  name: default
```

### Schritt 10: Anwendungen neu deployen

```bash
# Homelab Stack neu installieren (falls nötig)
./install-all.sh --force

# Oder einzelne Komponenten prüfen
kubectl get pods --all-namespaces
```

## 🧪 HA-Tests durchführen

### Test 1: Control Plane Node ausschalten
```bash
# Schalte prodesk aus
sudo shutdown -h now

# Auf einem anderen Node prüfen:
kubectl get nodes
kubectl get pods --all-namespaces

# Cluster sollte weiterhin funktionieren!
# API-Server sollte über 192.168.2.249 erreichbar sein
```

### Test 2: Mehrere Nodes nacheinander
```bash
# Teste verschiedene Kombinationen:
# - 1 Node down: ✅ Sollte funktionieren
# - 2 Nodes down: ❌ Cluster nicht verfügbar (etcd braucht Mehrheit)
# - Alle Worker down: ✅ Control Plane läuft weiter
```

### Test 3: Anwendungszugriff
```bash
# Prüfe, ob Services erreichbar bleiben:
curl -k https://argocd.elmstreet79.de
curl -k https://portainer.elmstreet79.de

# DNS-Auflösung (falls PiHole läuft):
nslookup google.com 192.168.2.250
```

## 🔍 Monitoring und Troubleshooting

### etcd Cluster Health
```bash
# etcd Member Status
kubectl exec -n kube-system etcd-prodesk -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/server-client.key \
  member list

# Cluster Health
kubectl exec -n kube-system etcd-prodesk -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/rancher/k3s/server/tls/etcd/server-ca.crt \
  --cert=/var/lib/rancher/k3s/server/tls/etcd/server-client.crt \
  --key=/var/lib/rancher/k3s/server/tls/etcd/server-client.key \
  endpoint health
```

### Logs überwachen
```bash
# K3s Logs auf Control Plane Nodes:
sudo journalctl -u k3s -f

# Pod Logs für kritische Services:
kubectl logs -n kube-system -l k8s-app=kube-dns
kubectl logs -n metallb-system -l app.kubernetes.io/component=controller
```

## ⚠️ Wichtige Hinweise

1. **Downtime während Migration**: Die Migration erfordert kurze Ausfallzeiten pro Node
2. **etcd Snapshots**: Nach der Migration regelmäßige etcd Snapshots aktivieren
3. **Kube-VIP kritisch**: Ohne Kube-VIP ist der Cluster nicht wirklich HA
4. **Netzwerk-Latenz**: Alle Control Planes sollten niedrige Latenz zueinander haben
5. **DNS-Problem**: Server nutzen 1.1.1.1, daher direkte IP-Konfiguration nötig

## 🔄 Rollback-Plan

Falls etwas schiefgeht:

```bash
# Alle neuen Control Planes stoppen
sudo systemctl stop k3s  # auf raspi4 und raspi5

# Original Master auf Single-Master zurücksetzen
sudo systemctl stop k3s  # auf prodesk
# K3s ohne cluster-init neu starten
sudo k3s server \
  --disable traefik \
  --write-kubeconfig-mode 644

# Worker Nodes neu joinen lassen
# (Token von prodesk holen und neu joinen)
```

## 📈 Nach der Migration

Wenn alles läuft:

1. **Kube-VIP überwachen**: Stelle sicher, dass die virtuelle IP 192.168.2.249 funktioniert
2. **Backup-Strategie**: Setze automatische etcd Snapshots auf
3. **Monitoring einrichten**: Überwache CPU/RAM/Disk auf allen Control Planes
4. **Updates planen**: Rolling Updates sind jetzt möglich
5. **Optional: DNS einrichten**: Später kann `api.elmstreet79.de` → 192.168.2.249 hinzugefügt werden

---

**Bereit für die Migration? Die Anleitung ist jetzt an deine Umgebung angepasst!**
