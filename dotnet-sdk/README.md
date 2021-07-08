# .NET 建置環境 for Docker

用於建置多目標的 .NET 應用程式

## 支援的建置目標

- .NET Framework
- .NET Core 3.1
- .NET 5.0

## 環境需求

- [Docker Engine](https://docs.docker.com/install/)

## 建置容器映像

```sh
docker build -t dotnet:sdk-msbuild .
```

## 利用容器執行指令

```sh
# 執行 dotnet CLI
$ docker run -it --rm dotnet:sdk-msbuild dotnet --info
.NET SDK (reflecting any global.json):
 Version:   5.0.301
 Commit:    ef17233f86

Runtime Environment:
 OS Name:     debian
 OS Version:  10
 OS Platform: Linux
 RID:         debian.10-x64
 Base Path:   /usr/share/dotnet/sdk/5.0.301/

Host (useful for support):
  Version: 5.0.7
  Commit:  556582d964

.NET SDKs installed:
  5.0.301 [/usr/share/dotnet/sdk]

.NET runtimes installed:
  Microsoft.AspNetCore.App 3.1.16 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.AspNetCore.App 5.0.7 [/usr/share/dotnet/shared/Microsoft.AspNetCore.App]
  Microsoft.NETCore.App 3.1.16 [/usr/share/dotnet/shared/Microsoft.NETCore.App]
  Microsoft.NETCore.App 5.0.7 [/usr/share/dotnet/shared/Microsoft.NETCore.App]

To install additional .NET runtimes or SDKs:
  https://aka.ms/dotnet-download

# 執行 msbuild
$ docker run --rm dotnet:sdk-msbuild msbuild -version
Microsoft (R) Build Engine version 16.6.0 for Mono
Copyright (C) Microsoft Corporation. All rights reserved.

16.6.0.15201

# 執行 Bash Shell
$ docker run -it --rm dotnet:sdk-msbuild bash
```

## 疑難排解

### 如何跨平台建置目標為 .NET Framework  的傳統 .NET 應用程式

可透過 msbuild for [Mono](ttps://www.mono-project.com/) 來達成

### 如何跨平台建置目標為 .NET Framework  的 [.NET SDK 應用程式](https://docs.microsoft.com/dotnet/core/project-sdk/overview)

可透過安裝 [Microsoft.NETFramework.ReferenceAssemblies](https://www.nuget.org/packages/Microsoft.NETFramework.ReferenceAssemblies/) 套件來解決

```xml
<PackageReference Include="Microsoft.NETFramework.ReferenceAssemblies" Version="1.0.2" PrivateAssets="All" Condition="$(TargetFramework.StartsWith('net4')) AND '$(OS)' != 'Windows_NT'"/>
```

### [如何跨平台測試目標為 .NET Framework 的 .NET SDK 應用程式](https://cake-contrib.github.io/Cake.Recipe/docs/known-issues/running-xunit-tests-on-net-framework)

> 執行環境需要安裝 [Mono](ttps://www.mono-project.com/)

可透過安裝 [Microsoft.TestPlatform.ObjectModel](https://www.nuget.org/packages/Microsoft.TestPlatform.ObjectModel/) 套件來達成

```xml
<PackageReference Include="Microsoft.TestPlatform.ObjectModel" Version="16.10.0" Condition="'$(OS)' != 'Windows_NT'" />
```

## 參考資料

- [Multi-Targeting .NET Framework & .NET Core](https://github.com/mono/docker/issues/63)
- [Build for desktop framework on non-windows platforms](https://github.com/dotnet/sdk/issues/335)