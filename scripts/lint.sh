#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "Error: shellcheck is required. Install it first (e.g. sudo apt install -y shellcheck)." >&2
  exit 1
fi

shellcheck -x \
  scripts/grafana-lib.sh \
  scripts/lint.sh \
  scripts/deploy-alerts.sh \
  scripts/deploy-dashboards.sh
echo "shellcheck passed."

python3 -m py_compile ansible/roles/trivy-host-scan/files/trivy-host-scan
find . -name __pycache__ -prune -exec rm -rf {} +
echo "python compile passed."

for f in grafana-cloud/dashboards/*.json; do
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$f"
done
echo "dashboard JSON parses."

python3 -c 'import yaml,sys; [yaml.safe_load(open(f)) for f in sys.argv[1:]]' \
  grafana-cloud/alerts/trivy-alerts.yaml ROADMAP.yaml
echo "YAML parses."
