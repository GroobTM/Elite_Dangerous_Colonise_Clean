using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using elite_dangerous_colonise.Models.Json_Structure;
using System.Numerics;

namespace elite_dangerous_colonise.Classes
{
    /// <summary> Defines a JsonReader. </summary>
    public class JsonReader
    {      
        private const int SOL_COLONY_RANGE = 2000;
        private SystemJson deserializedSystem;

        /// <summary> Instantiates a JsonReader object. </summary>
        /// <param name="jsonString"> A Spansh datadump system json string. </param>
        /// <exception cref="InvalidOperationException"> The entered jsonString returned a null value when deserialized. </exception>
        public JsonReader(string jsonString)
        {
            deserializedSystem = JsonConvert.DeserializeObject<SystemJson>(jsonString)
                ?? throw new InvalidOperationException("Deserialized failed: The JSON structure may be invalid.");
        }

        /// <summary>  Gets the value of the read system as a StarSystem object. </summary>
        /// <returns> A system object. </returns>
        public StarSystem? GetStarSystem()
        {
            return deserializedSystem.ConvertToStarSystem();
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
