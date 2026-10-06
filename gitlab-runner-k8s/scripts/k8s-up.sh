#!/usr/bin/env bash
# 建立 k3d 叢集 (k3s in Docker), 並以 Helm 部署 GitLab Runner (Kubernetes executor)
# 前置: ./scripts/init-secrets.sh && docker compose up -d, 且已建立 instance runner 並取得 token
# 用法: RUNNER_TOKEN=glrt-... ./scripts/k8s-up.sh
set -euo pipefail
cd "$(dirname "$0")/.."
: "${RUNNER_TOKEN:?請先在 GitLab 管理介面建立 instance runner 並設定 RUNNER_TOKEN}"

CLUSTER=gitlab-runner
# 不改動使用者既有的 ~/.kube/config
export KUBECONFIG="${PWD}/.secrets/kubeconfig"

if ! k3d cluster get "${CLUSTER}" >/dev/null 2>&1; then
  # 加入 compose 網路, Pod 才能以 gitlab / deploy-target 名稱存取
  k3d cluster create "${CLUSTER}" \
    --image docker.io/rancher/k3s:v1.36.5-k3s1 \
    --network gitlab-runner-k8s_default \
    --servers 1 --agents 0 \
    --k3s-arg "--disable=traefik@server:*" \
    --k3s-arg "--disable=servicelb@server:*" \
    --no-lb \
    --kubeconfig-update-default=false --kubeconfig-switch-context=false
fi
k3d kubeconfig get "${CLUSTER}" > "${KUBECONFIG}"
chmod 600 "${KUBECONFIG}"

kubectl apply -f k8s/ci-jobs.yaml
kubectl create namespace gitlab-runner --dry-run=client -o yaml | kubectl apply -f -
kubectl -n gitlab-runner create secret generic gitlab-runner-token \
  --from-literal=runner-token="${RUNNER_TOKEN}" \
  --from-literal=runner-registration-token="" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add gitlab https://charts.gitlab.io >/dev/null
helm repo update gitlab >/dev/null
helm upgrade --install gitlab-runner gitlab/gitlab-runner --version 0.93.0 \
  --namespace gitlab-runner -f k8s/runner-values.yaml --wait
