# .NET 開發建置環境

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)
- [Docker Compose V2](https://docs.docker.com/compose/cli-command/)

## 建置容器映像

```sh
# 建置所有的容器映像
docker compose build

# 建置指定服務的映像檔
docker compose build mono

# 建置指定系統架構的映像檔
docker build --platform=linux/amd64 -t dotnet-sdk:mono --build-arg APT_URL=http://free.nchc.org.tw .
docker build --platform=linux/amd64 -t dotnet-sdk:node -f ./Dockerfile.node --build-arg APT_URL=http://free.nchc.org.tw .
```

## 利用容器執行指令

```sh
# 執行 dotnet CLI
$ docker compose run -it --rm mono dotnet --info
.NET SDK:
 Version:   7.0.102
 Commit:    4bbdd14480

Runtime Environment:
 OS Name:     debian
 OS Version:  11
 OS Platform: Linux
 RID:         debian.11-x64
 Base Path:   /usr/share/dotnet/sdk/7.0.102/

Host:
  Version:      7.0.2
  Architecture: x64
  Commit:       d037e070eb

.NET SDKs installed:
  7.0.102 [/usr/share/dotnet/sdk]

.NET runtimes installed:
  Microsoft.AspNetCore.App 6.0.13 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.AspNetCore.App 7.0.2 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 6.0.13 [/usr/share/dotnet/shared/Microsoft.NETCore.App]
  Microsoft.NETCore.App 7.0.2 [/usr/share/dotnet/shared/Microsoft.NETCore.App]

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
$ docker compose run --rm mono msbuild -version
Microsoft (R) Build Engine version 16.10.1 for Mono
Copyright (C) Microsoft Corporation. All rights reserved.

16.10.1.31701

# 執行 npm
$ docker compose run --rm node npm --version
9.3.1

# 執行 yarn
$ docker compose run --rm node yarn --version
1.22.19
```

## 疑難排解

### 如何跨平台建置目標為 .NET Framework  的傳統 .NET 應用程式

可透過 msbuild for [Mono](https://www.mono-project.com/) 來達成

### 如何跨平台建置目標為 .NET Framework  的 [.NET SDK 應用程式](https://learn.microsoft.com/dotnet/core/project-sdk/overview)

可透過安裝 [Microsoft.NETFramework.ReferenceAssemblies](https://www.nuget.org/packages/Microsoft.NETFramework.ReferenceAssemblies/) 套件來解決

```xml
<PackageReference Include="Microsoft.NETFramework.ReferenceAssemblies" Version="1.0.3" PrivateAssets="All" Condition="$(TargetFramework.StartsWith('net4')) AND '$(OS)' != 'Windows_NT'"/>
```

### [如何跨平台測試目標為 .NET Framework 的 .NET SDK 應用程式](https://cake-contrib.github.io/Cake.Recipe/docs/known-issues/running-xunit-tests-on-net-framework)

> 執行環境需要安裝 [Mono](https://www.mono-project.com/)

可透過安裝 [Microsoft.TestPlatform.ObjectModel](https://www.nuget.org/packages/Microsoft.TestPlatform.ObjectModel/) 套件來達成

```xml
<PackageReference Include="Microsoft.TestPlatform.ObjectModel" Version="17.4.0" Condition="$(TargetFramework.StartsWith('net4')) AND '$(OS)' != 'Windows_NT'" />
```

## 參考資料

- [Multi-Targeting .NET Framework & .NET Core](https://github.com/mono/docker/issues/63)
- [Build for desktop framework on non-windows platforms](https://github.com/dotnet/sdk/issues/335)
