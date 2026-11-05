using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text.Json;
using TMVisualsWebApp.Models;
using TMVisualsWebApp.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Filters;

namespace TMVisualsWebApp.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly PortfolioCatalogService _portfolioCatalog;
        private readonly ServicesCatalogService _servicesCatalog;
        private readonly SupabaseBookingService _bookings;
        private readonly InvoiceCatalogService _invoiceCatalog;



        private readonly SupabaseDataService _data;
        private readonly SupabaseApiClient _api;

        public HomeController(
            ILogger<HomeController> logger,
            PortfolioCatalogService portfolioCatalog,
            ServicesCatalogService servicesCatalog,
            SupabaseBookingService bookings,
            InvoiceCatalogService invoiceCatalog,
            SupabaseDataService data,
            SupabaseApiClient api)
        {
            _logger = logger;
            _portfolioCatalog = portfolioCatalog;
            _servicesCatalog = servicesCatalog;
            _bookings = bookings;
            _invoiceCatalog = invoiceCatalog;
            _data = data;
            _api = api;
        }

        public IActionResult Index()
        {
            return View();
        }

       

        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
        }

        public async Task<IActionResult> Services(
            CancellationToken cancellationToken)
        {
            try
            {
                var services = await _servicesCatalog.FetchActiveServicesAsync(
                    cancellationToken);
                return View(services);
            }
            catch (Exception error) when (
                error is HttpRequestException ||
                error is InvalidOperationException ||
                error is JsonException)
            {
                _logger.LogError(error, "Could not load the public services.");
                ViewData["ServicesError"] =
                    "Services are temporarily unavailable. Please try again later.";
                return View(new List<ServiceItem>());
            }
        }

        public async Task<IActionResult> MyWork(CancellationToken cancellationToken)
        {
            try
            {
                var myWork = await _portfolioCatalog.FetchPublicItemsAsync(
                    cancellationToken);
                return View(myWork);
            }
            catch (Exception error) when (
                error is HttpRequestException ||
                error is InvalidOperationException ||
                error is JsonException)
            {
                _logger.LogError(error, "Could not load the public portfolio.");
                ViewData["PortfolioError"] =
                    "Portfolio items are temporarily unavailable. Please try again later.";
                return View(new List<PortfolioItem>());
            }
        }

        [Authorize]
        public IActionResult Booking()
        {
            return View();
        }

        [Authorize]
        public async Task<IActionResult> Profile(CancellationToken cancellationToken)
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return Forbid();
            var accessToken = await _api.AccessTokenAsync(cancellationToken);

            var myBookings = (await _bookings.FetchMineAsync(cancellationToken: cancellationToken))
                .OrderByDescending(b => b.Date)
                .ToList();

            var first = myBookings.FirstOrDefault();
            IReadOnlyList<InvoiceDownload> invoices;
            try
            {
                invoices = await _invoiceCatalog.FetchForClientAsync(email, cancellationToken, accessToken);
            }
            catch (Exception error) when (
                error is HttpRequestException ||
                error is InvalidOperationException ||
                error is JsonException)
            {
                _logger.LogError(error, "Could not load invoices for {Email}.", email);
                invoices = Array.Empty<InvoiceDownload>();
                TempData["InvoiceError"] = "Invoices are temporarily unavailable.";
            }

            var saved = await _data.GetMyProfileAsync(accessToken, userId, cancellationToken);

            var user = new UserProfile
            {
                FullName = saved?.FullName ?? first?.Name ?? email.Split('@')[0],
                Email = email,
                PhoneNumber = saved?.Phone ?? first?.Phone,
                Bookings = myBookings,
                Invoices = invoices.ToList()
            };

            return View(user);
        }

        [Authorize]
        public async Task<IActionResult> DownloadInvoice(
            string id,
            CancellationToken cancellationToken)
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
            var accessToken = await _api.AccessTokenAsync(cancellationToken);
            var invoice = (await _invoiceCatalog.FetchForClientAsync(email, cancellationToken, accessToken))
                .FirstOrDefault(item => string.Equals(item.Id, id, StringComparison.Ordinal));

            if (invoice == null)
            {
                return NotFound();
            }

            var downloadUrl = await _invoiceCatalog.CreateSignedDownloadUrlAsync(
                invoice.FilePath,
                invoice.Reference,
                cancellationToken,
                accessToken);
            return Redirect(downloadUrl);
        }

        [Authorize]
        public async Task<IActionResult> BookingStatus(Guid id, CancellationToken cancellationToken)
        {
            var booking = (await _bookings.FetchMineAsync(id,cancellationToken)).SingleOrDefault();

            if (booking == null)
            {
                return NotFound();
            }

            return View(booking);
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> CancelBooking(Guid id, CancellationToken cancellationToken)
        {
            try
            {
                await _bookings.CancelAsync(id,cancellationToken);
            }
            catch (SupabaseApiException error) when (error.Code == "P0001")
            {
                TempData["BookingError"] = "This booking could not be cancelled. Its status may have changed.";
                return RedirectToAction(nameof(BookingStatus),new {id});
            }

            return RedirectToAction(nameof(CancellationNotification));
        }

        [Authorize]
        public IActionResult CancellationNotification()
        {
            return View();
        }




        // DELETE this entire block:
        // private static readonly List<ClientContent> contentItems = new() { ... };

        // REPLACE MyContent() with:
        [Authorize]
        public async Task<IActionResult> MyContent(CancellationToken cancellationToken)
        {
            var items = (await _bookings.FetchMineAsync(cancellationToken: cancellationToken))
                .Where(b => b.Status is "Confirmed" or "Completed" && b.Date.HasValue)
                .OrderByDescending(b => b.Date)
                .Select(b => new ClientContent(b))
                .ToList();

            return View(items);
        }

        [Authorize]
        [HttpGet]
        public async Task<IActionResult> EditDetails(CancellationToken cancellationToken)
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
            if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
                return Forbid();
            var accessToken = await _api.AccessTokenAsync(cancellationToken);

            var latest = (await _bookings.FetchMineAsync(cancellationToken: cancellationToken))
                .OrderByDescending(b => b.Date)
                .FirstOrDefault();

            var saved = await _data.GetMyProfileAsync(accessToken, userId, cancellationToken);

            var profile = new UserProfile
            {
                FullName = saved?.FullName ?? latest?.Name ?? email.Split('@')[0],
                Email = email,
                PhoneNumber = saved?.Phone ?? latest?.Phone
            };

            return View(profile);
        }

        [Authorize]
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditDetails(UserProfile model, CancellationToken cancellationToken)
        {
            ModelState.Remove("Bookings");
            ModelState.Remove("Invoices");

            // The email is the login, so always use the one from the cookie
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
            model.Email = email;
            ModelState.Remove("Email");

            if (string.IsNullOrWhiteSpace(model.FullName))
                ModelState.AddModelError(nameof(model.FullName), "Please enter your name.");

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            var accessToken = await _api.AccessTokenAsync(cancellationToken);
            try
            {
                await _data.UpdateMyProfileAsync(
                    accessToken,
                    model.FullName.Trim(),
                    model.PhoneNumber?.Trim(),
                    cancellationToken);
            }
            catch (Exception error) when (
                error is SupabaseDataException or HttpRequestException or
                    JsonException or InvalidOperationException)
            {
                _logger.LogError(error, "Could not update the signed-in user's profile.");
                ModelState.AddModelError(
                    string.Empty,
                    "Your profile could not be saved. Please try again or contact support.");
                return View(model);
            }

            TempData["Message"] = "Details updated.";
            return RedirectToAction("Profile");
        }

        public override async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var executed = await next();
            if (executed.Exception is SupabaseSignInRequiredException)
            {
                executed.ExceptionHandled = true;
                executed.Result = Challenge();
            }
            else if (executed.Exception is SupabaseApiException or SupabaseDataException or HttpRequestException or JsonException or InvalidOperationException)
            {
                _logger.LogError(executed.Exception,"Could not load shared client booking data.");
                executed.ExceptionHandled = true;
                Response.StatusCode = 503;
                executed.Result = View("Error",new ErrorViewModel { RequestId=HttpContext.TraceIdentifier });
            }
        }


    }
}

