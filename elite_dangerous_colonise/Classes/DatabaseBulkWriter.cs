using Npgsql;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using NpgsqlTypes;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines a DatabaseBulkWriter.
    /// </summary>
    public class DatabaseBulkWriter
    {
        private const int BULK_SIZE = 2000;

        private readonly bool verboseReporting;
        private readonly NpgsqlDataSource dataSource;
        private int recordsRead = 0;
        private int recordsAddedOrUpdated = 0;
        private int recordsFailedToAdd = 0;


        /// <summary>
        /// Constructs a DatabaseBulkWriter.
        /// </summary>
        /// <param name="dataSource"> The database datasource. </param>
        public DatabaseBulkWriter(NpgsqlDataSource dataSource)
        {
            this.verboseReporting = true;
            this.dataSource = dataSource;
        }
        /// <inheritdoc cref="DatabaseBulkWriter.DatabaseBulkWriter(NpgsqlDataSource)"/>
        /// <param name="verboseReporting"> If the database writer should report its reading progress. </param>
        public DatabaseBulkWriter(NpgsqlDataSource dataSource, bool verboseReporting)
        {
            this.dataSource = dataSource;
            this.verboseReporting = verboseReporting;
        }

        /// <summary>
        /// Bulk inserts records into StarSystems and SystemCoords
        /// </summary>
        /// <param name="conn"> The database connection. </param>
        /// <param name="transaction"> The current transaction. </param>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        /// <returns></returns>
        private async Task InsertIntoStarSystemsBulk(NpgsqlConnection conn, NpgsqlTransaction transaction,
            DatabaseDataLists dataLists)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT InsertIntoStarSystemsBulkFunc(@inputStarSystems)", conn, transaction))
            {
                command.Parameters.AddWithValue("inputStarSystems", dataLists.StarSystems.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Bulk inserts records into Stations and Factions.
        /// </summary>
        /// <param name="conn"> The database connection. </param>
        /// <param name="transaction"> The current transaction. </param>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        /// <returns></returns>
        private async Task InsertIntoStationsBulk(NpgsqlConnection conn, NpgsqlTransaction transaction,
            DatabaseDataLists dataLists)
        {
            await using(NpgsqlCommand command = new NpgsqlCommand("SELECT InsertIntoStationsBulkFunc(@inputStations)", conn, transaction))
            {
                command.Parameters.AddWithValue("inputStations", dataLists.Stations.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Bulk inserts records into Bodies, BodyType, and ReserveType.
        /// </summary>
        /// <param name="conn"> The database connection. </param>
        /// <param name="transaction"> The current transaction. </param>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        /// <returns></returns>
        private async Task InsertIntoBodiesBulk(NpgsqlConnection conn, NpgsqlTransaction transaction,
            DatabaseDataLists dataLists)
        {
            await using(NpgsqlCommand command = new NpgsqlCommand("SELECT InsertIntoBodiesBulkFunc(@inputBodies)", conn, transaction))
            {
                command.Parameters.AddWithValue("inputBodies", dataLists.Bodies.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Bulk inserts records into Rings and RingType.
        /// </summary>
        /// <param name="conn"> The database connection. </param>
        /// <param name="transaction"> The current transaction. </param>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        /// <returns></returns>
        private async Task InsertIntoRingsBulk(NpgsqlConnection conn, NpgsqlTransaction transaction,
            DatabaseDataLists dataLists)
        {
            await using(NpgsqlCommand command = new NpgsqlCommand("SELECT InsertIntoRingsBulkFunc(@inputRings)", conn, transaction))
            {
                command.Parameters.AddWithValue("inputRings", dataLists.Rings.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Bulk inserts records into Hotspots and HotspotType.
        /// </summary>
        /// <param name="conn"> The database connection. </param>
        /// <param name="transaction"> The current transaction. </param>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        /// <returns></returns>
        private async Task InsertIntoHotspotsBulk(NpgsqlConnection conn, NpgsqlTransaction transaction,
            DatabaseDataLists dataLists)
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT InsertIntoHotspotsBulkFunc(@inputHotspots)", conn, transaction))
            {
                command.Parameters.AddWithValue("inputHotspots", dataLists.Hotspots.ToArray());

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Reports the systems added in the latest bulk.
        /// </summary>
        /// <param name="insertedNames"> A list of system names. </param>
        private async Task ReportInsert(List<string> insertedNames)
        {
            if (verboseReporting)
            {
                foreach (string name in insertedNames)
                {
                    await Task.Run(() => Logger.LogInformation("Database Writer", 4, $"System {name} was added to the database."));
                }
            }
        }

        /// <summary>
        /// Bulk inserts an entire DatabaseDataTables' data into the database.
        /// </summary>
        /// <param name="dataLists"> The DatabaseDataLists object. </param>
        private async Task<Task> BulkInsertIntoDatabase(DatabaseDataLists dataLists)
        {
            await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
            {
                await using (NpgsqlTransaction transaction = await conn.BeginTransactionAsync())
                {
                    try
                    {
                        await InsertIntoStarSystemsBulk(conn, transaction, dataLists);
                        await InsertIntoStationsBulk(conn, transaction, dataLists);
                        await InsertIntoBodiesBulk(conn, transaction, dataLists);
                        await InsertIntoRingsBulk(conn, transaction, dataLists);
                        await InsertIntoHotspotsBulk(conn, transaction, dataLists);

                        await transaction.CommitAsync();
                        recordsAddedOrUpdated += dataLists.Count();

                        return ReportInsert(dataLists.GetNames());
                    }
                    catch (NpgsqlException ex)
                    {
                        recordsFailedToAdd += dataLists.Count();
                        Logger.LogError("Database Writer", 5, ex);

                        try
                        {
                            await transaction.RollbackAsync();
                        }
                        catch (InvalidOperationException rollbackEx)
                        {
                            Logger.LogError("Database Writer", 6, rollbackEx);
                        }
                        
                    }
                }
                
            }
            return Task.CompletedTask;
        }

        /// <summary> Reports number of records read/added/failed. </summary>
        private async Task ReportReading(CancellationToken token)
        {
            DateTime startTime = DateTime.Now;

            try
            {
                while (!token.IsCancellationRequested)
                {
                    Logger.LogInformation("Database Writer", 100, $"Reading In Progress " +
                        $"| Records Read: {recordsRead} " +
                        $"({recordsRead / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min) " +
                        $"| Records Added: {recordsAddedOrUpdated} " +
                        $"({recordsAddedOrUpdated / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min) " +
                        $"| Records Failed to Add: {recordsFailedToAdd} " +
                        $"({recordsFailedToAdd / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min)");
                    await Task.Delay(TimeSpan.FromMinutes(1), token);
                }
            }
            catch (TaskCanceledException)
            {
                Logger.LogInformation("Database Writer", 101, $"Reading Complete " +
                    $"| Records Read: {recordsRead} " +
                    $"({recordsRead / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min) " +
                    $"| Records Added: {recordsAddedOrUpdated} " +
                    $"({recordsAddedOrUpdated / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min) " +
                    $"| Records Failed to Add: {recordsFailedToAdd} " +
                    $"({recordsFailedToAdd / Math.Max(1, DateTime.Now.Subtract(startTime).TotalMinutes)}/min)");
            }
        }

        /// <summary>
        /// Reads a Json file and inserts its data into the database.
        /// </summary>
        /// <param name="filePath"> The file path of a Json file. </param>
        /// <remarks> This method reports it's progress periodically. </remarks>
        public async Task InsertJsonIntoDatabase(string filePath)
        {
            try
            {
                using StreamReader streamReader = new StreamReader(filePath);
                using JsonTextReader jsonReader = new JsonTextReader(streamReader);

                CancellationTokenSource cancellationToken = new CancellationTokenSource();
                Task readingReportingTask = ReportReading(cancellationToken.Token);
                List<Task> insertReportingTask = new List<Task>();

                DatabaseDataLists dataLists = new DatabaseDataLists();

                while (await jsonReader.ReadAsync())
                {
                    if (jsonReader.TokenType == JsonToken.StartObject)
                    {
                        JObject obj = await JObject.LoadAsync(jsonReader);

                        if (Classes.JsonReader.InRangeOfSol(obj))
                        {
                            Classes.JsonReader readSystem = new Classes.JsonReader(obj.ToString());
                            readSystem.PruneSystem();

                            if (readSystem.IsInteresting())
                            {
                                readSystem.GetSystem().AddToDataLists(dataLists);
                            }

                            if (dataLists.Count() >= BULK_SIZE)
                            {
                                insertReportingTask.Add(await BulkInsertIntoDatabase(dataLists));
                                dataLists.ClearLists();
                            }
                        }
                        recordsRead++;
                    }
                }

                if (dataLists.Count() > 0)
                {
                    insertReportingTask.Add(await BulkInsertIntoDatabase(dataLists));
                }


                await Task.WhenAll(insertReportingTask);
                cancellationToken.Cancel();
                await readingReportingTask;

            }
            catch (JsonReaderException ex)
            {
                Logger.LogError("Database Writer", 0, ex);
            }
            catch (UnauthorizedAccessException ex)
            {
                Logger.LogError("Database Writer", 1, ex);
            }
            catch (Exception ex)
            {
                Logger.LogError("Database Writer", 2, ex);
            }
        }
    }
}
