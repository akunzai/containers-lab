#!/usr/bin/env bash
# 刪除 k3d 叢集 (Runner 與 Job Pod 一併移除)
set -euo pipefail
k3d cluster delete gitlab-runner
rm -f "$(dirname "$0")/../.secrets/kubeconfig"
