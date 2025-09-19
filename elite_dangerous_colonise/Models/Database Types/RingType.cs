using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("RingType")]
    public enum RingType
    {
        Rocky,
        MetalRich,
        Icy,
        Metallic
    }
}
