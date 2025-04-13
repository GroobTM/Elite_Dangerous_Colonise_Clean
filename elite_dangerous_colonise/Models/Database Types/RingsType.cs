using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("ringstype")]
    public class RingsType
    {
        [PgName("ringid")]
        public int RingID { get; set; }
        [PgName("bodyid")]
        public long BodyID { get; set; }
        [PgName("ringname")]
        public string RingName { get; set; }
        [PgName("ringtype")]
        public string RingType { get; set; }

        public RingsType() { }
        public RingsType(int ringID, long bodyID, string ringName, string ringType)
        {
            RingID = ringID;
            BodyID = bodyID;
            RingName = ringName;
            RingType = ringType;
        }
    }
}
