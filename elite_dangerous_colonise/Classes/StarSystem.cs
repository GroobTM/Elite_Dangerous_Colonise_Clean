using System.Data;
using System.Numerics;
using elite_dangerous_colonise.Models.Database_Types;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Represents a star system. 
    /// </summary>
    public class StarSystem
    {
        /// <summary> The system's Spansh ID. </summary>
        public Int64 SystemID { get; private set; }
        /// <summary> The system's name. </summary>
        public string? Name { get; private set; }
        /// <summary> If the system is colonised. </summary>
        public bool IsColonised { get; private set; }
        /// <summary> The date the system was last marked as colonising. </summary>
        public DateTime? ColonisingDate { get; private set; }
        /// <summary> The system's Coordinates. </summary>
        public Vector3 Coordinates { get; private set; }
        /// <summary> The bodies in the system. </summary>
        public List<Body>? Bodies { get; private set; }
        /// <summary> The orbital stations in the system. </summary>
        public List<Station>? Stations { get; private set; } 

        /// <summary>
        /// Creates a system.
        /// </summary>
        /// <param name="systemID"> The system's Spansh ID. </param>
        /// <param name="coordinates"> The system's coordinates. </param>
        public StarSystem(Int64 systemID, Vector3 coordinates)
        {
            SystemID = systemID;
            Coordinates = coordinates;
        }
        /// <inheritdoc cref="StarSystem.StarSystem(Int64, Vector3)"/>
        /// <param name="name"> The name of the system. </param>
        /// <param name="isColonised"> If the system is colonised. </param>
        /// <param name="bodies"> The bodies in the system. </param>
        public StarSystem(Int64 systemID, string name, bool isColonised, Vector3 coordinates, List<Body> bodies)
            :this(systemID, coordinates)
        {
            Name = name;
            IsColonised = isColonised;
            Bodies = bodies;
        }
        /// <inheritdoc cref="StarSystem.StarSystem(Int64, string, bool, Vector3, List{Body})"/>
        /// <param name="stations"> The list of the system's stations. </param>
        public StarSystem(Int64 systemID, string name, bool isColonised, Vector3 coordinates, List<Body> bodies,
            List<Station>? stations) :
            this(systemID, name, isColonised, coordinates, bodies)
        {
            Stations = stations;
        }
        /// <inheritdoc cref="StarSystem.StarSystem(Int64, string, bool, Vector3, List{Body})"/>
        /// <param name="colonisingDate"> The date the system was last marked as being colonised. </param>
        public StarSystem(Int64 systemID, string name, bool isColonised, DateTime? colonisingDate,
            Vector3 coordinates, List<Body> bodies) :
            this(systemID, name, isColonised, coordinates, bodies)
        {
            ColonisingDate = colonisingDate;
        }
        /// <inheritdoc cref="StarSystem.StarSystem(Int64, string, bool, Vector3, List{Body}, List{Station})"/>
        /// <param name="colonisingDate"> The date the system was last marked as being colonised. </param>
        public StarSystem(Int64 systemID, string name, bool isColonised, DateTime? colonisingDate,
            Vector3 coordinates, List<Body> bodies, List<Station>? stations) :
            this(systemID, name, isColonised, coordinates, bodies, stations)
        {
            ColonisingDate = colonisingDate;
        }

        /// <summary>
        /// Adds the System to the Systems List.
        /// </summary>
        private void AddSystemToDataList(DatabaseDataLists dataLists)
        {
            dataLists.StarSystems.Add(new StarSystemsType(SystemID, Name, ColonisingDate, IsColonised,
                (decimal)Coordinates.X, (decimal)Coordinates.Y, (decimal)Coordinates.Z));
        }

        /// <summary>
        /// Adds the System's Bodies and their components to their Lists.
        /// </summary>
        private void AddBodiesToDataList(DatabaseDataLists dataLists)
        {
            if (Bodies != null)
            {
                foreach (Body body in Bodies)
                {
                    body.AddToDataLists(dataLists, SystemID);
                }
            }
        }

        /// <summary>
        /// Adds the System's Stations to the Station List.
        /// </summary>
        private void AddStationsToDataList(DatabaseDataLists dataLists)
        {
            if (Stations != null)
            {
                foreach (Station station in Stations)
                {
                    station.AddToDataList(dataLists, SystemID);
                }
            }
        }

        /// <summary>
        /// Adds the System and its Bodies and Stations to their Lists.
        /// </summary>
        public void AddToDataLists(DatabaseDataLists dataLists)
        {
            AddSystemToDataList(dataLists);

            if (IsColonised)
            {
                AddStationsToDataList(dataLists);
            }
            else
            {
                AddBodiesToDataList(dataLists);
            }
        }
    }
}
