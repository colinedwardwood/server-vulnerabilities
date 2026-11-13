# Contributing to server-vulnerabilities

This is an open-source Trivy vulnerability-scanning pipeline built on Trivy, Grafana Alloy, and Grafana Cloud. Contributions are welcome.

## Ways to contribute

- **Bug reports**: open a GitHub Issue with steps to reproduce, expected behaviour, and actual behaviour.
- **Feature requests**: open an Issue describing the use-case and why it matters.
- **Pull requests**: see the workflow below.

## Development setup

You will need:
- `shellcheck` for linting shell scripts (`brew install shellcheck` or `sudo apt install shellcheck`)
- `ansible-lint` if editing the Ansible role (`pip install ansible-lint`)
- `curl`, `jq` and `python3` with PyYAML for the deploy scripts

Run the linter suite:

```bash
./scripts/lint.sh
```

## Pull request workflow

1. Fork the repository and create a feature branch from `main`.
2. Make your changes.
3. Run `./scripts/lint.sh` and fix any warnings.
4. Open a PR against `main` with a clear description of the change and why it is needed.
5. PRs that touch the Ansible role should note which OS and version they were tested against.

## Coding conventions

- **Shell scripts**: follow shellcheck recommendations; use `set -euo pipefail`; prefer `[[ ]]` for tests.
- **Ansible**: use fully-qualified module names (`ansible.builtin.*`); tasks must be idempotent and safe in `--check` mode.
- **Python**: standard library only in the scan wrapper; follow PEP 8.
- **GitHub Actions**: pin third-party actions to a full commit SHA with a trailing version comment.
- **No private data**: do not commit real hostnames, IP addresses, domains, or tokens, even in examples.

## Commit messages

Use the conventional commits style:

```
fix: keep the last success timestamp when a scan fails
feat: add per-image CRITICAL alert
chore: bump pinned Trivy release
```

## Reporting security issues

Please follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
