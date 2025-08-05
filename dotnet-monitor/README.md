# [.NET 應用程式監控診斷工具](https://github.com/dotnet/dotnet-monitor/)

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## Getting Started

```sh
# 在背景啟動並執行完整應用
podman-compose up -d

# 驗證服務狀態
podman-compose ps
```

### [診斷情境範例 .NET 應用程式](https://github.com/dotnet/samples/tree/main/core/diagnostics/DiagnosticScenarios)

```sh
# 模擬 .NET 死結
curl -s http://localhost:8080/deadlock

# 模擬記憶體飆升，持續 30 秒
curl -s http://localhost:8080/memspike/30

# 模擬記憶體洩漏，指定洩漏大小為 2048 KB
curl -s http://localhost:8080/memleak/2048

# 模擬高 CPU 使用率，持續 3600 毫秒(ms)
curl -s http://localhost:8080/highcpu/3600

# 觸發例外狀況
curl -s http://localhost:8080/exception

# 同步等待非同步任務 (錯誤做法)
curl -s http://localhost:8080/taskwait

# 使用 Thread.Sleep 等待任務 (錯誤做法)
curl -s http://localhost:8080/tasksleepwait

# 使用正確的非同步等待
curl -s http://localhost:8080/taskasyncwait
```

### [.NET 監控工具](https://github.com/dotnet/dotnet-monitor/blob/main/documentation)

> 透過配置 .NET 應用程式容器的 [.NET 診斷端口設定](https://learn.microsoft.com/dotnet/core/diagnostics/diagnostic-port) 讓 .NET 監控工具得以跨容器收集診斷資料

```sh
# 取得監控工具版本及監控模式資訊
$ curl -s http://localhost:52323/info | jq
{
  "version": "9.0.3-servicing.25257.4+da975d6cb396be656758e4bee6d5745e400d3571",
  "runtimeVersion": "9.0.7",
  "diagnosticPortMode": "Listen",
  "diagnosticPortName": "/diag/dotnet-monitor.sock"
}

# 列出可存取的 .NET 處理序清單
curl -s http://localhost:52323/processes | jq

# 取得指定 .NET 處理序的基本資訊
curl -s 'http://localhost:52323/process?pid=1' | jq

# 取得指定 .NET 處理序的環境變數
curl -s 'http://localhost:52323/env?pid=1' | jq

# 取得指定 .NET 處理序的堆疊資訊
curl -s 'http://localhost:52323/stacks?pid=1'

# 匯出指定 .NET 處理序的堆疊資訊為 Speedscope 檔案格式
# > 匯出的檔案可透過 https://www.speedscope.app/ 進行分析
curl -so ./dotnet.speedscope 'http://localhost:52323/stacks?pid=1' -H 'Accept: application/speedscope+json'

# 收集指定 .NET 處理序的效能分析追蹤資料
curl -so ./dotnet.nettrace 'http://localhost:52323/trace?pid=1'

# 取得指定 .NET 處理序的例外資訊
curl -s 'http://localhost:52323/exceptions?pid=1'

# 擷取指定 .NET 處理序的日誌串流
curl -s 'http://localhost:52323/logs?pid=1'

# 收集指定 .NET 處理序的記憶體傾印資料
curl -so ./dotnet.dump 'http://localhost:52323/dump?pid=1'

# 收集指定 .NET 處理序的記憶體回收(GC)傾印資料
curl -so ./dotnet-gc.dump 'http://localhost:52323/gcdump?pid=1'

# 取得 Prometheus 格式的監控指標
curl -s http://localhost:52323/metrics
```

## 參考資料

- [.NET 診斷工具](https://learn.microsoft.com/dotnet/core/diagnostics/)
