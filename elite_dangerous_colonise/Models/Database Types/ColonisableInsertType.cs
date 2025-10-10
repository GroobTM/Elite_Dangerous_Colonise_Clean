using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("ColonisableInsertType")]
    public class ColonisableInsertType
    {
        [PgName("colonisedSystemID")]
        public long ColonisedSystemID { get; set; }
        [PgName("uncolonisedSystemID")]
        public long UncolonisedSystemID { get; set; }

        public ColonisableInsertType() { }
        public ColonisableInsertType(long colonisedSystemID, long uncolonisedSystemID)
        {
            ColonisedSystemID = colonisedSystemID;
            UncolonisedSystemID = uncolonisedSystemID;
        }
    }
}
