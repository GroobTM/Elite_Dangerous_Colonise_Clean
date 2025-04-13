using Newtonsoft.Json;

namespace elite_dangerous_colonise.Models.Json_Structure
{
    /// <summary>
    /// Represents the Json structure of the ring's signal categories.
    /// </summary>
    public class SignalsCategoryJson
    {
        [JsonProperty("signals")]
        public required Dictionary<string, short> SignalTypes { get; set; }
    }
}
