namespace elite_dangerous_colonise.Models.Database_Results
{
    public class StarSystemStagingResult
    {
        public long SystemID { get; set; }
        public bool IsColonised { get; set; }
        public double CoordinateX { get; set; }
        public double CoordinateY { get; set; }
        public double CoordinateZ { get; set; }

        public StarSystemStagingResult(long systemID, bool isColonised, double coordinateX,
            double coordinateY, double coordinateZ)
        {
            SystemID = systemID;
            IsColonised = isColonised;
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