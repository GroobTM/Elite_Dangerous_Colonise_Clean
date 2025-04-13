using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace elite_dangerous_colonise.Pages
{
    public class ErrorModel : PageModel
    {
        public string? RequestID { get; set; }
        public bool ShowRequestID => !string.IsNullOrEmpty(RequestID);

        [BindProperty(SupportsGet = true)]
        public int? StatusCode { get; set; } = 500;

        public void OnGet(int? statusCode = null)
        {
            RequestID = HttpContext.TraceIdentifier;

            StatusCode = statusCode ?? HttpContext.Response.StatusCode;

            if (StatusCode == 200)
            {
                StatusCode = 500;
                HttpContext.Response.StatusCode = 500;
            }
        }
    }
}
