using elite_dangerous_colonise.Classes;
using elite_dangerous_colonise.Models.Database_Results;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Npgsql;
using System.Text.RegularExpressions;


namespace elite_dangerous_colonise.Pages;

public class IndexModel : PageModel
{
    private readonly NpgsqlDataSource dataSource;

    public SelectMaxSearchValuesResult MaxValues { get; private set; }
    public List<string> HotspotTypes { get; private set; }

    [BindProperty]
    public string ColonisedSystem { get; set; }

    [BindProperty]
    public string Faction { get; set; }

    [BindProperty]
    public string SortOrder { get; set; }


    public IndexModel(NpgsqlDataSource dataSource)
    {
        this.dataSource = dataSource;
    }

    public async Task<IActionResult> OnGet()
    {
        if (HttpContext.Session.GetString("PassedCaptcha") != "true")
        {
            string returnUrl = $"{Request.Path}{Request.QueryString}";

            return RedirectToPage("/Captcha", new { ReturnUrl = returnUrl });
        }


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
}
