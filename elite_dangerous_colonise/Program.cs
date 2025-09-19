using Serilog;
using Serilog.Events;
using Microsoft.AspNetCore.DataProtection;
using Npgsql;
using elite_dangerous_colonise.Classes;
using elite_dangerous_colonise.Models.Database_Types;

const bool DEBUG = true;

var builder = WebApplication.CreateBuilder(args);

string rootDir = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), @"..\"));

builder.Configuration
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .AddJsonFile("appsettings.Development.json", optional: true, reloadOnChange: true)
    .AddJsonFile(rootDir + "\\private\\ConnectionStrings.json", optional: false, reloadOnChange: true);

// Adds the RazorPages service.
builder.Services.AddRazorPages();

// Adds the SignalR service.
builder.Services.AddSignalR();

// Configures the data protection service.
builder.Services.AddDataProtection()
    .PersistKeysToFileSystem(new DirectoryInfo(rootDir + @"\private\keys"))
    .ProtectKeysWithDpapi()
    .SetApplicationName("EDColonise");

// Configures Serilog.
Log.Logger = new LoggerConfiguration()
    .ReadFrom.Configuration(builder.Configuration)
    .WriteTo.File(rootDir + @"\logs\errorLog.txt",
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] ({SourceContext}) {Message:lj} (RequestId: {RequestId}) {NewLine}{Exception}",
        restrictedToMinimumLevel: LogEventLevel.Warning, rollingInterval: RollingInterval.Day)
    .WriteTo.File(rootDir + @"\logs\infoLog.txt",
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] ({SourceContext}) {Message:lj} {NewLine}{Exception}",
        restrictedToMinimumLevel: LogEventLevel.Information, rollingInterval: RollingInterval.Day)
    .CreateLogger();
builder.Host.UseSerilog();

// Configures database connection.
string connectionString = builder.Configuration.GetConnectionString("SystemsDatabase")
    ?? throw new InvalidOperationException("Connection string 'SystemsDatabase' not found.");

NpgsqlDataSourceBuilder dataSourceBuilder = new NpgsqlDataSourceBuilder(connectionString);
dataSourceBuilder.MapEnum<RingType>("RingType");
dataSourceBuilder.MapEnum<HotspotType>("HotspotType");
dataSourceBuilder.MapEnum<ReserveType>("ReserveType");
dataSourceBuilder.MapComposite<StarSystemInsertType>("StarSystemInsertType");
dataSourceBuilder.MapComposite<StationInsertType>("StationInsertType");
dataSourceBuilder.MapComposite<RingInsertType>("RingInsertType");
dataSourceBuilder.MapComposite<HotspotInsertType>("HotspotInsertType");
dataSourceBuilder.MapComposite<UncolonisedDetailsInsertType>("UncolonisedDetailsInsertType");
dataSourceBuilder.MapComposite<ColonisableInsertType>("ColonisableInsertType");

NpgsqlDataSource dataSource = dataSourceBuilder.Build();
builder.Services.AddSingleton(dataSource);

// Registers Classes
builder.Services.AddScoped<DatabaseBulkWriter>(provider =>
{
    return new DatabaseBulkWriter(dataSource, DEBUG);
});

if (!DEBUG)
{
    // Configures the Spansh download background service.
    builder.Services.AddSingleton<SpanshDataDumpDownloadService>();
    builder.Services.AddHostedService(provider => provider.GetRequiredService<SpanshDataDumpDownloadService>());

    // Configures the staging clearing background service.
    builder.Services.AddHostedService<SystemSummaryStagingClearingService>();

    // Configures the EDDN listening background service.
    builder.Services.AddHostedService<EDDNListeningService>();

    // Configures the self ping background service.
    builder.Services.AddHttpClient();
    builder.Services.AddHostedService<SelfPingService>();
}

var app = builder.Build();

// Configure the HTTP request pipeline.
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseStatusCodePagesWithReExecute("/Error", "?statusCode={0}");

    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();

app.UseRouting();

app.UseAuthorization();

app.MapRazorPages();

app.MapHub<UpdateHub>("/updateHub");

if (DEBUG)
{
    // Configures and runs Launcher.
    await Launcher.Main(app.Services);

    if (Launcher.Start)
    {
        app.Run();
    }
}
else
{
    app.Run();
}
