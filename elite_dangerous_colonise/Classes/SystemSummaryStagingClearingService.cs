using Microsoft.AspNetCore.SignalR;
using Npgsql;

namespace elite_dangerous_colonise.Classes
{
    /// <summary> Defines a SystemSummaryStagingClearingService service. </summary>
    public class SystemSummaryStagingClearingService : BackgroundService
    {
        private readonly NpgsqlDataSource dataSource;
        private readonly SpanshDataDumpDownloadService spanshService;
        private readonly IHubContext<UpdateHub> hubContext;

        /// <summary> Instantiates a SystemSummaryStagingClearingService object. </summary>
        public SystemSummaryStagingClearingService(NpgsqlDataSource dataSource, SpanshDataDumpDownloadService spanshService,
            IHubContext<UpdateHub> hubContext)
        {
            this.dataSource = dataSource;
            this.spanshService = spanshService;
            this.hubContext = hubContext;
        }

        private async Task InsertColonisableStarSystemsFromStaged(NpgsqlConnection conn, bool insertColonised)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT \"InsertColonisableStarSystemsFromStaged\"(@insertColonised)", conn))
            {
                command.CommandTimeout = 180;
                command.Parameters.AddWithValue("insertColonised", insertColonised);
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task TruncateStagedStarSystems(NpgsqlConnection conn)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("TRUNCATE \"StagedStarSystems\"", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task ProcessStagedSystemSummaries(NpgsqlConnection conn)
        {
            using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
            {
                try
                {
                    await InsertColonisableStarSystemsFromStaged(conn, true);
                    Logger.LogInformation("System Summary Staging Clearing Service", 2, "Colonised staged systems added.");
                    await InsertColonisableStarSystemsFromStaged(conn, false);
                    Logger.LogInformation("System Summary Staging Clearing Service", 3, "Uncolonised staged systems added.");
                    await TruncateStagedStarSystems(conn);

                    await transaction.CommitAsync();

                    Logger.LogInformation("System Summary Staging Clearing Service", 4, "Processing Complete.");
                }
                catch (NpgsqlException ex)
                {
                    await transaction.RollbackAsync();
                    Logger.LogError("System Summary Staging Clearing Service", 6, ex);
                }
            }
        }
        private async Task CalculateTrailblazerDistances(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 10, "Updating Trailblazers distance table.");

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT \"InsertTrailblazerDistances\"()", conn))
            {
                command.CommandTimeout = 120;
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshDistinctColonisedStarSystems(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 9, "Refreshing DistinctColonisedStarSystems view.");

            await using (NpgsqlCommand command = new NpgsqlCommand("REFRESH MATERIALIZED VIEW \"DistinctColonisedStarSystems\"", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshDistinctUncolonisedStarSystems(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 9, "Refreshing DistinctUncolonisedStarSystems view.");

            await using (NpgsqlCommand command = new NpgsqlCommand("REFRESH MATERIALIZED VIEW \"DistinctUncolonisedStarSystems\"", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshClosestTrailblazerByStarSystem(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 9, "Refreshing ClosestTrailblazerByStarSystem view.");

            await using (NpgsqlCommand command = new NpgsqlCommand("REFRESH MATERIALIZED VIEW \"ClosestTrailblazerByStarSystem\"", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshValuesTables(NpgsqlConnection conn)
        {
            await using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
            {
                await RefreshDistinctColonisedStarSystems(conn);
                await RefreshDistinctUncolonisedStarSystems(conn);
                await RefreshClosestTrailblazerByStarSystem(conn);
                await CalculateTrailblazerDistances(conn);

                await transaction.CommitAsync();

                Logger.LogInformation("System Summary Staging Clearing Service", 11, "Update complete.");
            }
        }

        private async Task OnDataDumpProcessingComplete(object? sender, EventArgs e)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 1, "Running staged system processing.");
            try
            {
                await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
                {
                    await ProcessStagedSystemSummaries(conn);

                    UpdateHub.BlockSearch();
                    await hubContext.Clients.All.SendAsync("SearchBlockEnabled");

                    await RefreshValuesTables(conn);
                }
            }
            catch (Exception ex)
            {
                Logger.LogError("System Summary Staging Clearing Service", 7, ex);
            }
            finally
            {
                UpdateHub.EndUpdate();
                await hubContext.Clients.All.SendAsync("SystemUpdateComplete");
            }
        }

        protected override Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 0, "Staging Clearing Service starting.");

            spanshService.DataDumpProcessingComplete += (sender, e) => Task.Run(async () => await OnDataDumpProcessingComplete(sender, e));

            return Task.CompletedTask;
        }

        /// <summary> Stops the background service. </summary>
        /// <returns> A completed task. </returns>
        public override Task StopAsync(CancellationToken cancellationToken)
        { 
            spanshService.DataDumpProcessingComplete -= (sender, e) => Task.Run(async () => await OnDataDumpProcessingComplete(sender, e));

            Logger.LogInformation("System Summary Staging Clearing Service", 8, "Staging Clearing Service stopped.");

            return Task.CompletedTask;
        }
    }
}
