using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("hotspotstype")]
    public class HotspotsType
    {
        [PgName("ringid")]
        public int RingID { get; set; }
        [PgName("hotspottype")]
        public string HotspotType { get; set; }
        [PgName("hotspotcount")]
        public short HotspotCount { get; set; }

        public HotspotsType() { }
        public HotspotsType(int ringID, string hotspotType, short hotspotCount)
        {
            RingID = ringID;
            HotspotType = hotspotType;
            HotspotCount = hotspotCount;
        }
    }
}
