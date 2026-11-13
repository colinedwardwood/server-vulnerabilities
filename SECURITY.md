# Security Policy

## Supported versions

Only the latest commit on the `main` branch receives security fixes. There are no versioned releases at this time.

## Reporting a vulnerability

**Please do not open a public GitHub Issue for security vulnerabilities.**

To report a security issue privately:

1. Go to the repository's **Security** tab on GitHub.
2. Click **"Report a vulnerability"** to open a private advisory draft.
3. Include the vulnerability description, steps to reproduce, and any suggested fixes.

If the issue is confirmed, a fix will be prioritised and a GitHub Security Advisory published once resolved.

## Credential hygiene

This repository ships **no credentials**. The files `.env`, `grafana-api.key`, and `grafana-cloud.instance` are all listed in `.gitignore` and must never be committed. If you believe a credential has been accidentally exposed in a commit, rotate it immediately and report the incident as above.

## Scope

The following are considered in scope for security reports:

- Shell injection or credential leakage in any deploy script.
- Privilege escalation via the Ansible role or the `trivy-host-scan` wrapper (it runs as root).
- Insecure defaults that expose credentials, or write metrics to a world-writable location.
- Supply-chain risks in the Trivy download (the role verifies the published SHA-256 checksums).

The following are out of scope:

- Vulnerabilities in third-party software (Trivy, Grafana Alloy, Docker). Report those upstream.
- Vulnerabilities that Trivy reports in your own hosts or images. Those are findings, not defects of this project.
- Issues that require physical access to the host.
