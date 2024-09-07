# .NET 開發建置環境

## 環境需求

- [Podman](https://podman.io/)
- [Podman Compose](https://github.com/containers/podman-compose)

## 建置容器映像

```sh
# 建置所有的容器映像
podman-compose build

# 建置指定服務的映像檔
podman-compose build mono

# 建置指定系統架構的映像檔
podman-compose build --platform=linux/amd64
```

## 利用容器執行指令

```sh
# 執行 dotnet CLI
$ podman-compose run --rm mono dotnet --info
.NET SDK:
 Version:           8.0.303
 Commit:            29ab8e3268
 Workload version:  8.0.300-manifests.c915c39d
 MSBuild version:   17.10.4+10fbfbf2e

Runtime Environment:
 OS Name:     debian
 OS Version:  12
 OS Platform: Linux
 RID:         linux-arm64
 Base Path:   /usr/share/dotnet/sdk/8.0.303/

.NET workloads installed:
There are no installed workloads to display.

Host:
  Version:      8.0.7
  Architecture: arm64
  Commit:       2aade6beb0

.NET SDKs installed:
  8.0.303 [/usr/share/dotnet/sdk]

.NET runtimes installed:
  Microsoft.AspNetCore.App 6.0.32 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.AspNetCore.App 8.0.7 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 6.0.32 [/usr/share/dotnet/shared/Microsoft.NETCore.App]
  Microsoft.NETCore.App 8.0.7 [/usr/share/dotnet/shared/Microsoft.NETCore.App]

Other architectures found:
  None

Environment variables:
  Not set

global.json file:
  Not found

Learn more:
  https://aka.ms/dotnet/info

Download .NET:
  https://aka.ms/dotnet/download

# 執行 msbuild
$ podman-compose run --rm mono msbuild -version
Microsoft (R) Build Engine version 16.10.1 for Mono
Copyright (C) Microsoft Corporation. All rights reserved.

16.10.1.31701

# 執行 node
$ podman-compose run --rm node node --version
v20.17.0

# 執行 npm
$ podman-compose run --rm node npm --version
10.8.2
```

## 疑難排解

### 如何跨平台建置目標為 .NET Framework 的傳統 .NET 應用程式

可透過 msbuild for [Mono](https://www.mono-project.com/) 來達成

### 如何跨平台建置目標為 .NET Framework 的 [.NET SDK 應用程式](https://learn.microsoft.com/dotnet/core/project-sdk/overview)

可透過安裝 [Microsoft.NETFramework.ReferenceAssemblies](https://www.nuget.org/packages/Microsoft.NETFramework.ReferenceAssemblies/) 套件來解決

```xml
<PackageReference Include="Microsoft.NETFramework.ReferenceAssemblies" Version="1.0.3" PrivateAssets="All" Condition="$(TargetFramework.StartsWith('net4')) AND '$(OS)' != 'Windows_NT'"/>
```

### [如何跨平台測試目標為 .NET Framework 的 .NET SDK 應用程式](https://cake-contrib.github.io/Cake.Recipe/docs/known-issues/running-xunit-tests-on-net-framework)

> 執行環境需要安裝 [Mono](https://www.mono-project.com/)

可透過安裝 [Microsoft.TestPlatform.ObjectModel](https://www.nuget.org/packages/Microsoft.TestPlatform.ObjectModel/) 套件來達成

```xml
<PackageReference Include="Microsoft.TestPlatform.ObjectModel" Version="17.11.1" Condition="$(TargetFramework.StartsWith('net4')) AND '$(OS)' != 'Windows_NT'" />
```

## 參考資料

- [Multi-Targeting .NET Framework & .NET Core](https://github.com/mono/docker/issues/63)
- [Build for desktop framework on non-windows platforms](https://github.com/dotnet/sdk/issues/335)
