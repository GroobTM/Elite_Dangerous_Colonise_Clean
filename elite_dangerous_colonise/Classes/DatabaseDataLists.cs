using elite_dangerous_colonise.Models.Database_Types;

namespace elite_dangerous_colonise.Classes
{
    public class DatabaseDataLists
    {
        public List<StarSystemInsertType> StarSystems { get; set; } = new List<StarSystemInsertType>();
        public List<StationInsertType> Stations { get; set; } = new List<StationInsertType>();
        public List<RingInsertType> Rings { get; set; } = new List<RingInsertType>();
        public List<HotspotInsertType> Hotspots { get; set; } = new List<HotspotInsertType>();
        public List<UncolonisedDetailsInsertType> UncolonisedDetails { get; set; } = new List<UncolonisedDetailsInsertType>();

        public void ClearLists()
        {
            StarSystems.Clear();
            Stations.Clear();
            Rings.Clear();
            Hotspots.Clear();
            UncolonisedDetails.Clear();
        }

        public int Count()
        {
            return StarSystems.Count;
        }

        public List<string> GetNames()
        {
            return StarSystems.Select(value => value.SystemName).ToList();
        }
    }
}
