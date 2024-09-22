FROM mcr.microsoft.com/dotnet/sdk:8.0 AS builder
WORKDIR /src

COPY . .
ENV \
	# Unset DOTNET_DiagnosticPorts for building
	DOTNET_DiagnosticPorts=
RUN dotnet publish -c Release -o /app

FROM mcr.microsoft.com/dotnet/aspnet:8.0
EXPOSE 8080
WORKDIR /app
COPY --from=builder /app .
CMD ["./DiagnosticScenarios"]