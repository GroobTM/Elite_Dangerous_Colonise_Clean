using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("stationstype")]
    public class StationsType
    {
        [PgName("stationid")]
        public long StationID { get; set; }
        [PgName("systemid")]
        public long SystemID { get; set; }
        [PgName("stationname")]
        public string StationName {  get; set; }
        [PgName("controllingfaction")]
        public string ControllingFaction {  get; set; }

        public StationsType() { }
        public StationsType(long stationID, long systemID, string stationName, string controllingFaction)
        {
            StationID = stationID;
            SystemID = systemID;
            StationName = stationName;
            ControllingFaction = controllingFaction;
        }
    }
}
