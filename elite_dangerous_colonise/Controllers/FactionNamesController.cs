using elite_dangerous_colonise.Classes;
using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json.Linq;
using Npgsql;

namespace elite_dangerous_colonise.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class FactionNamesController : ControllerBase
    {
        private const int MIN_QUERY_LENGTH = 2;

        private readonly NpgsqlDataSource dataSource;

        public FactionNamesController(NpgsqlDataSource dataSource)
        {
            this.dataSource = dataSource;
        }

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] string? query)
        {
            if (string.IsNullOrEmpty(query) || query.Length < MIN_QUERY_LENGTH)
            {
                return Ok(new JArray());
            }

            try
            {
                await using (NpgsqlConnection conn = await dataSource.OpenConnectionAsync())
                {
                    await using (NpgsqlCommand command = new NpgsqlCommand("SELECT \"SelectFactionNamesJson\"(@name)", conn))
                    {
                        command.Parameters.AddWithValue("name", query);

                        await using (NpgsqlDataReader reader = await command.ExecuteReaderAsync())
                        {
                            if (await reader.ReadAsync() && !await reader.IsDBNullAsync(0))
                            {
                                string jsonResult = reader.GetFieldValue<string>(0);

                                JArray parsedJson = JArray.Parse(jsonResult);

                                return Content(parsedJson.ToString(), "application/json");
                            }
                            else
                            {
                                return Content("[]", "application/json");
                            }
                        }
                    }
                }
            }
            catch (NpgsqlException ex)
            {
                Logger.LogError("Faction Names Controller", 0, ex);

                return StatusCode(500, new
                {
                    success = false,
                    error = "A database error occurred."
                });
            }

            catch (Exception ex)
            {
                Logger.LogError("Faction Names Controller", 1, ex);

                return StatusCode(500, new
                {
                    success = false,
                    error = "An unexpected error occurred. Please try again later."
                });
            }
        }
    }
}
