
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Security.Claims;
using System.Text;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.WebUtilities;
using TMVisualsWebApp.Models.Account;

namespace TMVisualsWebApp.Controllers
{
    public class AccountController : Controller
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<AccountController> _logger;
        private const string GoogleVerifierCookie = "TMVisuals.GoogleVerifier";
        private const string GoogleStateCookie = "TMVisuals.GoogleState";

        public AccountController(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<AccountController> logger)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
        }

        [HttpGet]
        public IActionResult Register()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Register(
            RegisterViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            if (!TryGetSupabaseAuthSettings(out var url, out var key))
                return View(model);

            var client = _httpClientFactory.CreateClient("SupabaseAuth");

            using var request = CreateSupabaseRequest(
                HttpMethod.Post,
                $"{url}/auth/v1/signup",
                key,
                new
                {
                    email = model.Email,
                    password = model.Password,
                    data = new
                    {
                        full_name = model.Name.Trim(),
                        phone = model.Phone.Trim()
                    }
                });

            using var response = await client.SendAsync(request);

            if (!response.IsSuccessStatusCode)
            {
                ModelState.AddModelError(
                    string.Empty,
                    "Registration failed. Check your details and try again.");

                return View(model);
            }

            TempData["Message"] =
                "Registration submitted. Check your email if confirmation is required.";

            return RedirectToAction(nameof(Login));
        }

        [HttpGet]
        public IActionResult GoogleLogin()
        {
            if (!TryGetSupabaseAuthSettings(out var url, out _))
            {
                TempData["AuthMessage"] =
                    "Google sign-in is not configured. Please use email and password.";
                return RedirectToAction(nameof(Login));
            }

            var verifier = WebEncoders.Base64UrlEncode(
                RandomNumberGenerator.GetBytes(32));
            var state = WebEncoders.Base64UrlEncode(
                RandomNumberGenerator.GetBytes(32));
            var challenge = WebEncoders.Base64UrlEncode(
                SHA256.HashData(Encoding.ASCII.GetBytes(verifier)));
            var callbackUrl = Url.Action(
                nameof(GoogleCallback),
                "Account",
                new { state },
                Request.Scheme);
            if (string.IsNullOrWhiteSpace(callbackUrl))
            {
                TempData["AuthMessage"] =
                    "Google sign-in could not be started. Please try again.";
                return RedirectToAction(nameof(Login));
            }

            var cookieOptions = new CookieOptions
            {
                HttpOnly = true,
                Secure = Request.IsHttps,
                SameSite = SameSiteMode.Lax,
                Path = "/Account/GoogleCallback",
                MaxAge = TimeSpan.FromMinutes(10)
            };

            Response.Cookies.Append(GoogleVerifierCookie, verifier, cookieOptions);
            Response.Cookies.Append(GoogleStateCookie, state, cookieOptions);

            var authorizeUrl = QueryHelpers.AddQueryString(
                $"{url}/auth/v1/authorize",
                new Dictionary<string, string?>
                {
                    ["provider"] = "google",
                    ["redirect_to"] = callbackUrl,
                    ["code_challenge"] = challenge,
                    ["code_challenge_method"] = "s256"
                });

            return Redirect(authorizeUrl);
        }

        [HttpGet]
        public async Task<IActionResult> GoogleCallback(
            string? code,
            string? state,
            string? error,
            CancellationToken cancellationToken)
        {
            var verifier = Request.Cookies[GoogleVerifierCookie];
            var expectedState = Request.Cookies[GoogleStateCookie];
            DeleteGoogleFlowCookies();

            if (!string.IsNullOrWhiteSpace(error) ||
                string.IsNullOrWhiteSpace(code) ||
                !HasMatchingState(state, expectedState) ||
                string.IsNullOrWhiteSpace(verifier))
            {
                TempData["AuthMessage"] =
                    "Google sign-in could not be completed. Please try again.";
                return RedirectToAction(nameof(Login));
            }

            if (!TryGetSupabaseAuthSettings(out var url, out var key))
            {
                TempData["AuthMessage"] =
                    "Google sign-in is not configured. Please use email and password.";
                return RedirectToAction(nameof(Login));
            }

            var client = _httpClientFactory.CreateClient("SupabaseAuth");
            using var request = CreateSupabaseRequest(
                HttpMethod.Post,
                $"{url}/auth/v1/token?grant_type=pkce",
                key,
                new { auth_code = code, code_verifier = verifier });

            using var response = await client.SendAsync(
                request,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Supabase Google sign-in code exchange returned HTTP {StatusCode}.",
                    (int)response.StatusCode);
                TempData["AuthMessage"] =
                    "Google sign-in could not be completed. Please try again.";
                return RedirectToAction(nameof(Login));
            }

            var result = await response.Content
                .ReadFromJsonAsync<SupabaseLoginResponse>(
                    cancellationToken: cancellationToken);
            if (result?.User?.Id is not string userId ||
                string.IsNullOrWhiteSpace(userId) ||
                string.IsNullOrWhiteSpace(result.User.Email))
            {
                TempData["AuthMessage"] =
                    "Google sign-in could not be completed. Please try again.";
                return RedirectToAction(nameof(Login));
            }

            await SignInUserAsync(
                userId,
                result.User.Email,
                rememberMe: false);
            return RedirectToAction("Index", "Home");
        }

        [HttpGet]
        public IActionResult ForgotPassword()
        {
            return View(new ForgotPasswordViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ForgotPassword(
            ForgotPasswordViewModel model,
            CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
                return View(model);

            if (!TryGetSupabaseAuthSettings(out var url, out var key))
                return View(model);

            var resetUrl = Url.Action(
                nameof(ResetPassword),
                "Account",
                values: null,
                protocol: Request.Scheme);
            if (string.IsNullOrWhiteSpace(resetUrl))
            {
                ModelState.AddModelError(
                    string.Empty,
                    "Password reset is temporarily unavailable.");
                return View(model);
            }

            var client = _httpClientFactory.CreateClient("SupabaseAuth");
            var recoveryUrl = QueryHelpers.AddQueryString(
                $"{url}/auth/v1/recover",
                "redirect_to",
                resetUrl);
            using var request = CreateSupabaseRequest(
                HttpMethod.Post,
                recoveryUrl,
                key,
                new { email = model.Email.Trim() });

            using var response = await client.SendAsync(
                request,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Supabase password recovery request returned HTTP {StatusCode}.",
                    (int)response.StatusCode);
                TempData["AuthMessage"] =
                    "Password reset could not be requested right now. Please try again later.";
            }
            else
            {
                TempData["AuthMessage"] =
                    "If an account exists for that email, password reset instructions will be sent.";
            }

            return RedirectToAction(nameof(ForgotPassword));
        }

        [HttpGet]
        public IActionResult ResetPassword()
        {
            return View(new ResetPasswordViewModel());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ResetPassword(
            ResetPasswordViewModel model,
            CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
                return View(model);

            if (!TryGetSupabaseAuthSettings(out var url, out var key))
                return View(model);

            var client = _httpClientFactory.CreateClient("SupabaseAuth");
            using var request = CreateSupabaseRequest(
                HttpMethod.Put,
                $"{url}/auth/v1/user",
                key,
                new { password = model.Password });
            request.Headers.Authorization =
                new System.Net.Http.Headers.AuthenticationHeaderValue(
                    "Bearer",
                    model.AccessToken);

            using var response = await client.SendAsync(
                request,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Supabase password update returned HTTP {StatusCode}.",
                    (int)response.StatusCode);
                ModelState.AddModelError(
                    string.Empty,
                    "That reset link may have expired. Request a new one and try again.");
                return View(model);
            }

            TempData["AuthMessage"] =
                "Your password was updated. Sign in with your new password.";
            return RedirectToAction(nameof(Login));
        }

        [HttpGet]
        public IActionResult Login()
        {
            return View();
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Login(
            LoginViewModel model)
        {
            if (!ModelState.IsValid)
                return View(model);

            if (!TryGetSupabaseAuthSettings(out var url, out var key))
                return View(model);

            var client = _httpClientFactory.CreateClient("SupabaseAuth");

            using var request = CreateSupabaseRequest(
                HttpMethod.Post,
                $"{url}/auth/v1/token?grant_type=password",
                key,
                new { email = model.Email, password = model.Password });

            using var response = await client.SendAsync(request);

            if (!response.IsSuccessStatusCode)
            {
                ModelState.AddModelError(
                    string.Empty,
                    "Invalid email or password.");

                return View(model);
            }

            var result = await response.Content
                .ReadFromJsonAsync<SupabaseLoginResponse>();

            if (result?.User?.Id is not string userId ||
                string.IsNullOrWhiteSpace(userId))
            {
                ModelState.AddModelError(
                    string.Empty,
                    "Unable to complete sign-in.");

                return View(model);
            }

            await SignInUserAsync(
                userId,
                result.User.Email ?? model.Email,
                model.RememberMe);

            return RedirectToAction("Index", "Home");
        }

        private async Task SignInUserAsync(
            string userId,
            string email,
            bool rememberMe)
        {
            var claims = new List<Claim>
            {
                new(ClaimTypes.NameIdentifier, userId),
                new(ClaimTypes.Name, email),
                new(ClaimTypes.Email, email)
            };
            var identity = new ClaimsIdentity(
                claims,
                CookieAuthenticationDefaults.AuthenticationScheme);
            var principal = new ClaimsPrincipal(identity);

            await HttpContext.SignInAsync(
                CookieAuthenticationDefaults.AuthenticationScheme,
                principal,
                new AuthenticationProperties
                {
                    IsPersistent = rememberMe,
                    ExpiresUtc = DateTimeOffset.UtcNow.AddHours(
                        rememberMe ? 24 : 2)
                });
        }

        private static HttpRequestMessage CreateSupabaseRequest(
            HttpMethod method,
            string endpoint,
            string apiKey,
            object body)
        {
            var request = new HttpRequestMessage(method, endpoint);
            request.Headers.Add("apikey", apiKey);
            request.Content = JsonContent.Create(body);
            return request;
        }

        private void DeleteGoogleFlowCookies()
        {
            var options = new CookieOptions
            {
                Secure = Request.IsHttps,
                SameSite = SameSiteMode.Lax,
                Path = "/Account/GoogleCallback"
            };
            Response.Cookies.Delete(GoogleVerifierCookie, options);
            Response.Cookies.Delete(GoogleStateCookie, options);
        }

        private static bool HasMatchingState(
            string? suppliedState,
            string? expectedState)
        {
            if (string.IsNullOrEmpty(suppliedState) ||
                string.IsNullOrEmpty(expectedState))
            {
                return false;
            }

            var suppliedBytes = Encoding.UTF8.GetBytes(suppliedState);
            var expectedBytes = Encoding.UTF8.GetBytes(expectedState);
            return suppliedBytes.Length == expectedBytes.Length &&
                   CryptographicOperations.FixedTimeEquals(
                       suppliedBytes,
                       expectedBytes);
        }

        private bool TryGetSupabaseAuthSettings(out string url, out string key)
        {
            url = _configuration["Supabase:Url"]?.TrimEnd('/') ?? string.Empty;
            key = _configuration["Supabase:Key"] ?? string.Empty;

            if (Uri.TryCreate(url, UriKind.Absolute, out var projectUri) &&
                (projectUri.Scheme == Uri.UriSchemeHttps ||
                 projectUri.Scheme == Uri.UriSchemeHttp) &&
                !string.IsNullOrWhiteSpace(key))
            {
                return true;
            }

            ModelState.AddModelError(
                string.Empty,
                "Supabase Auth is not configured. Set Supabase:Url and Supabase:Key using .NET User Secrets.");
            return false;
        }

        private sealed class SupabaseLoginResponse
        {
            [JsonPropertyName("user")]
            public SupabaseUser? User { get; set; }
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Logout()
        {
            await HttpContext.SignOutAsync(
                CookieAuthenticationDefaults.AuthenticationScheme);

            return RedirectToAction("Index", "Home");
        }

        private sealed class SupabaseUser
        {
            [JsonPropertyName("id")]
            public string? Id { get; set; }

            [JsonPropertyName("email")]
            public string? Email { get; set; }
        }
    }
}
