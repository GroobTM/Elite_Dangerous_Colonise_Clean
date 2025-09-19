namespace elite_dangerous_colonise.Models.Database_Results
{
    public class NearbyStarSystemsResult
    {
        public long ColonisedSystemID { get; set; }
        public long NearbySystemID { get; set; }

        public NearbyStarSystemsResult(long colonisedSystemID, long nearbySystemID)
        {
            ColonisedSystemID = colonisedSystemID;
            NearbySystemID = nearbySystemID;
        }
    }
}
