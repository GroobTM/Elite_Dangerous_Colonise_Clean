using Newtonsoft.Json;
using elite_dangerous_colonise.Classes;

namespace elite_dangerous_colonise.Models.Json_Structure
{
    /// <summary>
    /// Represents the Json structure of a system.
    /// </summary>
    public class SystemJson
    {
        readonly string[] COLONISED_STATION_TYPES = new string[]
        {
            "Coriolis Starport",
            "Ocellus Starport",
            "Orbis Starport",
            "Outposts"
        };

        [JsonProperty("id64")]
        public required Int64 SystemID { get; set; }
        [JsonProperty("name")]
        public required string Name { get; set; }
        [JsonProperty("coords")]
        public required CoordinatesJson Coordinates { get; set; }
        [JsonProperty("government")]
        public string? Government { get; set; } = "None";
        [JsonProperty("bodies")]
        public required List<BodyJson> Bodies { get; set; }
        [JsonProperty("stations")]
        public List<StationJson>? Stations { get; set; }

        /// <summary>
        /// Checks if the system is colonised.
        /// </summary>
        /// <returns> If the system is colonised. </returns>
        internal bool IsColonised()
        {
            return (Government != null && Government != "None") 
                || (Stations != null && Stations.Any(station => COLONISED_STATION_TYPES.Contains(station.StationType)));
        }

        /// <summary>
        /// Checks if the system has invlid signals.
        /// </summary>
        /// <returns> If the system has invalid signals. </returns>
        internal bool HasInvalidSignals()
        {
            foreach (BodyJson body in Bodies)
            {
                if (body.SignalCategory?.SignalTypes != null)
                {
                    foreach (string key in body.SignalCategory.SignalTypes.Keys)
                    {
                        if (key == "$SAA_SignalType_Human;" || key == "$SAA_SignalType_Other;")
                        {
                            return true;
                        }
                    }
                }
            }

            return false;
        }

        /// <summary>
        /// If a construction ship is present in the system, gets its last update date.
        /// </summary>
        /// <returns> The date the systems construction ship was updated. </returns>
        private DateTime? LastColonisingDate()
        {
            if (!IsColonised() && Stations != null && Stations.Count() > 0)
            {
                foreach (StationJson station in Stations)
                {
                    if (station.Name == "System Colonisation Ship" || station.Name.ToLower().Contains("colonisationship"))
                    {
                        return station.LastUpdate.DateTime;
                    }
                }
            }

            return null;
        }

        /// <summary>
        /// Converts the BodyJson object list into a Body object list.
        /// </summary>
        /// <returns> A Body object list with the same values as this objects' list. </returns>
        private List<Body> ConvertToBodyList()
        {
            List<Body> bodyList = new List<Body>();

            if (Bodies != null)
            {
                foreach (BodyJson body in Bodies)
                {
                    bodyList.Add(body.ConvertToBody());
                }
            }

            return bodyList;
        }

        /// <summary> Merges the lists of StationJsons in Bodies into Stations. </summary>
        public void MergeSystemAndBodyStationLists()
        {
            foreach (BodyJson body in Bodies)
            {
                if (body.Stations != null && body.Stations.Count > 0)
                {
                    if (Stations == null)
                    {
                        Stations = new List<StationJson>();
                    }

                    Stations.AddRange(body.Stations);
                }
            }
        }

        /// <summary>
        /// Removes all mega ships from the System object's station list.
        /// </summary>
        private void RemoveMegaShips()
        {
            string[] colonyShipNames =
            {
                "$EXT_PANEL_ColonisationShip:#index=1;",
                "$EXT_PANEL_ColonisationShip; [inactive]",
                "System Colonisation Ship",
                "Stronghold Carrier"
            };

            if (Stations != null && Stations.Count() > 0)
            {
                Stations.RemoveAll(station => colonyShipNames.Contains(station.Name));

                if (Stations.Count() == 0)
                {
                    Stations = null;
                }
            }
        }

        /// <summary>
        /// Converts the SystemJson object into a System object.
        /// </summary>
        /// <returns> A System object with the same values as this objects. </returns>
        public StarSystem ConvertToSystem()
        {
            DateTime? lastColonisingDate = LastColonisingDate();
            RemoveMegaShips();

            return new StarSystem(SystemID, Name, IsColonised(),
                lastColonisingDate != null ? (DateTime)lastColonisingDate : null,
                Coordinates.ConvertToVector(), ConvertToBodyList(),
                StationJson.ConvertToStationList(Stations));
        }
    }
}
