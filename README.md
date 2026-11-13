# server-vulnerabilities

Automated vulnerability scanning for standalone Linux hosts and the Docker containers
on them, using [Trivy](https://trivy.dev), shipped to Grafana Cloud via Grafana Alloy.
A weekly systemd timer scans each host's OS packages and every running container image;
the results are written as Prometheus textfile-collector metrics, so there is no extra
exporter to run. Dashboards and alert rules show what is vulnerable, how bad it is, and
whether the scanner itself is still alive.

It is the companion of [server-compliance](https://github.com/colinedwardwood/server-compliance):
that repo answers "is this host configured securely (CIS controls)?", this one answers
"does this host run software with known, fixable vulnerabilities?".

## Architecture

```
Linux host
  ├─ systemd timer (weekly, randomised start)
  │    └─ trivy-host-scan.service  (Nice=19, idle I/O, CPUQuota=50%)
  │         └─ /usr/local/bin/trivy-host-scan
  │              ├─ trivy rootfs /     (OS packages, fixed-only)
  │              └─ trivy image <img>  (each running container image)
  │                   └─ /var/lib/node_exporter/textfile_collector/trivy_host.prom
  └─ Grafana Alloy (unix exporter, textfile collector)
       └─ remote_write → Grafana Cloud Prometheus (Mimir)

Grafana Cloud
  ├─ Dashboard   —  Trivy - Vulnerability Management
  └─ Alert rules —  scan stale / scan failing / critical CVEs (hosts and images)
```

## Repository layout

```
ansible/                      Automated deployment to Linux hosts
  site.yml                      Playbook
  inventory.yml                 Example inventory (placeholders)
  roles/trivy-host-scan/        Installs Trivy (checksum-verified), the scan wrapper, the timer

alloy/
  config-snippet.alloy          Minimal Alloy config to read the textfile and remote_write

grafana-cloud/                Everything deployed to Grafana Cloud
  alerts/trivy-alerts.yaml      SAAFE-model Prometheus alert rules
  dashboards/                   Dashboard JSON

scripts/
  grafana-lib.sh                Shared Grafana API helpers (sourced by deploy scripts)
  deploy-dashboards.sh          Push dashboards to Grafana Cloud
  deploy-alerts.sh              Push alert rules to Grafana Cloud
  lint.sh                       shellcheck, Python compile, JSON/YAML checks

docs/setup.md                 Manual (non-Ansible) setup
```

## Quick start

1. Deploy the scanner to your hosts:

   ```bash
   cd ansible
   $EDITOR inventory.yml          # list your hosts under trivy_targets
   ansible-playbook -i inventory.yml site.yml --check --diff
   ansible-playbook -i inventory.yml site.yml -l host1
   ```

2. Make sure Alloy reads the textfile directory and ships it
   ([`alloy/config-snippet.alloy`](alloy/config-snippet.alloy)).

3. Deploy the dashboard and alert rules:

   ```bash
   cp .env.example .env && $EDITOR .env       # GRAFANA_URL and GRAFANA_TOKEN
   ./scripts/deploy-dashboards.sh
   ./scripts/deploy-alerts.sh
   ```

4. Run a first scan now instead of waiting for the timer:

   ```bash
   sudo systemctl start trivy-host-scan.service
   ```

## Metrics reference

| Metric | Labels | Meaning |
|---|---|---|
| `trivy_host_vulnerabilities` | `target="host"`, `severity` | OS-package vulnerabilities on the host (CRITICAL, HIGH, MEDIUM, LOW) |
| `trivy_image_vulnerabilities` | `image`, `severity` | Vulnerabilities in each running container image |
| `trivy_host_scan_success` | | `1` if the host and all image scans succeeded, otherwise `0` |
| `trivy_host_scan_duration_seconds` | | Wall-clock duration of the last run |
| `trivy_host_scan_last_run_timestamp_seconds` | | Unix time of the last run (success or not) |
| `trivy_host_scan_last_success_timestamp_seconds` | | Unix time of the last fully successful run; kept across failures so staleness alerts can fire |

Grafana adds an `instance` label per host.

## Limits and design choices

- **Fixed-only by default.** `trivy_ignore_unfixed: true` counts only vulnerabilities for which a fixed version exists, so a non-zero count is actionable. Set it to `false` to see everything.
- **Weekly.** Scans are heavy on small or spinning-disk hosts. The unit runs at the lowest CPU and idle I/O priority with a 1 GiB memory cap and a randomised start so a fleet does not hit the vulnerability database mirror at once.
- **OS packages only for the host.** Language packages inside data directories, home directories and container storage are skipped (`trivy_rootfs_skip_dirs`); containers are scanned as images instead.
- **Kubernetes is out of scope.** For cluster workloads, an in-cluster operator such as trivy-operator is the better fit; this project is for standalone hosts. The two complement each other.
- **Not a patch manager.** It tells you what to update. It never changes packages.

## Security

See [SECURITY.md](SECURITY.md). No credentials are shipped in this repository.

## License

Apache License 2.0, see [LICENSE](LICENSE).
