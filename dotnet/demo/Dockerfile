# Learn about building .NET container images:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/README.md
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0-alpine AS build
ARG TARGETARCH
WORKDIR /source

# Copy project file and restore as distinct layers
COPY *.csproj .
RUN dotnet restore -a $TARGETARCH

# Copy source code and publish app
COPY . .
RUN dotnet publish -a $TARGETARCH --no-restore -o /app

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0-alpine AS runtime
# Enable globalization and time zones:
# https://github.com/dotnet/dotnet-docker/blob/main/samples/enable-globalization.md
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false \
	LC_ALL=en_US.UTF-8 \
	LANG=en_US.UTF-8
RUN apk add --no-cache \
	icu-data-full \
	icu-libs;
EXPOSE 8080
WORKDIR /app
COPY --chown=app:app --from=build /app .
USER app
CMD ["./demo"]