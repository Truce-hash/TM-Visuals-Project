using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using System.Text.Json;
using TMVisualsWebApp.Models;
using TMVisualsWebApp.Services;

namespace TMVisualsWebApp.Controllers
{
    public class BookingController : Controller
    {
        // South Africa is UTC+2 year-round, with no daylight saving.
        private static readonly TimeSpan SastOffset = TimeSpan.FromHours(2);
        // Keep in step with BookingAvailabilityService.MinimumSession.
        private static readonly TimeSpan MinimumDuration = TimeSpan.FromHours(1);
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;
        private readonly ILogger<BookingController> _logger;
        private readonly BookingAvailabilityService _availability;

        public BookingController(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration,
            ILogger<BookingController> logger,
            BookingAvailabilityService availability)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
            _logger = logger;
            _availability = availability;
        }

        // Availability must always be fresh, so it never let a browser or proxy cache it.
        [HttpGet]
        [ResponseCache(NoStore = true, Location = ResponseCacheLocation.None)]
        public IActionResult Availability(int year, int month)
        {
            if (year < 2000 || year > 2100 || month < 1 || month > 12)
            {
                return BadRequest();
            }

            return Json(new { days = _availability.GetMonth(year, month) });
        }

        [HttpGet]
        public IActionResult CreateBooking()
        {
            // Don't leave an old confirmation sitting in TempData next to a new booking.
            TempData.Remove("BookingConfirmation");

            return View(new Booking());
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public IActionResult CreateBooking(
            [Bind(
                nameof(Booking.Name),
                nameof(Booking.Phone),
                nameof(Booking.Email),
                nameof(Booking.Service),
                nameof(Booking.EventType),
                nameof(Booking.Date),
                nameof(Booking.StartTime),
                nameof(Booking.FinishTime),
                nameof(Booking.Location),
                nameof(Booking.Latitude),
                nameof(Booking.Longitude),
                nameof(Booking.NumberOfPeople),
                nameof(Booking.Budget),
                nameof(Booking.AcceptTerms))]
            Booking booking)
        {
            NormalizeBooking(booking);
            ValidateBooking(booking);

            if (!ModelState.IsValid)
            {
                foreach (var entry in ModelState.Where(x => x.Value!.Errors.Count > 0))
                {
                    foreach (var error in entry.Value!.Errors)
                    {
                        // The posted value is deliberately not logged: it can be a
                        // name, phone number or email address.
                        _logger.LogWarning(
                            "Booking validation error on '{Field}': {Error}",
                            entry.Key,
                            error.ErrorMessage);
                    }
                }

                return View(booking);
            }

            // The status is set by the server, not accepted from the form.
            booking.Status = "Pending";

            if (!_availability.TryReserve(booking))
            {
                ModelState.AddModelError(
                    nameof(booking.Date),
                    "That time is no longer available. " +
                    "Please choose another time or date.");

                return View(booking);
            }

            TempData["BookingConfirmation"] =
                JsonSerializer.Serialize(BuildConfirmation(booking));

            return RedirectToAction(nameof(Confirmation));
        }

        [HttpGet]
        public IActionResult Confirmation()
        {
            // Peek so refreshing the page doesn't immediately remove the confirmation.
            var json = TempData.Peek("BookingConfirmation") as string;

            if (string.IsNullOrEmpty(json))
            {
                return RedirectToAction(nameof(CreateBooking));
            }

            var model =
                JsonSerializer.Deserialize<BookingConfirmationViewModel>(json);

            if (model is null)
            {
                return RedirectToAction(nameof(CreateBooking));
            }

            return View(model);
        }

        private BookingConfirmationViewModel BuildConfirmation(Booking booking)
        {
            var typeOfBooking = $"{booking.EventType} - {booking.Service}";

            var message = string.Join(
                "\n",
                "Hi, I've just submitted a booking and I'd like to discuss the details and pricing.",
                "[Details]",
                $"Name: {booking.Name}",
                $"Type of booking: {typeOfBooking}",
                $"Date: {booking.Date:yyyy-MM-dd}",
                $"Budget: R{booking.Budget:N2}",
                $"Email: {booking.Email}",
                $"Contact number: {booking.Phone}");

            var number = new string(
                (_configuration["WhatsApp:Number"] ?? string.Empty)
                    .Where(char.IsDigit)
                    .ToArray());

            var whatsAppUrl = string.Empty;

            if (number.Length == 0)
            {
                _logger.LogWarning(
                    "WhatsApp:Number is not configured; WhatsApp link not generated.");
            }
            else
            {
                whatsAppUrl =
                    $"https://wa.me/{number}?text={Uri.EscapeDataString(message)}";
            }

            return new BookingConfirmationViewModel
            {
                //BookingId = booking.Id,
                //Name = booking.Name,
                //Service = booking.Service,
                //EventType = booking.EventType,
                //Date = booking.Date,
                //StartTime = booking.StartTime,
                //FinishTime = booking.FinishTime,
                //Location = booking.Location,
                //Budget = booking.Budget,
                //WhatsAppUrl = whatsAppUrl
            };
        }

        [HttpGet("/Booking/SearchLocations")]
        public async Task<IActionResult> SearchLocations(
            string? query,
            double? latitude,
            double? longitude,
            CancellationToken ct)
        {
            query = query?.Trim();

            if (string.IsNullOrWhiteSpace(query) || query.Length < 3)
            {
                return Json(Array.Empty<object>());
            }

            var url =
                $"api?q={Uri.EscapeDataString(query)}" +
                "&limit=8" +
                "&lang=en";

            if (latitude.HasValue && longitude.HasValue)
            {
                url += $"&lat={latitude.Value.ToString(CultureInfo.InvariantCulture)}" +
                       $"&lon={longitude.Value.ToString(CultureInfo.InvariantCulture)}";
            }

            // Rough South Africa bounding box: minLon,minLat,maxLon,maxLat.
            url += "&bbox=16.3,-35.0,33.1,-22.0";

            try
            {
                using var doc = await GetPhotonAsync(url, ct);

                if (!doc.RootElement.TryGetProperty("features", out var features) ||
                    features.ValueKind != JsonValueKind.Array)
                {
                    return Json(Array.Empty<object>());
                }

                var results = new List<object>();
                var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

                foreach (var feature in features.EnumerateArray())
                {
                    if (!feature.TryGetProperty("properties", out var properties))
                    {
                        continue;
                    }

                    if (!feature.TryGetProperty("geometry", out var geometry) ||
                        !geometry.TryGetProperty("coordinates", out var coordinates) ||
                        coordinates.ValueKind != JsonValueKind.Array ||
                        coordinates.GetArrayLength() < 2)
                    {
                        continue;
                    }

                    var label = BuildLabel(properties);

                    if (string.IsNullOrWhiteSpace(label) || !seen.Add(label))
                    {
                        continue;
                    }

                    if (!coordinates[0].TryGetDouble(out var longitudeResult) ||
                        !coordinates[1].TryGetDouble(out var latitudeResult))
                    {
                        continue;
                    }

                    results.Add(new
                    {
                        displayName = label,
                        latitude = latitudeResult,
                        longitude = longitudeResult
                    });

                    if (results.Count == 5)
                    {
                        break;
                    }
                }

                return Json(results);
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                return StatusCode(499);
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Location search failed for query '{Query}'.",
                    query);

                return StatusCode(StatusCodes.Status502BadGateway);
            }
        }

