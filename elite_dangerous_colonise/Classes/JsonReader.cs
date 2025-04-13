using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using elite_dangerous_colonise.Models.Json_Structure;
using System.Numerics;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Represents a JsonReader.
    /// </summary>
    public class JsonReader
    {
        /// <summary> An array of invalid station types that can't be colonised from. </summary>
        private readonly string[] INVALID_STATIONS =
        {
            "Drake-Class Carrier",
            "Mega ship",
            "Settlement",
            "Planetary Construction Depot",
            "Space Construction Depot",
            null
        };

        /// <summary> Body types that are interesting. </summary>
        private readonly string[] INTERESTING_TYPES =
        {
            "Black Hole",
            "White Dwarf",
            "Neutron Star",
            "Ammonia world",
            "Water world",
            "Earth-like world"
        };

        /// <summary> The max distance from SOL that systems will be saved. </summary>
        private const int SOL_COLONY_RANGE = 1000;

        /// <summary> The system read from a Json file. </summary>
        private SystemJson deserializedSystem;

        /// <summary>
        /// Creates a JsonReader.
        /// </summary>
        /// <param name="jsonString"> A Spansh datadump system json string. </param>
        /// <exception cref="InvalidOperationException">
        /// The entered jsonString returned a null value when deserialized.
        /// </exception>
        public JsonReader(string jsonString)
        {
            deserializedSystem = JsonConvert.DeserializeObject<SystemJson>(jsonString)
                ?? throw new InvalidOperationException("Deserialized failed: The JSON structure may be invalid.");

            deserializedSystem.MergeSystemAndBodyStationLists();
        }

        /// <summary> Removes all bodies from a system that are uninteresting. </summary>
        /// <remarks> An interesting body is one that is a rare star, has rings, or is landable. </remarks>
        private void PruneUninterestingBodies()
        {
            deserializedSystem.Bodies.RemoveAll(body => !(body.BodyType != null 
                && INTERESTING_TYPES.Any(type => type.Contains(body.BodyType))
                || body.Rings != null || body.IsDisembarkable()));
            if (deserializedSystem.Bodies.Count == 0)
            {
                deserializedSystem.Bodies = null;
            }
        }

        /// <summary> Removes invalid stations from the system. </summary>
        private void PruneInvalidStations()
        {
            if (deserializedSystem.Stations != null && deserializedSystem.Stations.Count > 0)
            {
                deserializedSystem.Stations.RemoveAll(station => INVALID_STATIONS.Contains(station.StationType));

                if (deserializedSystem.Stations.Count == 0)
                {
                    deserializedSystem.Stations = null;
                }
            }
        }

        /// <summary> Prunes unnecessary elements from the object. </summary>
        public void PruneSystem()
        {
            PruneInvalidStations();
            PruneUninterestingBodies();
        }

        /// <summary> Checks if the system is colonised or has interesting bodies. </summary>
        /// <remarks> An interesting body is one that is a rare star, has rings, or is landable. </remarks>
        public bool IsInteresting()
        {
            return deserializedSystem.IsColonised()
                || ((deserializedSystem.Bodies != null && deserializedSystem.Bodies.Count > 0) && !deserializedSystem.HasInvalidSignals());
        }

        /// <summary>
        /// Gets the value of the read system as a System object.
        /// </summary>
        /// <returns> A system object. </returns>
        public StarSystem GetSystem()
        {
            return deserializedSystem.ConvertToSystem();
        }

        /// <summary>
        /// Checks if a set of coordinates in a json file are within colonisation range of Sol.
        /// </summary>
        /// <param name="readObject"> The read JObject. </param>
        /// <returns> If the coordinates are within colonisation range of Sol. </returns>
        public static bool InRangeOfSol(JObject readObject)
        {
            JToken coordinates = readObject["coords"];

            if (coordinates != null && coordinates["x"] != null && coordinates["y"] != null && coordinates["z"] != null)
            {
                return Math.Abs(coordinates["x"].Value<float>()) < SOL_COLONY_RANGE
                    && Math.Abs(coordinates["y"].Value<float>()) < SOL_COLONY_RANGE
                    && Math.Abs(coordinates["z"].Value<float>()) < SOL_COLONY_RANGE;
            }
            else
            {
                return false;
            }
        }

        /// <summary>
        /// Checks if a set of coordinates are within colonisation range of Sol.
        /// </summary>
        /// <param name="coordinates"> A set of coordinates. </param>
        /// <returns> If the coordinates are within colonisation range of Sol. </returns>
        public static bool InRangeOfSol(Vector3 coordinates)
        {
            return Math.Abs(coordinates.X) < SOL_COLONY_RANGE
                && Math.Abs(coordinates.Y) < SOL_COLONY_RANGE
                && Math.Abs(coordinates.Z) < SOL_COLONY_RANGE;
        }
    }
}
