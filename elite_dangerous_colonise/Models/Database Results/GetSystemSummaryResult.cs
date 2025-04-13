namespace elite_dangerous_colonise.Models.Database_Results
{
    public class GetSystemSummaryResult
    {
        public Int64 SystemID { get; set; }
        public decimal CoordinateX { get; set; }
        public decimal CoordinateY { get; set; }
        public decimal CoordinateZ { get; set; }

        public GetSystemSummaryResult(Int64 systemID, decimal coordinateX, decimal coordinateY,
            decimal coordinateZ)
        {
            SystemID = systemID;
            CoordinateX = coordinateX;
            CoordinateY = coordinateY;
            CoordinateZ = coordinateZ;
        }
    }
}
