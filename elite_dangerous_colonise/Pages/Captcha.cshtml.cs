using Ixnas.AltchaNet;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace elite_dangerous_colonise.Pages
{
    public class CaptchaModel : PageModel
    {
        private readonly AltchaService altchaService;

        [BindProperty(SupportsGet = true)]
        public string? ReturnUrl { get; set; }

        public CaptchaModel(AltchaService altchaService)
        {
            this.altchaService = altchaService;
        }

        public IActionResult OnGet()
        {
            ReturnUrl ??= Url.Content("~/");

            if (HttpContext.Session.GetString("PassedCaptcha") == "true")
            {
                if (!string.IsNullOrEmpty(ReturnUrl) && Url.IsLocalUrl(ReturnUrl))
                {
                    return Redirect(ReturnUrl);
                }
                else
                {
                    return RedirectToPage("/Index");
                }
            }

            return Page();  
        }

        public async Task<IActionResult> OnPostAsync()
        {
            string altchaFormContent = HttpContext.Request.Form["altcha"];
            AltchaValidationResult validationResult = await altchaService.Validate(altchaFormContent);

            if (string.IsNullOrEmpty(altchaFormContent) || !validationResult.IsValid)
            {
                ModelState.AddModelError("Altcha Failed", "Captcha check failed. Please try again.");
                return Page();
            }

            HttpContext.Session.SetString("PassedCaptcha", "true");

            if (!string.IsNullOrEmpty(ReturnUrl) && Url.IsLocalUrl(ReturnUrl))
            {
                return Redirect(ReturnUrl);
            }
            else
            {
                return RedirectToPage("/Index");
            }
        }

        public IActionResult OnGetChallenge()
        {
            AltchaChallenge challenge = altchaService.Generate();

            return new JsonResult(challenge);
        }
    }
}
