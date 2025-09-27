using elite_dangerous_colonise.Classes;
using elite_dangerous_colonise.Models.Database_Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Newtonsoft.Json.Linq;
using Npgsql;


namespace elite_dangerous_colonise.Pages;

public class IndexModel : PageModel
{
    private readonly NpgsqlDataSource dataSource;
    private readonly ILogger<IndexModel> _logger;

    public SelectMaxSearchValuesResult MaxValues { get; private set; }

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

    public async Task<IActionResult> OnGet()
    {
        try
        {
            MaxValues = await SelectMaxSearchValues();

            return Page();
        }
        catch (NpgsqlException ex)
        {
            Logger.LogError("Index Page", 0, "A database error occurred.", ex);

            return RedirectToPage("/Error", new { statusCode = 500 });
        }

        catch (Exception ex)
        {
            Logger.LogError("Index Page", 1, ex);

            return RedirectToPage("/Error", new { statusCode = 500 });
        }
    }

    public void OnPost()
    {

    }

    private async Task<SelectMaxSearchValuesResult> SelectMaxSearchValues()
    {
        await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT * FROM \"MaxSearchValues\"", conn))
            {
                await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                {
                    await reader.ReadAsync();

                    return new SelectMaxSearchValuesResult(
                        reader.GetInt32(0),
                        reader.GetInt32(1),
                        reader.GetInt32(2),
                        reader.GetInt32(3),
                        reader.GetInt32(4),
                        reader.GetInt32(5),
                        reader.GetInt32(6),
                        reader.GetInt32(7),
                        reader.GetInt32(8),
                        reader.GetInt32(9),
                        reader.GetInt32(10),
                        reader.GetInt32(11),
                        reader.GetInt32(12),
                        reader.GetInt32(13),
                        reader.GetInt32(14),
                        reader.GetInt32(15),
                        reader.GetInt32(16),
                        reader.GetInt32(17),
                        reader.GetInt32(18),
                        reader.GetInt32(19)
                        );
                }
            }
        }
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
