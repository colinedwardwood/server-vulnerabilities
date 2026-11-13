# Ansible: Trivy host scan deployment

Deploys a weekly Trivy vulnerability scan to Linux hosts (Debian/Ubuntu tested)
and exposes the results as Prometheus textfile-collector metrics.

## What it installs

| Component | Notes |
|---|---|
| `trivy` | Pinned release (`trivy_version`), downloaded from GitHub releases and **checksum-verified** against the published `checksums.txt` |
| `/usr/local/bin/trivy-host-scan` | Python 3 wrapper (standard library only): runs Trivy and writes `trivy_host.prom` atomically |
| `/etc/trivy-host-scan/config.json` | Rendered from the role variables |
| `trivy-host-scan.service` / `.timer` | systemd oneshot, weekly, randomised start, `Nice=19`, idle I/O class, `CPUQuota=50%`, `MemoryMax=1G` |

The scan runs as root (it reads the root filesystem and talks to the Docker socket)
and writes only to the textfile collector directory and Trivy's cache.

## Prerequisites

- Ansible >= 2.14 on your workstation
- SSH access to the target hosts with passwordless `sudo`
- `python3` on the targets (the wrapper uses only the standard library)
- Docker on the target if `trivy_scan_docker_images: true`
- Something that reads the textfile directory and ships it to Grafana Cloud
  (see [`../alloy/config-snippet.alloy`](../alloy/config-snippet.alloy))

## Quick start

```bash
pip install ansible
$EDITOR inventory.yml                      # put your hosts under trivy_targets
ansible-playbook -i inventory.yml site.yml --check --diff
ansible-playbook -i inventory.yml site.yml -l host1       # one host first
```

Trigger a scan immediately instead of waiting for the timer:

```bash
sudo systemctl start trivy-host-scan.service
journalctl -u trivy-host-scan.service -n 50 --no-pager
cat /var/lib/node_exporter/textfile_collector/trivy_host.prom
```

## Variables

All variables are documented with defaults in
[`roles/trivy-host-scan/defaults/main.yml`](roles/trivy-host-scan/defaults/main.yml).

| Variable | Default | Description |
|---|---|---|
| `trivy_version` | pinned | Trivy release to install |
| `trivy_timer_oncalendar` | `Sun *-*-* 03:30:00` | systemd calendar expression |
| `trivy_timer_random_delay` | `2h` | spreads hosts out so they do not hit the vulnerability DB mirror together |
| `trivy_ignore_unfixed` | `true` | count only vulnerabilities that have a fix available |
| `trivy_rootfs_skip_dirs` | pseudo-fs, data mounts, container storage | directories skipped by the rootfs scan |
| `trivy_scan_docker_images` | `true` | also scan every running container image |
| `trivy_textfile_dir` | `/var/lib/node_exporter/textfile_collector` | where `trivy_host.prom` is written |
