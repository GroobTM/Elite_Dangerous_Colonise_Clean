using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("StationInsertType")]
    public class StationInsertType
    {
        [PgName("stationID")]
        public decimal StationID { get; set; }
        [PgName("systemID")]
        public long SystemID { get; set; }
        [PgName("stationName")]
        public string StationName {  get; set; }
        [PgName("controllingFaction")]
        public string ControllingFaction {  get; set; }

        public StationInsertType() { }
        public StationInsertType(ulong stationID, long systemID, string stationName, string controllingFaction)
        {
            StationID = stationID;
            SystemID = systemID;
            StationName = stationName;
            ControllingFaction = controllingFaction;
        }
    }
}
