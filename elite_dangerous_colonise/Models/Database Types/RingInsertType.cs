using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("RingInsertType")]
    public class RingInsertType
    {
        [PgName("systemID")]
        public long SystemID { get; set; }
        [PgName("ringName")]
        public string RingName { get; set; }
        [PgName("ringType")]
        public RingType Type { get; set; }

        public RingInsertType() { }
        public RingInsertType(long systemID, string ringName, RingType ringType)
        {
            SystemID = systemID;
            RingName = ringName;
            Type = ringType;
        }
    }


}
