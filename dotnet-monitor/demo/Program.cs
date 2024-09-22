// see https://github.com/dotnet/samples/tree/main/core/diagnostics/DiagnosticScenarios
using System.Diagnostics;

var builder = WebApplication.CreateBuilder(args);

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}

var o1 = new object();
var o2 = new object();
var p = new Processor();

app.MapGet("/", () => "DiagnosticScenarios");
app.MapGet("/api/deadlock", () =>
{
    new Thread(() =>
    {
        lock (o1)
        {
            new Thread(() =>
            {
                lock (o2)
                {
                    Monitor.Enter(o1);
                }
            }).Start();

            Thread.Sleep(2000);
            Monitor.Enter(o2);
        }
    }).Start();

    Thread.Sleep(5000);

    var threads = new Thread[300];
    for (var i = 0; i < 300; i++)
    {
        (threads[i] = new Thread(() =>
        {
            lock (o1)
            {
                Thread.Sleep(100);
            }
        })).Start();
    }

    foreach (var thread in threads)
    {
        thread.Join();
    }

    return "success:deadlock";
});
app.MapGet("/api/memspike/{seconds:int}", (int seconds) =>
{
    var watch = new Stopwatch();
    watch.Start();

    while (true)
    {
        p = new Processor();
        watch.Stop();
        if (watch.ElapsedMilliseconds > seconds * 1000)
            break;
        watch.Start();

        const int it = (2000 * 1000);
        for (var i = 0; i < it; i++)
        {
            p.ProcessTransaction(new Customer(Guid.NewGuid().ToString()));
        }

        Thread.Sleep(5000); // Sleep for 5 seconds before cleaning up

        // Cleanup
        p = null;

        // GC
        GC.Collect();
        GC.WaitForPendingFinalizers();
        GC.Collect();

        Thread.Sleep(5000); // Sleep for 5 seconds before spiking memory again
    }

    return "success:memspike";
});
app.MapGet("memleak/{kb:int}", (int kb) =>
{
    var it = (kb * 1000) / 100;
    for (var i = 0; i < it; i++)
    {
        p.ProcessTransaction(new Customer(Guid.NewGuid().ToString()));
    }

    return "success:memleak";
});
app.MapGet("exception", () => { throw new Exception("bad, bad code"); });
app.MapGet("highcpu/{milliseconds:int}", (int milliseconds) =>
{
    var watch = new Stopwatch();
    watch.Start();

    while (true)
    {
        watch.Stop();
        if (watch.ElapsedMilliseconds > milliseconds)
            break;
        watch.Start();
    }

    return "success:highcpu";
});
app.MapGet("taskwait", () =>
{
    var c = PretendQueryCustomerFromDbAsync("Dana").Result;
    return "success:taskwait";
});
app.MapGet("tasksleepwait", () =>
{
    Task dbTask = PretendQueryCustomerFromDbAsync("Dana");
    while(!dbTask.IsCompleted)
    {
        Thread.Sleep(10);
    }
    return "success:tasksleepwait";
});
app.MapGet("taskasyncwait", async () =>
{
    var c = await PretendQueryCustomerFromDbAsync("Dana");
    return "success:taskasyncwait";
});

app.Run();
return;

async Task<Customer> PretendQueryCustomerFromDbAsync(string customerId)
{
    await Task.Delay(500);
    return new Customer(customerId);
}

internal class Customer
{
    private string _id;

    public Customer(string id)
    {
        _id = id;
    }
}

internal class CustomerCache
{
    // ReSharper disable once CollectionNeverQueried.Local
    private readonly List<Customer> _cache = [];

    public void AddCustomer(Customer c)
    {
        _cache.Add(c);
    }
}

internal class Processor
{
    private readonly CustomerCache _cache = new();

    public void ProcessTransaction(Customer customer)
    {
        _cache.AddCustomer(customer);
    }
}