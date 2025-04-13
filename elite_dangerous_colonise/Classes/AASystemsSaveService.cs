using Npgsql;
using elite_dangerous_colonise.Models.Database_Results;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines a AASystemsSaveService.
    /// </summary>
    public class AASystemsSaveService : BackgroundService
    {
        private readonly NpgsqlDataSource dataSource;

        private static readonly string rootDir = Path.GetFullPath(Path.Combine(Directory.GetCurrentDirectory(), @"..\"));
        private readonly string saveDir = rootDir + @"\extra\AASystemHistory\";

        /// <summary>
        /// Creates a AASystemsSaveService object.
        /// </summary>
        public AASystemsSaveService(NpgsqlDataSource dataSource)
        {
            this.dataSource = dataSource;
        }

        /// <summary>
        /// Calculates the time between the current time and 1 am UTC.
        /// </summary>
        /// <returns> Time until 1 am UTC. </returns>
        private TimeSpan TimeUntilStart()
        {
            DateTime currentTime = DateTime.UtcNow;

            DateTime startTime = new DateTime(currentTime.Year, currentTime.Month, currentTime.Day,
                1, 0, 0, DateTimeKind.Utc);

            if (currentTime > startTime)
            {
                startTime = startTime.AddDays(1);
            }

            return startTime - currentTime;
        }

        private async Task<List<AASystemResult>> GetAASystems()
        {
            List<AASystemResult> results = new List<AASystemResult>();

            await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
            {
                await using NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM GetAASystemsFunc()", conn);
                await using NpgsqlDataReader reader = await command.ExecuteReaderAsync();

                while (await reader.ReadAsync())
                {
                    results.Add(new AASystemResult(
                        reader.GetString(0),
                        reader.GetDecimal(1),
                        reader.GetDecimal(2),
                        reader.GetDecimal(3)
                    ));
                }
            }

            return results;
        }

        private async Task SaveAASystem()
        {
            try
            {
                List<AASystemResult> aaSystems = await GetAASystems();

                if (!Directory.Exists(saveDir))
                {
                    Directory.CreateDirectory(saveDir);
                }

                string fileName = $"AASystems{DateTime.UtcNow.ToString("yyyyMMdd")}.csv";
                string savePath = Path.Combine(saveDir, fileName);

                List<string> csvLines = new List<string>();

                if (aaSystems.Any())
                {
                    var first = aaSystems.First();
                    var properties = first.GetType().GetProperties();
                    csvLines.Add(string.Join(",", properties.Select(p => p.Name)));

                    foreach (var system in aaSystems)
                    {
                        var values = properties.Select(p => (p.GetValue(system) ?? "").ToString().Replace(",", " "));
                        csvLines.Add(string.Join(",", values));
                    }

                    await File.WriteAllLinesAsync(savePath, csvLines);
                    Logger.LogInformation("AA Systems Save Service", 1, $"Saved AA systems to {savePath}");
                }
            }
            catch (Exception ex)
            {
                Logger.LogError("AA Systems Save Service", 2, ex);
            }
        }

        /// <summary>
        /// Starts the background service and sets it to run once a day at 1 am UTC.
        /// </summary>
        protected override async Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("AA Systems Save Service", 0, "AA system save service started.");

            var startDelay = TimeUntilStart();

            await Task.Delay(startDelay, cancellationToken);

            while (!cancellationToken.IsCancellationRequested)
            {
                await SaveAASystem();

                await Task.Delay(TimeSpan.FromDays(1), cancellationToken);
            }
        }

        /// <summary>
        /// Stops the background service.
        /// </summary>
        /// <returns> A completed task. </returns>
        public override Task StopAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("AA Systems Save Service", 3, "AA system save service stopped.");

            return Task.CompletedTask;
        }
    }
}
