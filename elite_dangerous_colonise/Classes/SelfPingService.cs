namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines the SelfPingService background service.
    /// </summary>
    public class SelfPingService : BackgroundService
    {
        private readonly IHttpClientFactory httpClientFactory;

        /// <summary>
        /// Constructs a SelfPingService object.
        /// </summary>
        public SelfPingService(IHttpClientFactory httpClientFactory)
        {
            this.httpClientFactory = httpClientFactory;
        }

        /// <summary>
        /// Pings https://edcolonise.net/ every 10 minutes to keep it awake.
        /// </summary>
        protected override async Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("Self Ping Service", 0, "Self Ping Service starting.");


            while (!cancellationToken.IsCancellationRequested)
            {
                try
                {
                    using (HttpClient client = httpClientFactory.CreateClient())
                    {
                        HttpResponseMessage response = await client.GetAsync("https://edcolonise.net/", cancellationToken);
                        if (response.IsSuccessStatusCode)
                        {
                            Logger.LogInformation("Self Ping Service", 1, "Self ping was successful.");
                        }
                    }
                }
                catch (Exception ex)
                {
                    Logger.LogError("Self Ping Service", 2, "Self ping failed and caused an error.", ex);
                }

                await Task.Delay(TimeSpan.FromMinutes(10), cancellationToken);
            }

            Logger.LogInformation("Self Ping Service", 3, "Self Ping Service stopping.");
        }
    }
}
