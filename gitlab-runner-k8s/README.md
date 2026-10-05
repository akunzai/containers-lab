# [GitLab Runner](https://docs.gitlab.com/runner/) Kubernetes executor

在本機以 [k3d](https://k3d.io/)（k3s in Docker）建置共用 GitLab Runner 的設定範例：Runner 以 Helm 部署、每個 Job 是拋棄式 Pod、以 namespace + ResourceQuota 控管用量、不使用 S3 / 分散式快取。

```text
Docker Compose 網路 gitlab-runner-k8s_default
├── gitlab         GitLab CE (http://localhost:8929)
├── deploy-target  rsync 部署目標 (sshd, port 2222)
└── k3d 叢集 gitlab-runner (k3s)
    ├── gitlab-runner namespace  Runner 管理 Pod
    └── ci-jobs namespace        Job Pod (ResourceQuota)
```

## 環境需求

- [Docker](https://www.docker.com/) 或 [OrbStack](https://orbstack.dev/)（建議，記憶體需求約 8 GB 以上）
- [mise](https://mise.jdx.dev/)：安裝 `helm`、`k3d`、`kubectl`

## Getting Started

```sh
# 安裝工具並載入環境
mise install && eval "$(mise env)"

# 產生 root 密碼與部署用 SSH 金鑰 (存放於 .secrets/)
./scripts/init-secrets.sh

# 啟動 GitLab 與部署目標 (GitLab 首次啟動約需數分鐘)
docker compose up -d
cat .secrets/gitlab_root.pwd

# 在 http://localhost:8929 以 root 登入, 於 Admin > CI/CD > Runners
# 建立 instance runner, 複製 glrt- 開頭的 token, 然後部署 Runner
RUNNER_TOKEN=glrt-... ./scripts/k8s-up.sh

# 以 kubeconfig 操作叢集 (不會更動 ~/.kube/config)
export KUBECONFIG=$PWD/.secrets/kubeconfig
kubectl -n gitlab-runner get pods
kubectl -n ci-jobs describe resourcequota ci-jobs
```

### Apple Silicon (arm64)

Kubernetes executor 預設假設 amd64, 在 arm64 主機會因 helper image 拉取失敗而無法執行 Job。
請改以 `k8s/runner-values.arm64.yaml` 覆蓋 (指定 `kubernetes.io/arch` node selector):

```sh
helm upgrade gitlab-runner gitlab/gitlab-runner --version 0.93.0 -n gitlab-runner \
  -f k8s/runner-values.yaml -f k8s/runner-values.arm64.yaml --wait
```

### 驗證部署流程

1. 建立專案並放入 [`example/.gitlab-ci.yml`](./example/.gitlab-ci.yml)
2. 新增專案 CI/CD 變數（皆為 File 類型, `SSH_PRIVATE_KEY` 另設 Protected）:
   - `SSH_PRIVATE_KEY`: `.secrets/deployer` 的內容
   - `SSH_KNOWN_HOSTS`: `ssh-keyscan -p 2222 deploy-target` 的輸出 (在 compose 網路內執行)
3. 在 `main` 觸發 pipeline, 完成後檢查 `docker compose exec deploy-target cat /config/www/index.html`

## 設定重點

| 項目 | 設定 | 位置 |
| --- | --- | --- |
| 全域併發上限 | `concurrent: 4` | `k8s/runner-values.yaml` |
| Job 資源 | requests 500m / 1Gi, limits 2 / 2Gi | `k8s/runner-values.yaml` |
| 命名空間資源配額 | `ResourceQuota` | `k8s/ci-jobs.yaml` |
| 快取 | 不設定 `[runners.cache]`（不使用 S3） | `k8s/runner-values.yaml` |
| 部署金鑰 | 專案 CI/CD File 變數, 不存放於 Runner | `example/.gitlab-ci.yml` |

## 已驗證

- Runner 以 Helm 部署並向 GitLab 註冊, Job 以拋棄式 Pod 執行, 結束後 Pod 被刪除
- Pod 內可 clone、建置、上傳 artifacts, 並以 rsync 部署至 `deploy-target`
- 超過 `memory_limit` 的 Job 被 `OOMKilled`, 不影響其他 Job
- 6 個平行 Job 在 `concurrent: 4` 下同時最多 4 個 Pod 執行, 其餘排隊, 全數成功
- 以 `docker:dind` 服務在 Job Pod 內 `docker build` 與 `docker run` 成功 (見下方)
- 以 rootless BuildKit 在 `privileged = false` 的 Runner 上建置映像成功 (見下方)

## 實測發現

- **ResourceQuota 不會讓 Job 排隊**: 超額時 Pod 建立被拒絕, Job 直接以 `runner_system_failure` 失敗; 排隊要靠 `concurrent`
- **刪除中 (Terminating) 的 Pod 仍佔配額**: 配額須有餘裕 (約 `concurrent` x 單一 Pod 用量的 2 倍), 否則併發高峰會隨機失敗
- **啟用配額後所有容器都必須宣告 requests / limits**: `services:` 容器未設定會被拒絕, 以 `LimitRange` 補預設值並設定 `service_*` 資源
- **Job 內 `docker build` 需 `privileged = true`**: 此設定作用於整個 Runner, 生產環境建議另設專用 Runner (以 tag 區分), 一般 Runner 維持 `privileged = false`

### Docker build (DinD)

於 `runner-values.yaml` 的 `[runners.kubernetes]` 加入 `privileged = true` 後套用, 範例見 [`example/docker-build.gitlab-ci.yml`](./example/docker-build.gitlab-ci.yml)。
Testcontainers 使用同一個 `DOCKER_HOST`, 不需另外設定 (此範例未測試 Testcontainers 本身)。

### 免特權建置 (rootless BuildKit)

不需 `privileged`, 使用 [`moby/buildkit`](https://hub.docker.com/r/moby/buildkit) 的 `rootless` 映像, 範例見 [`example/buildkit.gitlab-ci.yml`](./example/buildkit.gitlab-ci.yml)。
在預設 k3s 節點 (預設 seccomp / AppArmor 設定) 上, `privileged = false` 的 Runner 可直接建置。
節點若啟用 `RuntimeDefault` seccomp 或限制 user namespace, 可能需要額外的 `securityContext`, 需依環境調整。
BuildKit 只負責建置, 不提供 Docker API, 因此需要 `docker run` 或 Testcontainers 的 Job 仍須使用 DinD。

## 生產環境考量與差異

- 本機為單節點實驗環境, 無法代表實際叢集容量, 建議依目標環境進行壓力測試與資源評估
- 範例中 GitLab 以 HTTP 與內部主機名連線, 生產環境應使用 HTTPS 與正式網域
- 尚未驗證 Buildah 與 Testcontainers 本身, 以及節點啟用 `RuntimeDefault` seccomp 時的 rootless BuildKit

## 清理

```sh
./scripts/k8s-down.sh
docker compose down -v
```
