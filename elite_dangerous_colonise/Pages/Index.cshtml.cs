using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Newtonsoft.Json.Linq;
using Npgsql;
using elite_dangerous_colonise.Classes;


namespace elite_dangerous_colonise.Pages;

public class IndexModel : PageModel
{
    private readonly NpgsqlDataSource dataSource;
    private readonly ILogger<IndexModel> _logger;

    [BindProperty]
    public string ColonisedSystem { get; set; }

    [BindProperty]
    public string Faction { get; set; }

    [BindProperty]
    public string SortOrder { get; set; }

    [BindProperty]
    public bool IncludeClaimed { get; set; }

    public IndexModel(ILogger<IndexModel> logger, NpgsqlDataSource dataSource)
    {
        _logger = logger;
        this.dataSource = dataSource;
    }

    public void OnGet()
    {

    }

    public void OnPost()
    {

    }

    private string ParseSearchOrder(string inputOrder)
    {
        string[] validOrders =
        {
            "bodyValue",
            "landableBodies",
            "hotspots",
            "totalValue",
            "solDistance",
            "trailblazerDistance"
        };

        if (validOrders.Contains(inputOrder))
        {
            return inputOrder;
        }
        else
        {
            return "totalValue";
        }
    }

    public async Task<IActionResult> OnGetSearchAsync(string colonisedSystem, string faction, string sortOrder,
        bool includeClaimed, int currentPage, short resultsPerPage)
    {
        if (!UpdateHub.isSearchBlocked)
        {
            try
            {
                await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
                {
                    await using (NpgsqlCommand command = new NpgsqlCommand(
                        "SELECT GetSearchResultsFunc(@colonisedSystem, @faction, @sortOrder, @includeColonising, @pageNo, @resultsPerPage)", conn))
                    {
                        command.Parameters.AddWithValue("colonisedSystem", colonisedSystem ?? "");
                        command.Parameters.AddWithValue("faction", faction ?? "");
                        command.Parameters.AddWithValue("sortOrder", ParseSearchOrder(sortOrder));
                        command.Parameters.AddWithValue("includeColonising", includeClaimed);
                        command.Parameters.AddWithValue("pageNo", Math.Max(currentPage, 1));
                        command.Parameters.AddWithValue("resultsPerPage", Math.Min(Math.Max(resultsPerPage, (short)1), (short)50));

                        await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync())
                            {
                                string jsonResult = reader.GetFieldValue<string>(0);

                                JObject parsedJson = JObject.Parse(jsonResult);

                                return Content(parsedJson.ToString(), "application/json");
                            }
                            else
                            {
                                return Content("{}", "application/json");
                            }
                        }
                    }
                }
            }
            catch (NpgsqlException ex)
            {
                Logger.LogError("User Result Controller", 0, ex);

                return StatusCode(500, new
                {
                    success = false,
                    error = "A database error occurred."
                });
            }

            catch (Exception ex)
            {
                Logger.LogError("User Result Controller", 1, ex);

                return StatusCode(500, new
                {
                    success = false,
                    error = "An unexpected error occurred. Please try again later."
                });
            }
        }
        else
        {
            return StatusCode(403, new
            {
                success = false,
                error = "Search is currently blocked."
            });
        }
    }
}
