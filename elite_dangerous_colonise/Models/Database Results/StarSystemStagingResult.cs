namespace elite_dangerous_colonise.Models.Database_Results
{
    public class StarSystemStagingResult
    {
        public long SystemID { get; set; }
        public bool IsColonised { get; set; }
        public decimal CoordinateX { get; set; }
        public decimal CoordinateY { get; set; }
        public decimal CoordinateZ { get; set; }

        public StarSystemStagingResult(long systemID, bool isColonised, decimal coordinateX,
            decimal coordinateY, decimal coordinateZ)
        {
            SystemID = systemID;
            IsColonised = isColonised;
            CoordinateX = coordinateX;
            CoordinateY = coordinateY;
            CoordinateZ = coordinateZ;
        }

        public double[] GetCoordinateList()
        {
            return new double[3]
            {
                (double)CoordinateX,
                (double)CoordinateY,
                (double)CoordinateZ
            };
        }
    }
}