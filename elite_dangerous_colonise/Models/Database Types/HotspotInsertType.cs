using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("HotspotInsertType")]
    public class HotspotInsertType
    {
        [PgName("systemID")]
        public long SystemID { get; set; }
        [PgName("ringName")]
        public string RingName { get; set; }
        [PgName("hotspotType")]
        public HotspotType Type { get; set; }
        [PgName("hotspotCount")]
        public short HotspotCount { get; set; }

        public HotspotInsertType() { }
        public HotspotInsertType(long systemID, string ringName, HotspotType hotspotType, short hotspotCount)
        {
            SystemID = systemID;
            RingName = ringName;
            Type = hotspotType;
            HotspotCount = hotspotCount;
        }
    }
}
