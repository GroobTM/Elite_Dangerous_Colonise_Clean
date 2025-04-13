using elite_dangerous_colonise.Models.Database_Types;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Represents a celestial body.
    /// </summary>
    public class Body
    {
        /// <summary> The body's Spansh ID. </summary>
        public Int64 BodyID { get; private set; }
        /// <summary> The body's name. </summary>
        public string Name { get; private set; }
        /// <summary> The body's type. </summary>
        public string BodyType { get; private set; }
        /// <summary> If the body is landable. </summary>
        public bool IsLandable { get; private set; }
        /// <summary> The body's reserve level. </summary>
        public string? ReserveLevel { get; private set; }
        /// <summary> The body's distance to the main star. </summary>
        public int DistanceToStar { get; private set; }
        /// <summary> The stations on the body. </summary>
        public List<Ring>? Rings { get; private set; }

        /// <summary>
        /// Creates a celestial body.
        /// </summary>
        /// <param name="bodyID"> The Spansh ID of the body. </param>
        /// <param name="name"> The name of the body. </param>
        /// <param name="bodyType"> The type of the body. </param>
        /// <param name="isLandable"> If the body is landable. </param>
        /// <param name="reserveLevel"> The reserve level of the body. </param>
        /// <param name="distanceToStar"> The body's distance to the main star. </param>
        public Body(Int64 bodyID, string name, string bodyType, bool isLandable, string reserveLevel,
            int distanceToStar)
        {
            BodyID = bodyID;
            Name = name;
            BodyType = bodyType;
            IsLandable = isLandable;
            ReserveLevel = reserveLevel;
            DistanceToStar = distanceToStar;
        }
        /// <inheritdoc cref="Body.Body(string, string, bool, string)"/>
        /// <param name="rings"> The body's rings. </param>
        public Body(Int64 bodyID, string name, string bodyType, bool isLandable, string reserveLevel,
            int distanceToStar, List<Ring> rings) :
            this(bodyID, name, bodyType, isLandable, reserveLevel, distanceToStar)
        {
            Rings = rings;
        }

        /// <summary>
        /// Adds the Body to the Bodies List.
        /// </summary>
        private void AddBodyToDataList(DatabaseDataLists dataLists, Int64 systemID)
        {
            dataLists.Bodies.Add(new BodiesType(BodyID, systemID, Name,
                BodyType != null ? BodyType : "None",
                IsLandable,
                ReserveLevel != null ? ReserveLevel : "None",
                DistanceToStar));
        }

        /// <summary>
        /// Adds the Body's Rings and their components to their Lists.
        /// </summary>
        private void AddRingsToDataList(DatabaseDataLists dataLists)
        {
            if (Rings != null)
            {
                foreach (Ring ring in Rings)
                {
                    ring.AddToDataLists(dataLists, BodyID);
                }
            }
        }

        /// <summary>
        /// Adds the Body and its Rings to their Lists.
        /// </summary>
        /// <param name="systemID"> The ID of the System the Body is in. </param>
        internal void AddToDataLists(DatabaseDataLists dataLists, Int64 systemID)
        {
            AddBodyToDataList(dataLists, systemID);
            AddRingsToDataList(dataLists);
        }
    }
}
