using Newtonsoft.Json;
using elite_dangerous_colonise.Classes;

namespace elite_dangerous_colonise.Models.Json_Structure
{
    /// <summary>
    /// Represents the Json structure of the system's or body's stations.
    /// </summary>
    public class StationJson
    {
        [JsonProperty("id")]
        public required long StationID { get; set; }
        [JsonProperty("name")]
        public required string Name { get; set; }
        [JsonProperty("controllingFaction")]
        public required string Faction { get; set; }
        [JsonProperty("type")]
        public required string StationType { get; set; }
        [JsonProperty("updateTime")]
        public required DateTimeOffset LastUpdate { get; set; }

        /// <summary>
        /// Converts the StationJson object into a Station object.
        /// </summary>
        /// <returns> A Station object with the same values as this objects. </returns>
        internal Station ConvertToStation()
        {
            return new Station(StationID, Name, Faction);
        }

        /// <summary>
        /// Converts the StationJson object list into a Station object list.
        /// </summary>
        /// <returns> A Station object list with the same values as this objects' list. </returns>
        internal static List<Station>? ConvertToStationList(List<StationJson>? stations)
        {
            List<Station>? stationList = new List<Station>();

            if (stations != null && stations.Count > 0)
            {
                foreach (StationJson station in stations)
                {
                    stationList.Add(station.ConvertToStation());
                }
            }

            if (stationList.Count == 0)
            {
                stationList = null;
            }

            return stationList;
        }
    }
}
