# Manual setup (without Ansible)

These steps reproduce what the Ansible role does, for a single host.

## 1. Install Trivy

Download a release and verify its checksum (replace the version with the one pinned in
`ansible/roles/trivy-host-scan/defaults/main.yml`):

```bash
V=0.0.0   # use the pinned version
cd "$(mktemp -d)"
curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${V}/trivy_${V}_Linux-64bit.tar.gz"
curl -fsSLO "https://github.com/aquasecurity/trivy/releases/download/v${V}/trivy_${V}_checksums.txt"
sha256sum --ignore-missing -c "trivy_${V}_checksums.txt"
sudo tar -xzf "trivy_${V}_Linux-64bit.tar.gz" -C /usr/local/bin trivy
trivy --version
```

(Use `Linux-ARM64` on aarch64.)

## 2. Install the wrapper and its config

```bash
sudo mkdir -p /etc/trivy-host-scan /var/cache/trivy/tmp /var/lib/node_exporter/textfile_collector
sudo install -m 0755 ansible/roles/trivy-host-scan/files/trivy-host-scan /usr/local/bin/trivy-host-scan
sudo tee /etc/trivy-host-scan/config.json >/dev/null <<'JSON'
{
  "cache_dir": "/var/cache/trivy",
  "textfile_dir": "/var/lib/node_exporter/textfile_collector",
  "ignore_unfixed": true,
  "skip_dirs": ["/proc", "/sys", "/dev", "/run", "/var/lib/docker", "/var/lib/containerd", "/mnt", "/media", "/srv", "/home"],
  "scan_docker_images": true
}
JSON
```

## 3. Install the systemd units

Copy `ansible/roles/trivy-host-scan/templates/trivy-host-scan.service.j2` and `.timer.j2`
to `/etc/systemd/system/`, replacing the Jinja placeholders:

- `{{ trivy_cache_dir }}` → `/var/cache/trivy`
- `{{ trivy_timer_oncalendar }}` → `Sun *-*-* 03:30:00`
- `{{ trivy_timer_random_delay }}` → `2h`

Then:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now trivy-host-scan.timer
sudo systemctl start trivy-host-scan.service     # first scan now
```

## 4. Ship the metrics

Add the textfile directory to your Alloy (or node_exporter) config, see
[`alloy/config-snippet.alloy`](../alloy/config-snippet.alloy), then confirm the series exist:

```promql
trivy_host_scan_success
trivy_host_vulnerabilities{severity="CRITICAL"}
```

## 5. Dashboards and alerts

```bash
cp .env.example .env && $EDITOR .env
./scripts/deploy-dashboards.sh
./scripts/deploy-alerts.sh
```
