using NpgsqlTypes;

namespace elite_dangerous_colonise.Models.Database_Types
{
    [PgName("starsystemstype")]
    public class StarSystemsType
    {
        [PgName("systemid")]
        public long SystemID { get; set; }
        [PgName("systemname")]
        public string SystemName { get; set; }
        [PgName("lastcolonisingupdate")]
        public DateTime? LastColonisingDate { get; set; }
        [PgName("iscolonised")]
        public bool IsColonised { get; set; }
        [PgName("coordinatex")]
        public decimal CoordinateX { get; set; }
        [PgName("coordinatey")]
        public decimal CoordinateY { get; set; }
        [PgName("coordinatez")]
        public decimal CoordinateZ { get; set; }

        public StarSystemsType() { }
        public StarSystemsType(long systemID, string systemName, DateTime? lastColonisingDate, bool isColonised, decimal coordinateX, decimal coordinateY, decimal coordinateZ)
        {
            SystemID = systemID;
            SystemName = systemName;
            LastColonisingDate = lastColonisingDate;
            IsColonised = isColonised;
            CoordinateX = coordinateX;
            CoordinateY = coordinateY;
            CoordinateZ = coordinateZ;
        }
    }
}
