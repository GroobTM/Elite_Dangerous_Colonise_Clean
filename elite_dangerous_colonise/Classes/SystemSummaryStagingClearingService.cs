using System.Data;
using Microsoft.AspNetCore.SignalR;
using Accord.Collections;
using elite_dangerous_colonise.Models.Database_Results;
using Npgsql;
using System.Text;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines a SystemSummaryStagingClearingService service.
    /// </summary>
    public class SystemSummaryStagingClearingService : BackgroundService
    {
        private const double COLONISATION_RANGE = 15;

        private readonly NpgsqlDataSource dataSource;
        private readonly SpanshDataDumpDownloadService spanshService;
        private readonly IHubContext<UpdateHub> hubContext;

        /// <summary>
        /// Creates a SystemSummaryStagingClearingService object.
        /// </summary>
        public SystemSummaryStagingClearingService(NpgsqlDataSource dataSource, SpanshDataDumpDownloadService spanshService,
            IHubContext<UpdateHub> hubContext)
        {
            this.dataSource = dataSource;
            this.spanshService = spanshService;
            this.hubContext = hubContext;
        }

        /// <summary>
        /// Gets all the staged systems from the database.
        /// </summary>
        /// <returns> A list of staged systems. </returns>
        private async Task<List<StarSystemStagingResult>> SelectSystemSummaryStaging(NpgsqlConnection conn)
        {
            List<StarSystemStagingResult> results = new List<StarSystemStagingResult>();

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM StarSystemStaging", conn))
            await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
            {
                while (await reader.ReadAsync())
                {
                    results.Add(new StarSystemStagingResult(
                        reader.GetInt64(0),
                        reader.GetBoolean(1),
                        reader.GetDecimal(2),
                        reader.GetDecimal(3),
                        reader.GetDecimal(4),
                        reader.GetString(5)
                    ));
                }
            }

            return results;
        }

        /// <summary>
        /// Gets all the colonised or uncolonised system summaries from the database.
        /// </summary>
        /// <param name="getColonised"> If the method should get colonised or uncolonised systems. </param>
        /// <returns> A list of system summaries. </returns>
        private async Task<List<GetSystemSummaryResult>> SelectSystemSummary(NpgsqlConnection conn, bool getColonised)
        {
            List<GetSystemSummaryResult> results = new List<GetSystemSummaryResult>();

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM GetSystemSummaryFunc(@getColonised)", conn))
            {
                command.Parameters.AddWithValue("getColonised", getColonised);

                await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                {
                    while (await reader.ReadAsync())
                    {
                        results.Add(new GetSystemSummaryResult(
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

        /// <summary>
        /// Removes the star system from StarSystemStaging.
        /// </summary>
        /// <param name="starSystem">The system to remove.</param>
        private async Task RemoveFromStaging(NpgsqlConnection conn, StarSystemStagingResult starSystem)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("DELETE FROM StarSystemStaging WHERE systemID = @systemID", conn))
            {
                command.Parameters.AddWithValue("systemID", starSystem.SystemID);

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Removes the star system's nearby ID records from NearbyStarSystems.
        /// </summary>
        /// <param name="starSystem">The system to remove the IDs of.</param>
        private async Task RemoveNearbyIDs(NpgsqlConnection conn, StarSystemStagingResult starSystem)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("DELETE FROM NearbyStarSystems WHERE nearbySystemID = @systemID", conn))
            {
                command.Parameters.AddWithValue("systemID", starSystem.SystemID);

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Removes the star system's nearby ID records from NearbyStarSystems.
        /// </summary>
        /// <param name="starSystem">The system to remove the bodies of.</param>
        private async Task RemoveOldBodies(NpgsqlConnection conn, StarSystemStagingResult starSystem)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("DELETE FROM Bodies WHERE systemID = @systemID", conn))
            {
                command.Parameters.AddWithValue("systemID", starSystem.SystemID);

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Inserts a batch of system combinations into the NearbyStarSystems tables.
        /// </summary>
        /// <param name="nearbySystems"> A list of system combinations to insert. </param>
        private async Task InsertNearbySystems(NpgsqlConnection conn, List<NearbyStarSystemsResult> nearbySystems)
        {
            StringBuilder sb = new StringBuilder("INSERT INTO NearbyStarSystems (colonisedSystemID, nearbySystemID) VALUES ");
            List<NpgsqlParameter> parameters = new List<NpgsqlParameter>();

            for (int i = 0; i < nearbySystems.Count; i++)
            {
                sb.Append($"(@colonisedSystemID_{i}, @nearbySystemID_{i})");

                if (i < nearbySystems.Count - 1)
                {
                    sb.Append(", ");
                }

                parameters.Add(new NpgsqlParameter($"colonisedSystemID_{i}", nearbySystems[i].ColonisedSystemID));
                parameters.Add(new NpgsqlParameter($"nearbySystemID_{i}", nearbySystems[i].NearbySystemID));
            }

            sb.Append(" ON CONFLICT (colonisedSystemID, nearbySystemID) DO NOTHING");

            await using (NpgsqlCommand command = new NpgsqlCommand(sb.ToString(), conn))
            {
                command.Parameters.AddRange(parameters.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Creates a KDTree for a list of systems.
        /// </summary>
        /// <param name="targetSystems"> A list of systems used to create the tree. </param>
        /// <returns> A Coordinate-ID dictionary and a KDTree. </returns>
        private (Dictionary<(double, double, double), Int64>, KDTree) CreateKDTree(List<GetSystemSummaryResult> targetSystems)
        {
            Dictionary<(double, double, double), Int64> coordinatesToSystemID = new Dictionary<(double, double, double), Int64>();

            KDTree kdTree = new KDTree(3);

            foreach (GetSystemSummaryResult targetSystem in targetSystems)
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

        /// <summary>
        /// Creates a list of system combinations for systems in range of the new system.
        /// </summary>
        /// <param name="sourceSystem"> The new system. </param>
        /// <param name="dictAndKDTree"> A coordinate-ID dictionary and a KDTree. </param>
        /// <returns> A list of nearby system combinations. </returns>
        private List<NearbyStarSystemsResult> CreateLinksForSystem(StarSystemStagingResult sourceSystem, (Dictionary<(double, double, double), Int64>, KDTree) dictAndKDTree)
        {
            List<NearbyStarSystemsResult> nearbyStarSystems = new List<NearbyStarSystemsResult>();

            (Dictionary<(double, double, double), Int64> targetSystemCoordsToIDs, KDTree targetSystemTree) = dictAndKDTree;

            double[] sourceCoordinates = new double[3]
            {
                (double)sourceSystem.CoordinateX,
                (double)sourceSystem.CoordinateY,
                (double)sourceSystem.CoordinateZ
            };

            List<NodeDistance<KDTreeNode>> nearestNodes = targetSystemTree.Nearest(sourceCoordinates, radius: COLONISATION_RANGE);

            foreach (NodeDistance<KDTreeNode> node in nearestNodes)
            {
                if (targetSystemCoordsToIDs.TryGetValue((node.Node.Position[0], node.Node.Position[1], node.Node.Position[2]), out Int64 targetID))
                {
                    if (sourceSystem.SystemID != targetID)
                    {
                        if (sourceSystem.IsColonised)
                        {
                            nearbyStarSystems.Add(new NearbyStarSystemsResult(sourceSystem.SystemID, targetID));
                        }
                        else
                        {
                            nearbyStarSystems.Add(new NearbyStarSystemsResult(targetID, sourceSystem.SystemID));
                        }
                    }
                }
            }

            return nearbyStarSystems;
        }

        /// <summary>
        /// Processes all the staged systems and moves them to the StarSystemSummary table and adds any links to the NearbyStarSystem table.
        /// </summary>
        private async Task ProcessStagedSystemSummaries(NpgsqlConnection conn)
        {
            List<StarSystemStagingResult> stagedSystems = await SelectSystemSummaryStaging(conn);

            if (stagedSystems.Any())
            {
                (Dictionary<(double, double, double), Int64> colonisedSystemCoordsToIDs, KDTree colonisedSystemTree) = CreateKDTree(await SelectSystemSummary(conn, true));
                (Dictionary<(double, double, double), Int64> uncolonisedSystemCoordsToIDs, KDTree uncolonisedSystemTree) = CreateKDTree(await SelectSystemSummary(conn, false));


                foreach (StarSystemStagingResult stagedSystem in stagedSystems)
                {
                    List<NearbyStarSystemsResult> nearbyStarSystems = new List<NearbyStarSystemsResult>();

                    if (stagedSystem.IsColonised)
                    {
                        nearbyStarSystems = CreateLinksForSystem(stagedSystem, (uncolonisedSystemCoordsToIDs, uncolonisedSystemTree));
                    }
                    else
                    {
                        nearbyStarSystems = CreateLinksForSystem(stagedSystem, (colonisedSystemCoordsToIDs, colonisedSystemTree));
                    }
                            
                    using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
                    {
                        try
                        {
                            await RemoveFromStaging(conn, stagedSystem);

                            if (stagedSystem.QueryType == "UPDATE")
                            {
                                await RemoveOldBodies(conn, stagedSystem);
                                await RemoveNearbyIDs(conn, stagedSystem);
                            }
                            else if (stagedSystem.QueryType != "INSERT")
                            {
                                throw new InvalidQueryTypeException($"System {stagedSystem.SystemID} has invalid QueryType {stagedSystem.QueryType}." +
                                    $"\r\nFurther staging processing blocked. Manual fix required in database.");
                            }

                            if (nearbyStarSystems.Count > 0)
                            {
                                await InsertNearbySystems(conn, nearbyStarSystems);
                            }

                            await transaction.CommitAsync();

                            Logger.LogInformation("System Summary Staging Clearing Service", 3, $"System {stagedSystem.SystemID} moved to StarSystemSummary.");

                            double[] coordinates = new double[3]
                            {
                                (double)stagedSystem.CoordinateX,
                                (double)stagedSystem.CoordinateY,
                                (double)stagedSystem.CoordinateZ
                            };

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
                        catch (InvalidQueryTypeException ex)
                        {
                            await transaction.RollbackAsync();
                            Logger.LogError("System Summary Staging Clearing Service", 5, ex);
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

        /// <summary>
        /// Calculates the values for the NearbyStarSystemValue table.
        /// </summary>
        /// <returns></returns>
        private async Task CalculateNearbyStarSystemValue(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 9, "Updating Systems values table.");

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT CalculateNearbyStarSystemsValuesFunc()", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task CalculateTrailblazerDistances(NpgsqlConnection conn)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 10, "Updating Trailblazers distance table.");

            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT CalculateTrailblazerDistancesFunc()", conn))
            {
                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RefreshValuesTables(NpgsqlConnection conn)
        {
            await using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
            {
                await CalculateNearbyStarSystemValue(conn);
                await CalculateTrailblazerDistances(conn);

                await transaction.CommitAsync();

                Logger.LogInformation("System Summary Staging Clearing Service", 11, "Update complete.");
            }
        }

        /// <summary>
        /// Runs the background service on event invoke.
        /// </summary>
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

        /// <summary>
        /// Starts the background service.
        /// </summary>
        protected override Task ExecuteAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("System Summary Staging Clearing Service", 0, "Staging Clearing Service starting.");

            spanshService.DataDumpProcessingComplete += (sender, e) => Task.Run(async () => await OnDataDumpProcessingComplete(sender, e));

            return Task.CompletedTask;
        }

        /// <summary>
        /// Stops the background service.
        /// </summary>
        /// <returns> A completed task. </returns>
        public override Task StopAsync(CancellationToken cancellationToken)
        { 
            spanshService.DataDumpProcessingComplete -= (sender, e) => Task.Run(async () => await OnDataDumpProcessingComplete(sender, e));

            Logger.LogInformation("System Summary Staging Clearing Service", 8, "Staging Clearing Service stopped.");

            return Task.CompletedTask;
        }

        /// <summary>
        /// Defines a InvalidQueryTypeException exception.
        /// </summary>
        private class InvalidQueryTypeException : Exception 
        {
            public InvalidQueryTypeException() : base() { }
            public InvalidQueryTypeException(string message) : base(message) { }
        }
    }
}