        [HttpGet("/Booking/ReverseGeocode")]
        public async Task<IActionResult> ReverseGeocode(
            double latitude, double longitude, CancellationToken ct)
        {
            if (latitude is < -90 or > 90 ||
                longitude is < -180 or > 180 ||
                (latitude == 0 && longitude == 0))
            {
                return BadRequest(
                    new { message = "The supplied coordinates are invalid." });
            }

            var url =
                $"reverse?lat={latitude.ToString(CultureInfo.InvariantCulture)}" +
                $"&lon={longitude.ToString(CultureInfo.InvariantCulture)}" +
                "&limit=1&lang=en";

            try
            {
                using var doc = await GetPhotonAsync(url, ct);

                if (!doc.RootElement.TryGetProperty("features", out var features) ||
                    features.ValueKind != JsonValueKind.Array ||
                    features.GetArrayLength() == 0)
                {
                    return NotFound(new { message = "No address was found." });
                }

                if (!features[0].TryGetProperty("properties", out var properties))
                {
                    return NotFound(
                        new { message = "No readable address was found." });
                }

                var label = BuildLabel(properties);

                if (string.IsNullOrWhiteSpace(label))
                {
                    return NotFound(
                        new { message = "No readable address was found." });
                }

                return Json(new
                {
                    displayName = label,
                    latitude,
                    longitude
                });
            }
            catch (OperationCanceledException) when (ct.IsCancellationRequested)
            {
                return StatusCode(499);
            }
            catch (Exception ex) when (
                ex is HttpRequestException or
                      JsonException or
                      OperationCanceledException)
            {
                _logger.LogError(
                    ex,
                    "Reverse geocode failed for {Lat},{Lon}.",
                    latitude,
                    longitude);

                return StatusCode(
                    StatusCodes.Status502BadGateway,
                    new { message = "The location service is unavailable." });
            }
        }

