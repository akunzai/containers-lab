
using System.Collections;
using System.Net.NetworkInformation;
using System.Net.Sockets;
using Microsoft.AspNetCore.Http.Extensions;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

app.Map("/", async (HttpRequest request, HttpResponse response) =>
{
    await response.WriteAsync($"Hostname: {Environment.MachineName}\r\n");
    await response.WriteAsync($"Scheme: {request.Scheme}\r\n");
    foreach (var ip in GetIpAddress())
    {
        await response.WriteAsync($"IP: {ip}\r\n");
    }
    await response.WriteAsync($"RemoteAddr: {request.HttpContext.Connection.RemoteIpAddress}\r\n");
    await response.WriteAsync($"{request.Method} {request.GetEncodedPathAndQuery()} {request.Protocol}\r\n");
    foreach (var header in request.Headers)
    {
        await response.WriteAsync($"{header.Key}: {header.Value}\r\n");
    }
});
app.Map("/env", async (HttpRequest request, HttpResponse response) =>
{
    foreach (var env in Environment.GetEnvironmentVariables()
                 .Cast<DictionaryEntry>()
                 .OrderBy(e => e.Key.ToString()))
    {
        await response.WriteAsync($"{env.Key}={env.Value}\r\n");
    }
});
app.Map("/api", async (HttpRequest request, HttpResponse response) =>
{
    await response.WriteAsJsonAsync(new
    {
        Hostname = Environment.MachineName,
        IP = GetIpAddress(),
        request.Method,
        Headers = request.Headers.ToDictionary(x => x.Key, x => x.Value.ToString()),
        Host = request.Host.Value,
        URL = request.GetEncodedPathAndQuery()
    });
});
app.Run();

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