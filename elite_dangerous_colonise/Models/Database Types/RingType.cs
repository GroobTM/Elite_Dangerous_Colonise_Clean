using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("RingType")]
    public enum RingType
    {
        [PgName("Rocky")]
        Rocky,
        [PgName("MetalRich")]
        MetalRich,
        [PgName("Icy")]
        Icy,
        [PgName("Metallic")]
        Metallic
    }
}