        private async Task<JsonDocument> GetPhotonAsync(
            string url, CancellationToken ct)
        {
            var client = _httpClientFactory.CreateClient("photon");

            using var response = await client.GetAsync(url, ct);
            response.EnsureSuccessStatusCode();

            await using var stream =
                await response.Content.ReadAsStreamAsync(ct);

            return await JsonDocument.ParseAsync(
                stream,
                cancellationToken: ct);
        }

        private static string BuildLabel(JsonElement properties)
        {
            string? Get(string key) =>
                properties.TryGetProperty(key, out var value) &&
                value.ValueKind == JsonValueKind.String
                    ? value.GetString()
                    : null;

            var street = Get("street");
            var houseNumber = Get("housenumber");
            var streetLine = street is null
                ? null
                : houseNumber is null
                    ? street
                    : $"{houseNumber} {street}";

            var parts = new[]
            {
                Get("name"),
                streetLine,
                Get("district") ?? Get("locality"),
                Get("city"),
                Get("state"),
                Get("postcode"),
                Get("country")
            }
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Distinct(StringComparer.OrdinalIgnoreCase);

            return string.Join(", ", parts);
        }
        // Model binding turns empty fields into null, so be null-safe here.
        private static void NormalizeBooking(Booking booking)
        {
            booking.Name = booking.Name?.Trim() ?? string.Empty;
            booking.Phone = booking.Phone?.Trim() ?? string.Empty;
            booking.Email = booking.Email?.Trim() ?? string.Empty;
            booking.Location = booking.Location?.Trim() ?? string.Empty;
        }

        private void ValidateBooking(Booking booking)
        {
            // AcceptTerms is validated by the MustBeTrue attribute on Booking.

            if (!string.IsNullOrWhiteSpace(booking.Service) &&
                !BookingOptions.Services.Contains(booking.Service))
            {
                ModelState.AddModelError(
                    nameof(booking.Service),
                    "Please select a valid service.");
            }

            if (!string.IsNullOrWhiteSpace(booking.EventType) &&
                !BookingOptions.EventTypes.Contains(booking.EventType))
            {
                ModelState.AddModelError(
                    nameof(booking.EventType),
                    "Please select a valid event type.");
            }

            // [Phone] is very loose (it accepts almost anything with a digit),
            // so also require a realistic number of digits.
            var phoneDigits = booking.Phone?.Count(char.IsDigit) ?? 0;

            if (!string.IsNullOrWhiteSpace(booking.Phone) && phoneDigits is < 9 or > 15)
            {
                ModelState.AddModelError(
                    nameof(booking.Phone),
                    "Please enter a valid phone number (9 to 15 digits).");
            }

            // South Africa is UTC+2 year-round.
            var nowSast = DateTimeOffset.UtcNow.ToOffset(SastOffset);

            if (booking.Date.HasValue)
            {
                var bookingDate = booking.Date.Value.Date;

                if (bookingDate < nowSast.Date)
                {
                    ModelState.AddModelError(
                        nameof(booking.Date),
                        "The booking date cannot be in the past.");
                }
                else if (bookingDate == nowSast.Date &&
                         booking.StartTime.HasValue &&
                         booking.StartTime.Value <= nowSast.TimeOfDay)
                {
                    ModelState.AddModelError(
                        nameof(booking.StartTime),
                        "The start time has already passed today.");
                }
            }

            if (booking.StartTime.HasValue && booking.FinishTime.HasValue)
            {
                var duration = booking.FinishTime.Value - booking.StartTime.Value;

                if (duration <= TimeSpan.Zero)
                {
                    ModelState.AddModelError(
                        nameof(booking.FinishTime),
                        "The finish time must be later than the start time.");
                }
                else if (duration < MinimumDuration)
                {
                    ModelState.AddModelError(
                        nameof(booking.FinishTime),
                        "Bookings must be at least 1 hour long.");
                }
            }

            if (booking.Latitude is < -90 or > 90)
            {
                ModelState.AddModelError(
                    nameof(booking.Location),
                    "The selected location has an invalid latitude.");
            }

            if (booking.Longitude is < -180 or > 180)
            {
                ModelState.AddModelError(
                    nameof(booking.Location),
                    "The selected location has an invalid longitude.");
            }
        }
    }
}