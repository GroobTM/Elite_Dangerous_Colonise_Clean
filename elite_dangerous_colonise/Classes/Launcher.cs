namespace elite_dangerous_colonise.Classes
{
    /// <summary>
    /// Handles launching the application.
    /// </summary>
    public static class Launcher
    {
        /// <summary> If the application should be launched. </summary>
        public static bool Start { get; private set; } = false;
        private static string pickedOption;

        /// <summary> Displays the launcher menu.</summary>
        /// <remarks> Automatically launches the application after 30 seconds. </remarks>
        public async static Task Main(IServiceProvider serviceProvider)
        {
            LauncherHeader();
            LauncherOptionsSelections();
            await ParseSelection(serviceProvider);
        }

        private static void LauncherHeader()
        {
            Console.WriteLine("-----------------------Elite Dangerous Colonise-----------------------");
            Console.WriteLine("Launch Options:");
            Console.WriteLine("1 (Default). Launch Elite Dangerous Colonise");
            Console.WriteLine("2. Insert Json data into database.");
            Console.WriteLine("3. 2 -> 1.");
            Console.WriteLine("\nOption 1 will be selected automatically after 30 seconds.");
            Console.WriteLine("----------------------------------------------------------------------");
        }

        private static void LauncherOptionsSelections()
        {
            Console.Write("Select an option: ");

            Task<string> input = Task.Run(() => Console.ReadLine());
            if (input.Wait(TimeSpan.FromSeconds(30))) {
                pickedOption = input.Result;
            }
            else
            {
                pickedOption = "1";
            }
        }

        private async static Task ParseSelection(IServiceProvider serviceProvider)
        {
            if (pickedOption == "2")
            {
                await InsertIntoDatabase(serviceProvider);
                Console.ReadLine();
            }
            else if (pickedOption == "3")
            {
                await InsertIntoDatabase(serviceProvider);
                Launch();
            }
            else
            {
                Launch();
            }
        }

        private static void Launch()
        {
            Start = true;
        }

        private async static Task InsertIntoDatabase(IServiceProvider serviceProvider)
        {
            string filePath = SelectJson();

            if (File.Exists(filePath))
            {
                await using AsyncServiceScope scope = serviceProvider.CreateAsyncScope();
                DatabaseBulkWriter dbWriter = scope.ServiceProvider.GetRequiredService<DatabaseBulkWriter>();

                await dbWriter.InsertJsonIntoDatabase(filePath);
            }
            else
            {
                await InsertIntoDatabase(serviceProvider);
            }
        }

        private static string SelectJson()
        {
            Console.Write("Enter Json file path: ");
            return Console.ReadLine();
        }
    }
}
