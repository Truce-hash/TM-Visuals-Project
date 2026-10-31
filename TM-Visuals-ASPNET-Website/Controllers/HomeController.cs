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
        private readonly BookingStore _store;

        public HomeController(
            ILogger<HomeController> logger,
            PortfolioCatalogService portfolioCatalog,
            BookingStore store)
        {
            _logger = logger;
            _portfolioCatalog = portfolioCatalog;
            _store = store;
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

        public IActionResult Services()
        {
            return View();
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
        public IActionResult Profile()
        {
            var email = User.FindFirstValue(ClaimTypes.Email) ?? string.Empty;

            var myBookings = _store.All()
                .Where(b => string.Equals(b.Email, email, StringComparison.OrdinalIgnoreCase))
                .OrderByDescending(b => b.Date)
                .ToList();

            var first = myBookings.FirstOrDefault();

            var user = new UserProfile
            {
                FullName = first?.Name ?? email.Split('@')[0],
                Email = email,
                PhoneNumber = first?.Phone,
                Bookings = myBookings
            };

            return View(user);
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
        public IActionResult MyContent()
        {
            var items = _store.All()
                .Where(b => b.Status == "Confirmed" && b.Date.HasValue)
                .OrderByDescending(b => b.Date)
                .Select(b => new ClientContent(b))
                .ToList();

            return View(items);
        }

        [HttpGet]
        public IActionResult EditDetails()
        {
            // Use the same UserProfile object your Profile() action uses
            var profile = new UserProfile { FullName = "Musa Bonga", Email = "musa@example.com", PhoneNumber = null };
            return View(profile);
        }

        [HttpPost]
        public IActionResult EditDetails(UserProfile model)
        {
            ModelState.Remove("Bookings");

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
