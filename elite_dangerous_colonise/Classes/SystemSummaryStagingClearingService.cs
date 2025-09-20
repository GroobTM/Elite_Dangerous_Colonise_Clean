using Accord.Collections;
using elite_dangerous_colonise.Models.Database_Results;
using elite_dangerous_colonise.Models.Database_Types;
using Microsoft.AspNetCore.SignalR;
using Npgsql;

namespace elite_dangerous_colonise.Classes
{
    /// <summary> Defines a SystemSummaryStagingClearingService service. </summary>
    public class SystemSummaryStagingClearingService : BackgroundService
    {
        private const double COLONISATION_RANGE = 15;

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

        private async Task<List<StarSystemStagingResult>> SelectSystemSummaryStaging(NpgsqlConnection conn)
        {
            List<StarSystemStagingResult> results = new List<StarSystemStagingResult>();

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM \"SelectStagedStarSystems\"()", conn))
            await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    results.Add(new StarSystemStagingResult(
                        reader.GetInt64(0),
                        reader.GetBoolean(1),
                        reader.GetDecimal(2),
                        reader.GetDecimal(3),
                        reader.GetDecimal(4)
                    ));
                }
            }

            return results;
        }

        private async Task<List<SelectStagedStarSystemsResult>> SelectSystemSummary(NpgsqlConnection conn, bool getColonised)
        {
            List<SelectStagedStarSystemsResult> results = new List<SelectStagedStarSystemsResult>();

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM \"SelectStarSystems\"(@getColonised)", conn))
            {
                command.Parameters.AddWithValue("getColonised", getColonised);

                await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        results.Add(new SelectStagedStarSystemsResult(
                            reader.GetInt64(0),
                            reader.GetDecimal(1),
                            reader.GetDecimal(2),
                            reader.GetDecimal(3)
                        ));
                    }
                }
            }

            return results;
        }

        private async Task RemoveStagedStarSystems(NpgsqlConnection conn, StarSystemStagingResult starSystem)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("DELETE FROM \"StagedStarSystems\" WHERE \"systemID\" = @systemID", conn))
            {
                command.Parameters.AddWithValue("systemID", starSystem.SystemID);

                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task InsertNearbySystems(NpgsqlConnection conn, List<ColonisableInsertType> colonisableStarSystems)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT \"InsertColonisableStarSystemsBulk\"(@inputColonisables)", conn))
            {
                command.Parameters.AddWithValue("inputColonisables", colonisableStarSystems.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }
        
        private (Dictionary<(double, double, double), long>, KDTree) CreateKDTree(List<SelectStagedStarSystemsResult> targetSystems)
        {
            Dictionary<(double, double, double), long> coordinatesToSystemID = new Dictionary<(double, double, double), long>();

            KDTree kdTree = new KDTree(3);

            foreach (SelectStagedStarSystemsResult targetSystem in targetSystems)
            {
                double[] coordinates = new double[3]
                {
                    (double)targetSystem.CoordinateX,
                    (double)targetSystem.CoordinateY,
                    (double)targetSystem.CoordinateZ
                };

                coordinatesToSystemID[(coordinates[0], coordinates[1], coordinates[2])] = targetSystem.SystemID;

                kdTree.Add(coordinates);
            }

            return (coordinatesToSystemID, kdTree);
        }

        private List<ColonisableInsertType> CreateLinksForSystem(StarSystemStagingResult sourceSystem, (Dictionary<(double, double, double), long>, KDTree) dictAndKDTree)
        {
            List<ColonisableInsertType> colonisableStarSystems = new List<ColonisableInsertType>();

            (Dictionary<(double, double, double), long> targetSystemCoordsToIDs, KDTree targetSystemTree) = dictAndKDTree;

            double[] sourceCoordinates = sourceSystem.GetCoordinateList();

            List<NodeDistance<KDTreeNode>> nearestNodes = targetSystemTree.Nearest(sourceCoordinates, radius: COLONISATION_RANGE);

            foreach (NodeDistance<KDTreeNode> node in nearestNodes)
            {
                if (targetSystemCoordsToIDs.TryGetValue((node.Node.Position[0], node.Node.Position[1], node.Node.Position[2]), out long targetID))
                {
                    if (sourceSystem.SystemID != targetID)
                    {
                        if (sourceSystem.IsColonised)
                        {
                            colonisableStarSystems.Add(new ColonisableInsertType(sourceSystem.SystemID, targetID));
                        }
                        else
                        {
                            colonisableStarSystems.Add(new ColonisableInsertType(targetID, sourceSystem.SystemID));
                        }
                    }
                }
            }

            return colonisableStarSystems;
        }

        private async Task ProcessStagedSystemSummaries(NpgsqlConnection conn)
        {
            List<StarSystemStagingResult> stagedSystems = await SelectSystemSummaryStaging(conn);

            if (stagedSystems.Any())
            {
                (Dictionary<(double, double, double), long> colonisedSystemCoordsToIDs, KDTree colonisedSystemTree) = CreateKDTree(await SelectSystemSummary(conn, true));
                (Dictionary<(double, double, double), long> uncolonisedSystemCoordsToIDs, KDTree uncolonisedSystemTree) = CreateKDTree(await SelectSystemSummary(conn, false));


                foreach (StarSystemStagingResult stagedSystem in stagedSystems)
                {
                    List<ColonisableInsertType> colonisableStarSystems = new List<ColonisableInsertType>();

                    if (stagedSystem.IsColonised)
                    {
                        colonisableStarSystems = CreateLinksForSystem(stagedSystem, (uncolonisedSystemCoordsToIDs, uncolonisedSystemTree));
                    }
                    else
                    {
                        colonisableStarSystems = CreateLinksForSystem(stagedSystem, (colonisedSystemCoordsToIDs, colonisedSystemTree));
                    }
                            
                    using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
                    {
                        try
                        {
                            await RemoveStagedStarSystems(conn, stagedSystem);

                            if (colonisableStarSystems.Count > 0)
                            {
                                await InsertNearbySystems(conn, colonisableStarSystems);
                            }

                            await transaction.CommitAsync();

                            Logger.LogInformation("System Summary Staging Clearing Service", 3, $"System {stagedSystem.SystemID} moved to ColonisableStarSystems.");

                            double[] coordinates = stagedSystem.GetCoordinateList();

                            if (stagedSystem.IsColonised)
                            {
                                colonisedSystemCoordsToIDs[(coordinates[0], coordinates[1], coordinates[2])] = stagedSystem.SystemID;

                                colonisedSystemTree.Add(coordinates);
                            }
                            else
                            {
                                uncolonisedSystemCoordsToIDs[(coordinates[0], coordinates[1], coordinates[2])] = stagedSystem.SystemID;

                                uncolonisedSystemTree.Add(coordinates);
                            }
                        }
                        catch (NpgsqlException ex)
                        {
                            await transaction.RollbackAsync();
                            Logger.LogError("System Summary Staging Clearing Service", 6, ex);
                        }
                    }
                }

                Logger.LogInformation("System Summary Staging Clearing Service", 4, "Processing Complete.");
            }
            else
            {
                Logger.LogInformation("System Summary Staging Clearing Service", 2, "No staged systems. Skipping processing.");
            }

        }

        private async Task CalculateTrailblazerDistances(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 10, "Updating Trailblazers distance table.");

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT InsertTrailblazerDistances()", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshValuesTables(NpgsqlConnection conn)
        {
            await using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
            {
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
