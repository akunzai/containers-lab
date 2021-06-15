# https://hub.docker.com/_/microsoft-dotnet-sdk/
FROM mcr.microsoft.com/dotnet/sdk:5.0
# install ASP.NET Core 3.1 Runtime
COPY --from=mcr.microsoft.com/dotnet/aspnet:3.1 /usr/share/dotnet /usr/share/dotnet
# install msbuild for Mono
# https://www.mono-project.com/download/stable/#download-lin-debian
RUN set -eux; \
    apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https dirmngr gnupg ca-certificates \
    && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF \
    && echo "deb http://download.mono-project.com/repo/debian stable-buster main" > /etc/apt/sources.list.d/mono-official-stable.list \
    && apt-get update \
    && apt-get install -y mono-devel \
    # clean up
    && apt-get purge -y --auto-remove gnupg dirmngr \
    && rm -rf /var/lib/apt/lists/* /tmp/* \
    # smoke test
    && msbuild -version