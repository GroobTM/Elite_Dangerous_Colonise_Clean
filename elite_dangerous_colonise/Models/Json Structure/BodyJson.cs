using Newtonsoft.Json;
using elite_dangerous_colonise.Classes;

namespace elite_dangerous_colonise.Models.Json_Structure
{
    /// <summary>
    /// Represents the Json structure of the system's bodies.
    /// </summary>
    public class BodyJson
    {

        [JsonProperty("id64")]
        public required Int64 BodyID { get; set; }
        [JsonProperty("name")]
        public required string Name { get; set; }
        [JsonProperty("subType")]
        public required string BodyType { get; set; }
        [JsonProperty("isLandable")]
        public bool IsLandable { get; set; } = false;
        [JsonProperty("reserveLevel")]
        public string? ReserveLevel { get; set; }
        [JsonProperty("distanceToArrival")]
        public required float DistanceToArrival { get; set; }
        [JsonProperty("gravity")]
        public float? Gravity { get; set; }
        [JsonProperty("surfaceTemperature")]
        public float? SurfaceTemparature { get; set; }
        [JsonProperty("rings")]
        public List<RingJson>? Rings { get; set; }
        [JsonProperty("stations")]
        public List<StationJson>? Stations { get; set; }
        [JsonProperty("signals")]
        public SignalsCategoryJson? SignalCategory { get; set; }

        public bool IsDisembarkable()
        {
            bool isDisembarkable = IsLandable;

            if (Gravity != null && Gravity >= 2.7f)
            {
                isDisembarkable &= false;
            }

            if (SurfaceTemparature != null && SurfaceTemparature >= 800)
            {
                isDisembarkable &= false;
            }

            return isDisembarkable;
        }


        /// <summary>
        /// Converts the RingJson object list into a Ring object list.
        /// </summary>
        /// <returns> A Ring object list with the same values as this objects' list. </returns>
        private List<Ring>? ConvertToRingList()
        {
            List<Ring>? ringList = Rings != null ? new List<Ring>() : null;

            if (Rings != null && Rings.Count > 0)
            {
                foreach (RingJson ring in Rings)
                {
                    ringList.Add(ring.ConvertToRing());
                }
            }

            return ringList;
        }

        /// <summary>
        /// Converts the BodyJson object into a Body object.
        /// </summary>
        /// <returns> A Body object with the same values as this objects. </returns>
        internal Body ConvertToBody()
        {
            return new Body(BodyID, Name, BodyType, IsDisembarkable(), ReserveLevel, (int)Math.Round(DistanceToArrival),
                ConvertToRingList());
        }
    }
}
