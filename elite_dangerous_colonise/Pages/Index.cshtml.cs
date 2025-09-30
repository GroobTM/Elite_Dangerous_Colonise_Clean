using elite_dangerous_colonise.Classes;
using elite_dangerous_colonise.Models.Database_Results;
using elite_dangerous_colonise.Models.Database_Types;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Newtonsoft.Json.Linq;
using Npgsql;
using NpgsqlTypes;
using System.Text.RegularExpressions;


namespace elite_dangerous_colonise.Pages;

public class IndexModel : PageModel
{
    private readonly NpgsqlDataSource dataSource;
    private readonly ILogger<IndexModel> _logger;

    public SelectMaxSearchValuesResult MaxValues { get; private set; }
    public List<string> HotspotTypes { get; private set; }

    [BindProperty]
    public string ColonisedSystem { get; set; }

    [BindProperty]
    public string Faction { get; set; }

    [BindProperty]
    public string SortOrder { get; set; }


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
            HotspotTypes = await SelectHotspotTypes();

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

    private async Task<List<string>> SelectHotspotTypes()
    {
        List<string> result = new List<string>();

        await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
        {
            await using (NpgsqlCommand command = new NpgsqlCommand("SELECT DISTINCT \"hotspotType\" FROM \"Hotspots\";", conn))
            {
                await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                {
                    while(await reader.ReadAsync())
                    {
                        result.Add(Regex.Replace(reader.GetString(0), "(\\B[A-Z])", " $1"));
                    }
                }
            }
        }

        return result;
    }

    private ResultOrderType ParseSortOrder(string inputOrder)
    {
        if(Enum.TryParse<ResultOrderType>(inputOrder, out ResultOrderType resultOrder))
        {
            return resultOrder;
        }
        else
        {
            return ResultOrderType.SystemValue;
        }
    }

    private List<HotspotType>? ParseHotspotTypes(string inputHotspots)
    {
        List<HotspotType> hotspotTypes = new List<HotspotType>();

        if (inputHotspots != null)
        {
            foreach (string hotspot in inputHotspots.Split(","))
            {
                if (Enum.TryParse<HotspotType>(hotspot, out HotspotType hotspotType))
                {
                    hotspotTypes.Add(hotspotType);
                }
            }
        }

        if (hotspotTypes.Count > 0)
        {
            return hotspotTypes;
        }
        else
        {
            return null;
        }
    }

