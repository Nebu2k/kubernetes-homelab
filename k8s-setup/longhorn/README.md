# Longhorn Distributed Storage Setup

Dieses Verzeichnis enthält die Kubernetes-Konfiguration für Longhorn v1.9.0 distributed storage.

## Features

- **Hochverfügbarkeit**: 3-fache Datenreplikation across Nodes
- **Automatisches Failover**: Bei Node-Ausfall automatischer Wechsel  
- **Web-Management-UI**: Grafische Verwaltung und Monitoring
- **Snapshots & Backups**: Eingebaute Backup-Funktionalität mit System-Backup
- **Live Volume Expansion**: Volumes können live vergrößert werden
- **Multiple StorageClasses**: Optimiert für verschiedene Anwendungsfälle
- **🆕 Offline Replica Rebuilding**: Rebuild von Replicas auch bei detached Volumes
- **🆕 Orphaned Instance Cleanup**: Automatische Bereinigung verwaister Instanzen
- **🆕 Recurring System Backups**: Regelmäßige Backups des gesamten Systems
- **🆕 Enhanced Metrics**: Verbesserte Prometheus-Metriken für Monitoring

## Dateien

- `values.yaml` - Helm-Konfiguration für Longhorn v1.9.0
- `install.sh` - Installationsskript
- `ingress.yaml` - Ingress für Longhorn Web-UI
- `storage-classes.yaml` - Verschiedene StorageClass-Definitionen
- `MIGRATION.md` - Detaillierte Migrationsanleitung

## Anforderungen

- **Kubernetes**: v1.25 oder höher
- **Nodes**: Open-iSCSI und NFS-Common installiert
- **Storage**: Mindestens 10GB freier Platz pro Node

## Schnellstart

### 1. Node-Vorbereitung

Auf **allen Nodes** ausführen:

```bash
sudo apt update
sudo apt install -y open-iscsi nfs-common
sudo systemctl enable --now iscsid
```

### 2. Installation

```bash
# Longhorn installieren
./k8s-setup/longhorn/install.sh
```

### 3. Zugriff

- **Web-UI**: `http://<node-ip>:30080` (z.B. `http://192.168.2.7:30080`)
- **Nur intern**: Kein externer Zugriff, nur im lokalen Netzwerk
- **Kein Login erforderlich**: Direkter Zugriff ohne Authentifizierung

## StorageClasses

Nach der Installation sind folgende StorageClasses verfügbar:

| Name | Replicas | Default | Use Case | Performance |
|------|----------|---------|----------|-------------|
| `longhorn` | 3 | ✅ | Production | Balanced |
| `longhorn-fast` | 1 | ❌ | Cache/Temp | High |
| `longhorn-ha` | 3 | ❌ | Mission Critical | Lower |
| `local-path` | 1 | ❌ | Legacy | High |

## Verwendung

### Neue PVC erstellen

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
spec:
  accessModes:
    - ReadWriteOnce  
  storageClassName: longhorn  # 3 Replicas, HA
  resources:
    requests:
      storage: 10Gi
```

### Bestehende Services migrieren

Siehe `MIGRATION.md` für detaillierte Anweisungen zur Migration von `local-path` zu Longhorn.

## Node-Verteilung

Longhorn verteilt Daten automatisch auf deine Nodes:

- **prodesk** (Master): Kann Longhorn-Replicas hosten
- **raspi3** (Worker): Kann Longhorn-Replicas hosten  
- **raspi4** (Worker): Kann Longhorn-Replicas hosten
- **raspi5** (Worker): Kann Longhorn-Replicas hosten

Bei 3 Replicas werden die Daten auf 3 verschiedene Nodes verteilt.

## v1.9.0 Neue Features

### Offline Replica Rebuilding

Longhorn kann jetzt Replicas rebuilden, auch wenn das Volume detached ist:

```bash
# Feature Status prüfen
kubectl get setting.longhorn.io offline-replica-rebuilding -n longhorn-system

# In der Web-UI: Settings → General → Offline Replica Rebuilding
```

### Orphaned Instance Cleanup

Automatische Bereinigung verwaister Instanzen:

```bash
# Status prüfen
kubectl get setting.longhorn.io orphan-resource-auto-deletion -n longhorn-system

