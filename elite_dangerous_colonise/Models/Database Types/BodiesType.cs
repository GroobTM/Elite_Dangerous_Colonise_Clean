using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("bodiestype")]
    public class BodiesType
    {
        [PgName("bodyid")]
        public long BodyID { get; set; }
        [PgName("systemid")]
        public long SystemID { get; set; }
        [PgName("bodyname")]
        public string BodyName { get; set; }
        [PgName("bodytype")]
        public string BodyType { get; set; }
        [PgName("islandable")]
        public bool IsLandable { get; set; }
        [PgName("reservetype")]
        public string ReserveType { get; set; }
        [PgName("distancefromstar")]
        public int DistanceFromStar { get; set; }

        public BodiesType() { }
        public BodiesType(long bodyID, long systemID, string bodyName, string bodyType, bool isLandable, string reserveType, int distanceFromStar)
        {
            BodyID = bodyID;
            SystemID = systemID;
            BodyName = bodyName;
            BodyType = bodyType;
            IsLandable = isLandable;
            ReserveType = reserveType;
            DistanceFromStar = distanceFromStar;
        }
    }
}
