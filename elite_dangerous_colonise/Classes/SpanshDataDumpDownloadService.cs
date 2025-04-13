using System.IO.Compression;
using Microsoft.AspNetCore.SignalR;
using Npgsql;


namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines a SpanshDataDumpDownloadService.
    /// </summary>
    public class SpanshDataDumpDownloadService : BackgroundService
    {
        private const string DOWNLOAD_URL = "https://downloads.spansh.co.uk/galaxy_1day.json.gz";
        
        private static readonly HttpClient client = new HttpClient();
        private static readonly string rootDir = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), @"..\"));
        private readonly string downloadPath = rootDir + @"\private\SpanshDataDump\galaxy_1day.json.gz";
        private readonly string decompressPath = rootDir + @"\private\SpanshDataDump\galaxy_1day.json";
        private readonly IServiceScopeFactory scopeFactory;
        private readonly IHubContext<UpdateHub> hubContext;

        public event EventHandler? DataDumpProcessingComplete;

        /// <summary>
        /// Creates a SpanshDataDumpDownloadService object.
        /// </summary>
        public SpanshDataDumpDownloadService(IServiceScopeFactory scopeFactory, IHubContext<UpdateHub> hubContext)
        {
            this.scopeFactory = scopeFactory;

            this.hubContext = hubContext;
        }

        /// <summary>
        /// Calculates the time between the current time and 5 am UTC.
        /// </summary>
        /// <returns> Time until 5 am UTC. </returns>
        private TimeSpan TimeUntilStart()
        {
            DateTime currentTime = DateTime.UtcNow;

            DateTime startTime = new DateTime(currentTime.Year, currentTime.Month, currentTime.Day,
                5, 0, 0, DateTimeKind.Utc);

            if (currentTime > startTime)
            {
                startTime = startTime.AddDays(1);
            }

            return startTime - currentTime;
        }

        /// <summary>
        /// Downloads the Spansh data dump.
        /// </summary>
        private async Task DownloadDataDump()
        {
            int maxAttempts = 3;
            int attemptDelay = 5;

            Logger.LogInformation("Spansh Download Service", 1, "Spansh data dump download starting.");

            string path = Path.GetDirectoryName(downloadPath);
            if (!Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }

            for (int attempt = 1; attempt <= maxAttempts; attempt++)
            {
                try
                {
                    using (HttpResponseMessage response = await client.GetAsync(DOWNLOAD_URL, HttpCompletionOption.ResponseHeadersRead))
                    {
                        response.EnsureSuccessStatusCode();

                        await using (Stream stream = await response.Content.ReadAsStreamAsync())
                        await using (FileStream fileStream = new FileStream(downloadPath, FileMode.Create, FileAccess.Write,
                            FileShare.None, bufferSize: 81920, useAsync: true))
                        {
                            await stream.CopyToAsync(fileStream);
                        }
                    }
                    Logger.LogInformation("Spansh Download Service", 3, "Spansh data dump download complete.");
                    return;
                }
                catch (HttpRequestException ex)
                {
                    if (attempt < maxAttempts)
                    {
                        Logger.LogError("Spansh Download Service", 2, $"Spansh data dump download attempt {attempt} failed.", ex);

                        await Task.Delay(TimeSpan.FromSeconds(attemptDelay));
                    }
                    else
                    {
                        throw;
                    }
                }
            }
        }

        /// <summary>
        /// Decompresses the downloaded Spansh data dump.
        /// </summary>
        private async Task DecompressDataDump()
        {
            Logger.LogInformation("Spansh Download Service", 4, "Spansh data dump decompression starting.");

            await using (FileStream compressedFileStream = new FileStream(downloadPath, FileMode.Open, FileAccess.Read,
                FileShare.None, bufferSize: 81920, useAsync: true))
            await using(GZipStream decompressionStream = new GZipStream(compressedFileStream, CompressionMode.Decompress))
            await using(FileStream decompressedFileStream = new FileStream(decompressPath, FileMode.Create, FileAccess.Write,
                FileShare.None, bufferSize: 81920, useAsync: true))
            {
                await decompressionStream.CopyToAsync(decompressedFileStream);
            }

            Logger.LogInformation("Spansh Download Service", 5, "Spansh data dump decompression complete.");
        }

        /// <summary>
        /// Inserts the decompressed Spansh data dump into the database.
        /// </summary>
        private async Task InsertDataDumpIntoDatabase()
        {
            Logger.LogInformation("Spansh Download Service", 6, "Spansh data dump database insertion starting.");

            await using (AsyncServiceScope scope = scopeFactory.CreateAsyncScope())
            {
                DatabaseBulkWriter dbWriter = scope.ServiceProvider.GetRequiredService<DatabaseBulkWriter>();
                await dbWriter.InsertJsonIntoDatabase(decompressPath);
            }

            Logger.LogInformation("Spansh Download Service", 7, "Spansh data dump database insertion complete.");
        }

        /// <summary>
        /// Deletes the downloaded Spansh data dump zip file and json file.
        /// </summary>
        private void DeleteDataDump()
        {
            Logger.LogInformation("Spansh Download Service", 8, "Spansh data dump file delete starting.");

            File.Delete(downloadPath);
            File.Delete(decompressPath);

            Logger.LogInformation("Spansh Download Service", 9, "Spansh data dump file delete complete.");
        }

        /// <summary>
        /// Downloads, decompresses, inserts, and deletes a Spansh data dump.
        /// </summary>
        private async Task DownloadAndProcessDataDump()
        {
            try
            {
                UpdateHub.StartUpdate();
                await hubContext.Clients.All.SendAsync("SystemUpdateStarted");

                await DownloadDataDump();
                await DecompressDataDump();
                await InsertDataDumpIntoDatabase();

                DataDumpProcessingComplete?.Invoke(this, EventArgs.Empty);
            }
            catch (Exception ex)
            {
                Logger.LogError("Spansh Download Service", 10, "Spansh data dump download and processing failed.", ex);
            }
            finally
            {
                DeleteDataDump();
            }
        }

        /// <summary>
        /// Starts the background service and sets it to run once a day at 5 am UTC.
        /// </summary>
        protected override async Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("Spansh Download Service", 0, "Spansh data dump download service started.");

            var startDelay = TimeUntilStart();

            await Task.Delay(startDelay, cancellationToken);

            while (!cancellationToken.IsCancellationRequested)
            {
                await DownloadAndProcessDataDump();

                await Task.Delay(TimeSpan.FromDays(1), cancellationToken);
            }
        }

        /// <summary>
        /// Stops the background service.
        /// </summary>
        /// <returns> A completed task. </returns>
        public override Task StopAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("Spansh Download Service", 11, "Spansh data dump download service stopped.");

            return Task.CompletedTask;
        }
    }
}
