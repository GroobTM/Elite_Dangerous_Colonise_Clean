using System.Text;
using System.Numerics;
using System.IO.Compression;
using System.Globalization;
using NetMQ.Sockets;
using NetMQ;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using System;
using NuGet.Packaging.Signing;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Defines a EDDNListeningService.
    /// </summary>
    public class EDDNListeningService : BackgroundService
    {
        private const string EDDN_ADDRESS = "tcp://eddn.edcd.io:9500";
        private const string JOURNAL_SCHEMA = "https://eddn.edcd.io/schemas/journal/1";

        private NpgsqlDataSource dataSource;
        private List<Task> colonyShipUpdates = new List<Task>();
        private List<Task> trailblazerUpdates = new List<Task>();

        /// <summary>
        /// Creates a EDDNListeningService object.
        /// </summary>
        public EDDNListeningService(NpgsqlDataSource dataSource)
        {
            this.dataSource = dataSource;
        }

        private bool IsJournalSchema(string schema)
        {
            return schema == JOURNAL_SCHEMA;
        }

        private bool IsDockedEvent(string messageEvent)
        {
            return messageEvent == "Docked";
        }

        private bool IsSystemColonisationShip(string messageStationName)
        {
            return messageStationName == "System Colonisation Ship" || messageStationName.ToLower().Contains("colonisationship");
        }

        private bool IsTrailblazerMegaship(string messageStationName)
        {
            return messageStationName.Contains("Trailblazer");
        }

        /// <summary>
        /// Decompresses the recieved message.
        /// </summary>
        /// <param name="compressedMessage"> The compressed message byte array. </param>
        /// <returns> The decompressed message string. </returns>
        private async Task<string> DecompressMessage(byte[] compressedMessage)
        {
            return await Task.Run(() =>
            {
                using (MemoryStream memoryStream = new MemoryStream(compressedMessage))
                using (ZLibStream decompressor = new ZLibStream(memoryStream, CompressionMode.Decompress))
                using (StreamReader streamReader = new StreamReader(decompressor, Encoding.UTF8))
                {
                    return streamReader.ReadToEnd();
                }
            });
        }

        private Vector3 ConvertJsonToVector(JToken token)
        {
            float[] coords = token["StarPos"].ToObject<float[]>();
            return new Vector3(coords[0], coords[1], coords[2]);
        }

        /// <summary>
        /// Sends a database update query to update the colonisation status of known systems.
        /// </summary>
        private async Task UpdateColonisingTracker(JToken message)
        {
            try
            {
                Vector3 coords = ConvertJsonToVector(message);

                if (JsonReader.InRangeOfSol(coords))
                {
                    if (Int64.TryParse(message["SystemAddress"].ToString(), out Int64 systemID)
                        && DateTime.TryParse(message["timestamp"].ToString(), null, DateTimeStyles.AdjustToUniversal, out DateTime timestamp))
                    {
                        await UpdateColonisationDatabase(systemID, timestamp);

                        Logger.LogInformation("EDDN Listening Service", 1, $"Updating system {systemID}.");
                    }
                        
                }
            }
            catch (Exception ex)
            {
                Logger.LogError("EDDN Listening Service", 2, "Error occured while trying to update a system.", ex);
            }
        }

        private async Task UpdateColonisationDatabase(Int64 systemID, DateTime timestamp)
        {
            await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
            {
                await using NpgsqlCommand command = new NpgsqlCommand("SELECT UpdateSystemColonisationStateFunc(@inputSystemID, @inputUpdateDate)", conn);
                
                command.Parameters.AddWithValue("inputSystemID", NpgsqlDbType.Bigint, systemID);
                command.Parameters.AddWithValue("inputUpdateDate", NpgsqlDbType.Timestamp, timestamp);

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Sends a database insert/update query to insert/update the position of the Trailblazer megaships.
        /// </summary>
        private async Task UpdateTrailblazer(JToken message)
        {
            Int64[] validStations =
            {
                129033207,
                129032951,
                129032695,
                129032183,
                129033463,
                129032439,
            };

            try
            {
                if (Int64.TryParse(message?["MarketID"].ToString(), out Int64 stationID) && validStations.Contains(stationID))
                {
                    Vector3 coords = ConvertJsonToVector(message);
                    string name = message["StationName"].ToString();

                    if (DateTime.TryParse(message["timestamp"].ToString(), null, DateTimeStyles.AdjustToUniversal, out DateTime timestamp))
                    {
                        await UpdateTrailblazerDatabase(stationID, name, coords, timestamp);

                        Logger.LogInformation("EDDN Listening Service", 8, $"Updating {name}.");
                    }                    
                }
            }
            catch (Exception ex)
            {
                Logger.LogError("EDDN Listening Service", 9, "Error occured while trying to update a Trailblazer megaship.", ex);
            }
        }

        private async Task UpdateTrailblazerDatabase(Int64 trailblazerID, string trailblazerName, Vector3 coordinates, DateTime timestamp)
        {
            await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
            {
                await using NpgsqlCommand command = new NpgsqlCommand(
                    "SELECT InsertTrailblazerMegashipFunc(@inputID, @inputName, @inputCoordinateX, @inputCoordinateY, @inputCoordinateZ, @inputUpdateDate)", conn);

                command.Parameters.AddWithValue("inputID", NpgsqlDbType.Bigint, trailblazerID);
                command.Parameters.AddWithValue("inputName", NpgsqlDbType.Varchar, trailblazerName);
                command.Parameters.AddWithValue("inputCoordinateX", NpgsqlDbType.Numeric, coordinates.X);
                command.Parameters.AddWithValue("inputCoordinateY", NpgsqlDbType.Numeric, coordinates.Y);
                command.Parameters.AddWithValue("inputCoordinateZ", NpgsqlDbType.Numeric, coordinates.Z);
                command.Parameters.AddWithValue("inputUpdateDate", NpgsqlDbType.Timestamp, timestamp);

                await command.ExecuteNonQueryAsync();
            }
        }

        private async Task RemoveClaim(JToken message)
        {
            try
            {
                Vector3 coords = ConvertJsonToVector(message);

                if (JsonReader.InRangeOfSol(coords))
                {
                    if (Int64.TryParse(message["SystemAddress"].ToString(), out Int64 systemID)
                        && DateTime.TryParse(message["timestamp"].ToString(), null, DateTimeStyles.AdjustToUniversal, out DateTime timestamp))
                    {
                        await RemoveClaimFromDatabase(systemID, timestamp);

                        Logger.LogInformation("EDDN Listening Service", 10, $"Removed claim from system {systemID}.");
                    }

                }
            }
            catch (Exception ex)
            {
                Logger.LogError("EDDN Listening Service", 11, "Error occured while trying to remove a claim from a system.", ex);
            }
        }

        private async Task RemoveClaimFromDatabase(Int64 systemID, DateTime timestamp)
        {
            await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
            {
                await using NpgsqlCommand command = new NpgsqlCommand("SELECT UnclaimSystemFunc(@inputSystemID, @inputUpdateDate)", conn);

                command.Parameters.AddWithValue("inputSystemID", NpgsqlDbType.Bigint, systemID);
                command.Parameters.AddWithValue("inputUpdateDate", NpgsqlDbType.Timestamp, timestamp);

                await command.ExecuteNonQueryAsync();
            }
        }

        /// <summary>
        /// Listens to the EDDN socket for journal events and updates the database with the colonisation status of systems.
        /// </summary>
        private async Task ListenToEDDN(CancellationToken cancellationToken)
        {
            using (SubscriberSocket subscriber = new SubscriberSocket())
            {
                subscriber.Connect(EDDN_ADDRESS);
                subscriber.Subscribe(string.Empty);

                Logger.LogInformation("EDDN Listening Service", 0, $"Connected to {EDDN_ADDRESS}, listening for messages.");

                while (!cancellationToken.IsCancellationRequested)
                {
                    colonyShipUpdates.RemoveAll(task => task.IsCompleted || task.IsFaulted || task.IsCanceled);
                    trailblazerUpdates.RemoveAll(task => task.IsCompleted || task.IsFaulted || task.IsCanceled);

                    try
                    {
                        JObject jsonContent = JObject.Parse(await DecompressMessage(subscriber.ReceiveFrameBytes()));

                        JToken message = jsonContent["message"];
                        string schema = jsonContent?["$schemaRef"]?.ToString();
                        string messageEvent = message?["event"]?.ToString();
                        string messageStationName = message?["StationName"]?.ToString();

                        //Logger.LogInformation("test", 100, message.ToString());
                        

                        if (IsJournalSchema(schema) && IsDockedEvent(messageEvent))
                        {
                            if (IsSystemColonisationShip(messageStationName))
                            {
                                Task task = Task.Run(async () => await UpdateColonisingTracker(message), cancellationToken);

                                colonyShipUpdates.Add(task);
                            }
                            else if (IsTrailblazerMegaship(messageStationName))
                            {
                                Task task = Task.Run(async () => await UpdateTrailblazer(message), cancellationToken);

                                trailblazerUpdates.Add(task);
                            }
                        }
                    }
                    catch (Exception ex)
                    {
                        Logger.LogError("EDDN Listening Service", 3, "Error occured while receiving or processing message.", ex);
                    }
                }
            }
        }

        /// <summary>
        /// Runs the ListenToEDDN method on a new thread.
        /// </summary>
        protected override async Task ExecuteAsync(CancellationToken cancellationToken)
        {
            await Task.Run(() => ListenToEDDN(cancellationToken), cancellationToken);
        }

        /// <summary>
        /// Waits for the background tasks to complete and then stops the background service.
        /// </summary>
        public override async Task StopAsync(CancellationToken cancellationToken)
        {
            Logger.LogInformation("EDDN Listening Service", 4, "Waiting for background tasks to complete.");

            try
            {
                using (CancellationTokenSource timeoutToken = new CancellationTokenSource(TimeSpan.FromMinutes(2)))
                {
                    await Task.WhenAll(colonyShipUpdates).WaitAsync(timeoutToken.Token);
                    Logger.LogInformation("EDDN Listening Service", 5, "All background tasks completed. Service shutting down.");
                }
            }
            catch (OperationCanceledException)
            {
                Logger.LogWarning("EDDN Listening Service", 6, "Background tasks took too long to complete. Forcing shutdown.");
            }
            catch (Exception ex)
            {
                Logger.LogError("EDDN Listening Service", 7, "An error occured while waiting for background tasks to complete.", ex);
            }
        }
    }
}
