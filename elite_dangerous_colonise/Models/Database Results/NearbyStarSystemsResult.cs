namespace elite_dangerous_colonise.Models.Database_Results
{
    public class NearbyStarSystemsResult
    {
        public Int64 ColonisedSystemID { get; set; }
        public Int64 NearbySystemID { get; set; }

        public NearbyStarSystemsResult(Int64 colonisedSystemID, Int64 nearbySystemID)
        {
            ColonisedSystemID = colonisedSystemID;
            NearbySystemID = nearbySystemID;
        }
    }
}
