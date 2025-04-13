using Serilog;

namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Class to facilitate easy logging in the correct format.
    /// </summary>
    public static class Logger
    {
        /// <summary>
        /// Creates a information log event.
        /// </summary>
        /// <param name="eventCategory"> The category of the event. </param>
        /// <param name="eventID"> The ID of the event. </param>
        /// <param name="eventMessage"> The message shown by the event. </param>
        public static void LogInformation(string eventCategory, int eventID, string eventMessage)
        {
            Log.ForContext("SourceContext", eventCategory)
                .Information("[{eventID}] " + eventMessage, eventID);
        }

        /// <summary>
        /// Creates an error log event.
        /// </summary>
        /// <param name="eventCategory"> The category of the event. </param>
        /// <param name="eventID"> The ID of the event. </param>
        /// <param name="exception"> The exception that triggered the event. </param>
        public static void LogError(string eventCategory, int eventID, Exception exception)
        {
            Log.ForContext("SourceContext", eventCategory)
                .Error(exception, "[{eventID}] An error occured:", eventID);
        }

        /// <inheritdoc cref="LogError(string, int, Exception)"/>
        /// <param name="eventMessage"> The message shown by the event. </param>
        public static void LogError(string eventCategory, int eventID, string eventMessage, Exception exception)
        {
            Log.ForContext("SourceContext", eventCategory)
                .Error(exception, "[{eventID}] " + eventMessage, eventID);
        }

        /// <summary>
        /// Creates a warning log event.
        /// </summary>
        /// <param name="eventCategory"> The category of the event. </param>
        /// <param name="eventID"> The ID of the event. </param>
        /// <param name="eventMessage"> The message shown by the event. </param>
        public static void LogWarning(string eventCategory, int eventID, string eventMessage)
        {
            Log.ForContext("SourceContext", eventCategory)
                .Warning("[{eventID}] " + eventMessage, eventID);
        }
    }
}
