using System.Collections;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using System.Runtime.InteropServices;
using Microsoft.AspNetCore.Http.Extensions;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.MapFallback(async (HttpRequest request, HttpResponse response) =>
{
    await response.WriteAsync($"Hostname: {Environment.MachineName}\r\n");
    await response.WriteAsync($"DateTime: {DateTimeOffset.Now:O}\r\n");
    await response.WriteAsync($"Process Architecture: {RuntimeInformation.ProcessArchitecture}\r\n");
    await response.WriteAsync($"OS Version: {Environment.OSVersion}\r\n");
    await response.WriteAsync($"Runtime Version: {Environment.Version}\r\n");
    foreach (var ip in GetIpAddress())
    {
        await response.WriteAsync($"Server IP: {ip}\r\n");
    }

    await response.WriteAsync($"Client IP: {request.HttpContext.Connection.RemoteIpAddress}\r\n");
    await response.WriteAsync($"Protocol: {request.Protocol}\r\n");
    await response.WriteAsync($"Scheme: {request.Scheme}\r\n");
    await response.WriteAsync($"Host: {request.Host}\r\n");
    await response.WriteAsync($"Path: {request.Path}\r\n");
    if (request.QueryString.HasValue)
    {
        await response.WriteAsync($"Query: {request.QueryString.Value}\r\n");
    }

    await response.WriteAsync($"Method: {request.Method}\r\n");
    await response.WriteAsync("Headers:\r\n");
    foreach (var header in request.Headers.OrderBy(h => h.Key))
    {
        await response.WriteAsync($"- {header.Key}: {header.Value}\r\n");
    }
});
app.Map("/api", async (HttpRequest request, HttpResponse response) =>
{
    await response.WriteAsJsonAsync(new
    {
        Hostname = Environment.MachineName,
        DateTime = DateTimeOffset.Now,
        RuntimeVersion = Environment.Version,
        ProcessArchitecture = RuntimeInformation.ProcessArchitecture.ToString(),
        OSVersion = Environment.OSVersion.ToString(),
        ServerIP = GetIpAddress(),
        ClientIP = request.HttpContext.Connection.RemoteIpAddress?.ToString(),
        request.Protocol,
        request.Scheme,
        Host = request.Host.Value,
        request.Method,
        RequestedPath = request.Path.Value,
        QueryString = request.QueryString.HasValue ? request.QueryString.Value : null,
        Headers = request.Headers.ToDictionary(x => x.Key, x => x.Value.ToString()),
    });
});
app.Map("/env", async (HttpRequest _, HttpResponse response) =>
{
    foreach (var env in Environment.GetEnvironmentVariables()
                 .Cast<DictionaryEntry>()
                 .OrderBy(e => e.Key.ToString()))
    {
        await response.WriteAsync($"{env.Key}={env.Value}\r\n");
    }
});
app.Run();
return;

IEnumerable<string> GetIpAddress()
{
    foreach (var @interface in NetworkInterface.GetAllNetworkInterfaces())
    {
        if (@interface.OperationalStatus != OperationalStatus.Up) continue;

        foreach (var ip in @interface.GetIPProperties().UnicastAddresses)
        {
            if (ip.Address.AddressFamily != AddressFamily.InterNetwork) continue;
            yield return ip.Address.ToString();
        }
    }
}