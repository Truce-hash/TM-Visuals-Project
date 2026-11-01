using Microsoft.AspNetCore.Mvc;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text.Json;
using TMVisualsWebApp.Models;
using TMVisualsWebApp.Services;
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace TMVisualsWebApp.Controllers
{
    public class HomeController : Controller
    {
        private readonly ILogger<HomeController> _logger;
        private readonly PortfolioCatalogService _portfolioCatalog;
        private readonly ServicesCatalogService _servicesCatalog;
        private readonly BookingStore _store;
        private readonly InvoiceCatalogService _invoiceCatalog;

        public HomeController(
            ILogger<HomeController> logger,
            PortfolioCatalogService portfolioCatalog,
            ServicesCatalogService servicesCatalog,
            BookingStore store,
            InvoiceCatalogService invoiceCatalog)
        {
            _logger = logger;
            _portfolioCatalog = portfolioCatalog;
            _servicesCatalog = servicesCatalog;
            _store = store;
            _invoiceCatalog = invoiceCatalog;
        }

        public IActionResult Index()
        {
            return View();
        }

        public IActionResult Privacy()
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

        public IActionResult Booking()
        {
            return View();
        }

        [Authorize]
        public async Task<IActionResult> Profile(CancellationToken cancellationToken)
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

            var myBookings = _store.All()
                .Where(b => string.Equals(b.Email, email, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(b => b.Date)
                .ToList();

            var first = myBookings.FirstOrDefault();
            IReadOnlyList<InvoiceDownload> invoices;
            try
            {
                invoices = await _invoiceCatalog.FetchForClientAsync(email, cancellationToken);
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

            var user = new UserProfile
            {
                FullName = first?.Name ?? email.Split('@')[0],
                Email = email,
                PhoneNumber = first?.Phone,
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
            var invoice = (await _invoiceCatalog.FetchForClientAsync(email, cancellationToken))
                .FirstOrDefault(item => string.Equals(item.Id, id, StringComparison.Ordinal));

            if (invoice == null)
            {
                return NotFound();
            }

            var downloadUrl = await _invoiceCatalog.CreateSignedDownloadUrlAsync(
                invoice.FilePath,
                invoice.Reference,
                cancellationToken);
            return Redirect(downloadUrl);
        }

        [Authorize]
        public IActionResult BookingStatus(int id)
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

            var booking = _store.All().FirstOrDefault(b =>
                b.Id == id &&
                string.Equals(b.Email, email, StringComparison.OrdinalIgnoreCase));

            if (booking == null)
            {
                return NotFound();
            }

            return View(booking);
        }




        // DELETE this entire block:
        // private static readonly List<ClientContent> contentItems = new() { ... };

        // REPLACE MyContent() with:
        [Authorize]
        public IActionResult MyContent()
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

            var items = _store.All()
                .Where(b => string.Equals(b.Email, email, StringComparison.OrdinalIgnoreCase)
                         && b.Status == "Confirmed" && b.Date.HasValue)
                .OrderByDescending(b => b.Date)
                .Select(b => new ClientContent(b))
                .ToList();

            return View(items);
        }

        [Authorize]
        [HttpGet]
        public IActionResult EditDetails()
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

            var latest = _store.All()
                .Where(b => string.Equals(b.Email, email, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(b => b.Date)
                .FirstOrDefault();

            var profile = new UserProfile
            {
                FullName = latest?.Name ?? email.Split('@')[0],
                Email = email,
                PhoneNumber = latest?.Phone
            };

            return View(profile);
        }

        [Authorize]
        [HttpPost]
        public IActionResult EditDetails(UserProfile model)
        {
            ModelState.Remove("Bookings");

            // The email is the login, so always use the one from the cookie
            model.Email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;
            ModelState.Remove("Email");

            if (!ModelState.IsValid)
            {
                return View(model);
            }

            // TODO: save to the database once Supabase is connected
            TempData["Message"] = "Details updated.";
            return RedirectToAction("Profile");
        }
    }
}


