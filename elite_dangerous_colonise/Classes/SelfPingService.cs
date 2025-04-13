namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines the SelfPingService background service.
    /// </summary>
    public class SelfPingService : BackgroundService
    {
        private const int START_TIME = 0;
        private const int END_TIME = 7;

        private readonly IHttpClientFactory httpClientFactory;

        /// <summary>
        /// Constructs a SelfPingService object.
        /// </summary>
        public SelfPingService(IHttpClientFactory httpClientFactory)
        {
            this.httpClientFactory = httpClientFactory;
        }

        /// <summary>
        /// Calculates the time until the service is next due to start running.
        /// </summary>
        private TimeSpan TimeUntilStart()
        {
            DateTime currentTime = DateTime.UtcNow;

            DateTime startTime = new DateTime(currentTime.Year, currentTime.Month, currentTime.Day,
                START_TIME, 0, 0, DateTimeKind.Utc);

            if (currentTime > startTime)
            {
                startTime = startTime.AddDays(1);
            }

            return startTime - currentTime;
        }

        /// <summary>
        /// Pings https://edcolonise.net/ every 5 minutes between 4am and 7am to keep it awake.
        /// </summary>
        protected override async Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("Self Ping Service", 0, "Self Ping Service starting.");

            HttpClient client = httpClientFactory.CreateClient();

            TimeSpan startTime = new TimeSpan(START_TIME, 0, 0);
            TimeSpan endTime = new TimeSpan(END_TIME, 0, 0);

            while (!cancellationToken.IsCancellationRequested)
            {
                TimeSpan now = DateTime.Now.TimeOfDay;

                if (now >= startTime && now <= endTime)
                {
                    try
                    {
                        HttpResponseMessage response = await client.GetAsync("https://edcolonise.net/", cancellationToken);
                        if (response.IsSuccessStatusCode)
                        {
                            Logger.LogInformation("Self Ping Service", 1, "Self ping was successful.");
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.LogError("Self Ping Service", 2, "Self ping failed and caused an error.", ex);
                    }

                    await Task.Delay(TimeSpan.FromMinutes(5), cancellationToken);
                }
                else
                {
                    await Task.Delay(TimeUntilStart(), cancellationToken);
                }
            }

            Logger.LogInformation("Self Ping Service", 3, "Self Ping Service stopping.");
        }
    }
}
