using Murmur;
using System.Text;
using elite_dangerous_colonise.Models.Database_Types;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Represents a rings.
    /// </summary>
    public class Ring
    {
        /// <summary> The ring's Spansh ID. </summary>
        public int RingID { get; private set; }
        /// <summary> The ring's name. </summary>
        public string Name { get; private set; }
        /// <summary> The ring's material type. </summary>
        public string RingType { get; private set; }
        /// <summary> The hotspots present on the ring. </summary>
        public Dictionary<string, short>? Hotspots { get; private set; }

        /// <summary>
        /// Creates a ring.
        /// </summary>
        /// <param name="name"> The name of the ring. </param>
        /// <param name="ringType"> The material type of the ring. </param>
        public Ring(string name, string ringType)
        {
            Name = name;
            RingType = ringType;

            RingID = BitConverter.ToInt32(
                MurmurHash.Create32().ComputeHash(Encoding.UTF8.GetBytes(Name)), 0);
        }
        /// <inheritdoc cref="Ring.Ring(string, string)"/>
        /// <param name="hotspots"> The hotspots present on the ring. </param>
        public Ring(string name, string ringType, Dictionary<string, short> hotspots) :
            this(name, ringType)
        {
            Hotspots = hotspots;
        }

        /// <summary>
        /// Adds the Ring to the Rings List.
        /// </summary>
        private void AddRingToDataList(DatabaseDataLists dataLists, Int64 bodyID)
        {
            dataLists.Rings.Add(new RingsType(RingID, bodyID, Name,
                RingType != null ? RingType : "None"));            
        }

        /// <summary>
        /// Adds the Hotspot to the Hotspots List.
        /// </summary>
        private void AddHotspotToDataList(DatabaseDataLists dataLists)
        {
            if (Hotspots != null)
            {
                foreach (KeyValuePair<string, short> hotspot in Hotspots)
                {
                    dataLists.Hotspots.Add(new HotspotsType(RingID,
                        hotspot.Key != null ? hotspot.Key : "None",
                        hotspot.Value));
                }
            }
        }

        /// <summary>
        /// Adds the Ring and its Hotspots values to their Lists.
        /// </summary>
        /// <param name="bodyID"> The ID of the Body the Ring surrounds. </param>
        internal void AddToDataLists(DatabaseDataLists dataLists, Int64 bodyID)
        {
            AddRingToDataList(dataLists, bodyID);
            AddHotspotToDataList(dataLists);
        }
    }
}
