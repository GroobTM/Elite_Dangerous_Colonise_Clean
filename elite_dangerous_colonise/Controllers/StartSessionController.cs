using Microsoft.AspNetCore.Mvc;
using Newtonsoft.Json;

namespace elite_dangerous_colonise.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class StartSessionController : ControllerBase
    {
        [HttpPost]
        public IActionResult Post([FromBody] List<long> reportedStarSystems)
        {
            if (string.IsNullOrEmpty(HttpContext.Session.GetString("reportedStarSystemsJson")))
            {
                HttpContext.Session.SetString("reportedStarSystemsJson", JsonConvert.SerializeObject(reportedStarSystems ?? []));
                return Ok("Session created.");
            }
            else
            {
                return Ok("Session already created.");
            }
        }
    }
}