# Manueller Cleanup von Orphans
kubectl get orphan.longhorn.io -n longhorn-system
```

### System Backups

Recurring backups des gesamten Longhorn-Systems:

```bash
# System Backup erstellen
kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta2
kind: SystemBackup
metadata:
  name: system-backup-$(date +%Y%m%d)
  namespace: longhorn-system
spec:
  volumeBackupPolicy: if-not-present
EOF

# System Backups auflisten
kubectl get systembackup -n longhorn-system
```

### Enhanced Metrics

Neue Prometheus-Metriken für besseres Monitoring:

- `longhorn_volume_replica_count` - Anzahl Replicas per Volume
- `longhorn_volume_engine_status` - Engine-Status per Volume  
- `longhorn_node_status` - Node-Gesundheitsstatus
- `longhorn_volume_rebuild_status` - Rebuild-Status

## Monitoring

### CLI Commands

```bash
# Volume Status
kubectl get volumes.longhorn.io -n longhorn-system

# Node Status  
kubectl get nodes.longhorn.io -n longhorn-system

# StorageClass Status
kubectl get storageclass

# Longhorn Pods
kubectl get pods -n longhorn-system

# 🆕 System Backups
kubectl get systembackup -n longhorn-system

# 🆕 Orphaned Resources
kubectl get orphan.longhorn.io -n longhorn-system
```

### Web-UI Features

- Volume-Management und -Status
- Node-Gesundheit und -Auslastung
- Snapshot-Verwaltung
- Backup-Konfiguration
- Performance-Metriken
- **🆕 System Backup Management**
- **🆕 Orphaned Resource Cleanup**
- **🆕 Offline Rebuild Status**

## Backup-Strategien

### Lokale Snapshots

Automatische Snapshots können über die Web-UI oder CRDs konfiguriert werden.

### Remote Backups

Longhorn unterstützt Backups zu:

- S3-kompatible Storage (AWS, MinIO, etc.)
- NFS-Shares
- SMB/CIFS-Shares

Konfiguration über Web-UI: Settings → General → Backup Target

### 🆕 System Backups

Regelmäßige Backups des gesamten Longhorn-Systems:

1. Web-UI: System → System Backup → Create Recurring Job
2. Konfiguriere Zeitplan (Cron-Format)
3. Wähle Backup-Target

## Troubleshooting

### Version-spezifische Probleme

**v1.9.0 Regression (behoben)**:
- Problem: Recurring Jobs schlagen fehl
- Lösung: Verwendet automatisch `longhorn-manager:v1.9.0-hotfix-1`

### Häufige Befehle

```bash
# Longhorn System Status
kubectl get pods -n longhorn-system

# Volume Details
kubectl describe volume.longhorn.io <volume-name> -n longhorn-system

# Longhorn Manager Logs
kubectl logs -n longhorn-system -l app=longhorn-manager

# Node-spezifische Probleme
kubectl describe node.longhorn.io <node-name> -n longhorn-system
```

### Häufige Probleme

1. **Volume hängt in "Attaching"**
   - Node-Status prüfen
   - iSCSI-Service auf Nodes prüfen
   - Firewall-Regeln überprüfen

2. **Performance-Probleme**  
   - Anzahl Replicas reduzieren für bessere Performance
   - `longhorn-fast` StorageClass für nicht-kritische Daten verwenden
   - Node-Ressourcen und Disk-IO prüfen

3. **Speicherplatz-Probleme**
   - Node-Speicher über Web-UI monitoren
   - Alte Snapshots löschen
   - Volume-Größen anpassen

## Deinstallation

Falls nötig:

```bash
# Longhorn entfernen
helm uninstall longhorn -n longhorn-system

# Namespace löschen (Vorsicht: alle Daten gehen verloren!)
kubectl delete namespace longhorn-system

# local-path wieder als Default setzen
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

**⚠️ Warnung**: Bei der Deinstallation gehen alle Longhorn-Volumes und deren Daten verloren!
