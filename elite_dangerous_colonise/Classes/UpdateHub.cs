using Microsoft.AspNetCore.SignalR;

namespace elite_dangerous_colonise.Classes
{
    public class UpdateHub : Hub
    {
        public static bool isUpdateInProgress { get; private set; } = false;
        public static bool isSearchBlocked { get; private set; } = false;

        public override async Task OnConnectedAsync()
        {
            string updateStatus = isUpdateInProgress ? "inProgress" : "completed";
            string searchStatus = isSearchBlocked ? "blocked" : "clear";
            await Clients.Caller.SendAsync("SystemUpdateStatus", updateStatus, searchStatus);

            await base.OnConnectedAsync();
        }

        static public void StartUpdate()
        {
            isUpdateInProgress = true;
        }

        static public void BlockSearch()
        {
            isSearchBlocked = true;
        }

        static public void EndUpdate()
        {
            isSearchBlocked = false;
            isUpdateInProgress = false;
        }
    }
}
