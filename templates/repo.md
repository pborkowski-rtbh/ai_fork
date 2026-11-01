---
goal: One line saying what this repo is for
path: folder-name-relative-to-the-workspace
host_cli: gh
min_rung:
setup: npm ci
check: npm test
check: npm run lint
check_timeout: 600
protected_branch: develop
environment: name-of-a-section-in-environments.md
cloud_access: none
cloud_aws_profile:
cloud_gcloud_config:
cloud_azure_config_dir:
cloud_kubeconfig:
connectors: none
---

## Goal and current priority

What this repo is for, and what matters most right now.

## Restrictions

Guidance for workers. This text is advisory. Anything that must never happen belongs in a `deny` rule in `<repo>.settings.json`, or a hook.
