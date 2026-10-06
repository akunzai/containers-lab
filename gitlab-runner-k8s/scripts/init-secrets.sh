#!/usr/bin/env bash
# 產生本機實驗用的密碼與部署用 SSH 金鑰 (已存在則略過)
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p .secrets
[[ -f .secrets/gitlab_root.pwd ]] || openssl rand -base64 18 | tr -d '\n' > .secrets/gitlab_root.pwd
[[ -f .secrets/deployer ]] || ssh-keygen -q -t ed25519 -N '' -C deployer@gitlab-runner-k8s -f .secrets/deployer
chmod 600 .secrets/gitlab_root.pwd .secrets/deployer
chmod 644 .secrets/deployer.pub
