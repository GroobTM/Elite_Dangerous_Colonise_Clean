using Newtonsoft.Json;
using elite_dangerous_colonise.Classes;

namespace elite_dangerous_colonise.Models.Json_Structure
{
    /// <summary>
    /// Represents the Json structure of the body's rings.
    /// </summary>
    public class RingJson
    {
        [JsonProperty("name")]
        public required string Name { get; set; }
        [JsonProperty("type")]
        public required string RingType { get; set; }
        [JsonProperty("signals")]
        public SignalsCategoryJson? SignalCategory { get; set; }

        /// <summary>
        /// Converts the RingJson object into a Ring object.
        /// </summary>
        /// <returns> A Ring object with the same values as this objects. </returns>
        internal Ring ConvertToRing()
        {
            if (SignalCategory != null)
            {
                return new Ring(Name, RingType, SignalCategory.SignalTypes);
            }
            else
            {
                return new Ring(Name, RingType);
            }
        }
    }
}
