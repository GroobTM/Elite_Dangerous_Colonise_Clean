using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("ReserveType")]
    public enum ReserveType
    {
        None,
	    Major,
	    Common,
	    Low,
	    Depleted,
	    Pristine
    }
}
