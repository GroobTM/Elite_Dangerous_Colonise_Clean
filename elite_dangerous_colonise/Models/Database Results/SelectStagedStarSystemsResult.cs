namespace elite_dangerous_colonise.Models.Database_Results
{
    public class SelectStagedStarSystemsResult
    {
        public long SystemID { get; set; }
        public double CoordinateX { get; set; }
        public double CoordinateY { get; set; }
        public double CoordinateZ { get; set; }

        public SelectStagedStarSystemsResult(long systemID, double coordinateX, double coordinateY,
            double coordinateZ)
        {
            SystemID = systemID;
            CoordinateX = coordinateX;
            CoordinateY = coordinateY;
            CoordinateZ = coordinateZ;
        }

        public double[] GetCoordinateList()
        {
            return
            [
                CoordinateX,
                CoordinateY,
                CoordinateZ
            ];
        }
    }
}
