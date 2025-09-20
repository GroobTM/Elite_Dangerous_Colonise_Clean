namespace elite_dangerous_colonise.Models.Database_Results
{
    public class SelectStagedStarSystemsResult
    {
        public long SystemID { get; set; }
        public decimal CoordinateX { get; set; }
        public decimal CoordinateY { get; set; }
        public decimal CoordinateZ { get; set; }

        public SelectStagedStarSystemsResult(long systemID, decimal coordinateX, decimal coordinateY,
            decimal coordinateZ)
        {
            SystemID = systemID;
            CoordinateX = coordinateX;
            CoordinateY = coordinateY;
            CoordinateZ = coordinateZ;
        }
    }
}