    public async Task<IActionResult> OnGetSearchAsync(string sortOrder, int pageNo, short resultsPerPage, string systemName,
        string factionName, short minBlackHoles, short maxBlackHoles, short minNeutronStars, short maxNeutronStars, short minWhiteDwarves, short maxWhiteDwarves,
        short minOtherStars, short maxOtherStars, short minEarthLikes, short maxEarthLikes, short minWaterWorlds, short maxWaterWorlds, short minAmmoniaWorlds,
        short maxAmmoniaWorlds, short minGasGiants, short maxGasGiants, short minHighMetalContents, short maxHighMetalContents, short minMetalRiches,
        short maxMetalRiches, short minRockyIces, short maxRockyIces, short minRocks, short maxRocks, short minIces, short maxIces, short minOrganics,
        short maxOrganics, short minGeologicals, short maxGeologicals, short minRings, short maxRings, short minLandables, short maxLandables,
        short minWalkables, short maxWalkables, int maxDistanceToSol, string hotspotTypes)
    {
        if (!UpdateHub.isSearchBlocked)
        {
            try
            {
                await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
                {
                    await using (NpgsqlCommand command = new NpgsqlCommand("SELECT \"SelectSearchResults\"(" +
                        "@sortOrder, " +
                        "@pageNo, " +
                        "@resultsPerPage, " +
                        "@systemName, "  +
                        "@factionName, " +
                        "@minBlackHoles, " +
                        "@maxBlackHoles, " +
                        "@minNeutronStars, " +
                        "@maxNeutronStars, " +
                        "@minWhiteDwarves, " +
                        "@maxWhiteDwarves, " +
                        "@minOtherStars, " +
                        "@maxOtherStars, " +
                        "@minEarthLikes, " +
                        "@maxEarthLikes, " +
                        "@minWaterWorlds, " +
                        "@maxWaterWorlds, " +
                        "@minAmmoniaWorlds, " +
                        "@maxAmmoniaWorlds, " +
                        "@minGasGiants, " +
                        "@maxGasGiants, " +
                        "@minHighMetalContents, " +
                        "@maxHighMetalContents, " +
                        "@minMetalRiches, " +
                        "@maxMetalRiches, " +
                        "@minRockyIces, " +
                        "@maxRockyIces, " +
                        "@minRocks, " +
                        "@maxRocks, " +
                        "@minIces, " +
                        "@maxIces, " +
                        "@minOrganics, " +
                        "@maxOrganics, " +
                        "@minGeologicals, " +
                        "@maxGeologicals, " +
                        "@minRings, " +
                        "@maxRings, " +
                        "@minLandables, " +
                        "@maxLandables, " +
                        "@minWalkables, " +
                        "@maxWalkables, " +
                        "@maxDistanceToSol, " +
                        "@hotspotTypes" +
                        ")", conn))
                    {
                        command.Parameters.AddWithValue("sortOrder", ParseSortOrder(sortOrder));
                        command.Parameters.AddWithValue("pageNo", Math.Max(1, pageNo));
                        command.Parameters.AddWithValue("resultsPerPage", Math.Min((short)50, resultsPerPage));
                        command.Parameters.AddWithValue("systemName", NpgsqlDbType.Varchar, (object)systemName ?? DBNull.Value);
                        command.Parameters.AddWithValue("factionName", NpgsqlDbType.Varchar, (object)factionName ?? DBNull.Value);
                        command.Parameters.AddWithValue("minBlackHoles", minBlackHoles);
                        command.Parameters.AddWithValue("maxBlackHoles", maxBlackHoles);
                        command.Parameters.AddWithValue("minNeutronStars", minNeutronStars);
                        command.Parameters.AddWithValue("maxNeutronStars", maxNeutronStars);
                        command.Parameters.AddWithValue("minWhiteDwarves", minWhiteDwarves);
                        command.Parameters.AddWithValue("maxWhiteDwarves", maxWhiteDwarves);
                        command.Parameters.AddWithValue("minOtherStars", minOtherStars);
                        command.Parameters.AddWithValue("maxOtherStars", maxOtherStars);
                        command.Parameters.AddWithValue("minEarthLikes", minEarthLikes);
                        command.Parameters.AddWithValue("maxEarthLikes", maxEarthLikes);
                        command.Parameters.AddWithValue("minWaterWorlds", minWaterWorlds);
                        command.Parameters.AddWithValue("maxWaterWorlds", maxWaterWorlds);
                        command.Parameters.AddWithValue("minAmmoniaWorlds", minAmmoniaWorlds);
                        command.Parameters.AddWithValue("maxAmmoniaWorlds", maxAmmoniaWorlds);
                        command.Parameters.AddWithValue("minGasGiants", minGasGiants);
                        command.Parameters.AddWithValue("maxGasGiants", maxGasGiants);
                        command.Parameters.AddWithValue("minHighMetalContents", minHighMetalContents);
                        command.Parameters.AddWithValue("maxHighMetalContents", maxHighMetalContents);
                        command.Parameters.AddWithValue("minMetalRiches", minMetalRiches);
                        command.Parameters.AddWithValue("maxMetalRiches", maxMetalRiches);
                        command.Parameters.AddWithValue("minRockyIces", minRockyIces);
                        command.Parameters.AddWithValue("maxRockyIces", maxRockyIces);
                        command.Parameters.AddWithValue("minRocks", minRocks);
                        command.Parameters.AddWithValue("maxRocks", maxRocks);
                        command.Parameters.AddWithValue("minIces", minIces);
                        command.Parameters.AddWithValue("maxIces", maxIces);
                        command.Parameters.AddWithValue("minOrganics", minOrganics);
                        command.Parameters.AddWithValue("maxOrganics", maxOrganics);
                        command.Parameters.AddWithValue("minGeologicals", minGeologicals);
                        command.Parameters.AddWithValue("maxGeologicals", maxGeologicals);
                        command.Parameters.AddWithValue("minRings", minRings);
                        command.Parameters.AddWithValue("maxRings", maxRings);
                        command.Parameters.AddWithValue("minLandables", minLandables);
                        command.Parameters.AddWithValue("maxLandables", maxLandables);
                        command.Parameters.AddWithValue("minWalkables", minWalkables);
                        command.Parameters.AddWithValue("maxWalkables", maxWalkables);
                        command.Parameters.AddWithValue("maxDistanceToSol", maxDistanceToSol);
                        command.Parameters.AddWithValue("hotspotTypes", (object)ParseHotspotTypes(hotspotTypes) ?? DBNull.Value);
                        
                        await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync() && !await reader.IsDBNullAsync(0))
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
                Logger.LogError("Index Page", 0, ex);

                return StatusCode(500, new
                {
                    success = false,
                    error = "A database error occurred."
                });
            }

            catch (Exception ex)
            {
                Logger.LogError("Index Page", 1, ex);

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
