using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("ReserveType")]
    public enum ReserveType
    {
        [PgName("None")]
        None,
        [PgName("Major")]
        Major,
        [PgName("Common")]
        Common,
        [PgName("Low")]
        Low,
        [PgName("Depleted")]
        Depleted,
        [PgName("Pristine")]
        Pristine
    }
}
