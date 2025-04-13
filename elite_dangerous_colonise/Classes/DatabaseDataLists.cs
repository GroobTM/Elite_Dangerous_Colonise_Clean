using elite_dangerous_colonise.Models.Database_Types;

namespace elite_dangerous_colonise.Classes
{
    public class DatabaseDataLists
    {
        public List<StarSystemsType> StarSystems { get; set; } = new List<StarSystemsType>();
        public List<StationsType> Stations { get; set; } = new List<StationsType>();
        public List<BodiesType> Bodies { get; set; } = new List<BodiesType>();
        public List<RingsType> Rings { get; set; } = new List<RingsType>();
        public List<HotspotsType> Hotspots { get; set; } = new List<HotspotsType>();

        public void ClearLists()
        {
            StarSystems.Clear();
            Stations.Clear();
            Bodies.Clear();
            Rings.Clear();
            Hotspots.Clear();
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
