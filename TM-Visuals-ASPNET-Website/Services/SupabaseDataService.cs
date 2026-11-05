using System.Globalization;
using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services
{
    /// <summary>One bookable time slot from the get_booking_calendar function.</summary>
    public sealed record CalendarSlot(
        Guid Id,
        DateOnly Date,
        TimeSpan Start,
        TimeSpan End,
        bool Available);

    /// <summary>The booking details sent to create_booking_request.</summary>
    public sealed record BookingRequest(
        IReadOnlyList<Guid> TimeSlotIds,
        IReadOnlyList<Guid> ServiceIds,
        string EventType,
        decimal? Budget,
        string? Requirements,
        int? NumberOfPeople,
        string Location,
        bool TermsAccepted,
        double? Latitude,
        double? Longitude);

    public sealed record SupabaseProfile(string FullName, string Email, string? Phone);

    /// <summary>A rejected Supabase request. Message is Supabase's own message.</summary>
    public sealed class SupabaseDataException : Exception
    {
        public int StatusCode { get; }

        public SupabaseDataException(string message, int statusCode)
            : base(message)
        {
            StatusCode = statusCode;
        }
    }

    /// <summary>
    /// Talks to the database through Supabase's REST API. Anything that depends
    /// on who is signed in passes that user's access token, so the database
    /// functions and row-level security see the real user.
    /// </summary>
    public sealed class SupabaseDataService
    {
        // One booking with everything the pages need, in a single request.
        private const string BookingSelect =
            "booking_id,booking_status,event_type,budget,requirements," +
            "number_of_people,location,latitude,longitude,terms_accepted," +
            "created_at,hold_expires_at," +
            "client:client_id(user_id,user:user_id(full_name,email,phone))," +
            "booking_slot(selection_status,time_slot:time_slot_id(slot_date,start_time,end_time))," +
            "booking_service(service:service_id(service_name))," +
            "client_content(delivery_link,access_status,uploaded_at)";

        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public SupabaseDataService(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }

        // ---------------------------------------------------------------
        // Calendar and services (signed-in users)
        // ---------------------------------------------------------------

        public async Task<List<CalendarSlot>> GetCalendarAsync(
            string accessToken,
            DateOnly from,
            DateOnly to,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Post,
                "rpc/get_booking_calendar",
                accessToken,
                new
                {
                    p_start_date = from.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                    p_end_date = to.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)
                },
                cancellationToken);

            if (document.RootElement.ValueKind != JsonValueKind.Array)
            {
                throw new JsonException("Supabase returned an unexpected calendar response.");
            }

            var slots = new List<CalendarSlot>();
            foreach (var row in document.RootElement.EnumerateArray())
            {
                slots.Add(new CalendarSlot(
                    Guid.Parse(row.GetProperty("time_slot_id").GetString()!),
                    DateOnly.ParseExact(
                        row.GetProperty("slot_date").GetString()!,
                        "yyyy-MM-dd",
                        CultureInfo.InvariantCulture),
                    TimeSpan.Parse(
                        row.GetProperty("start_time").GetString()!,
                        CultureInfo.InvariantCulture),
                    TimeSpan.Parse(
                        row.GetProperty("end_time").GetString()!,
                        CultureInfo.InvariantCulture),
                    row.GetProperty("is_available").GetBoolean()));
            }

            return slots;
        }

        /// <summary>
        /// Turns the service shown on the form ("Photography", or
        /// "Photography &amp; Videography") into the service ids the database uses.
        /// </summary>
        public async Task<List<Guid>> ResolveServiceIdsAsync(
            string accessToken,
            string serviceLabel,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Get,
                "tmv_service?select=service_id,service_name&is_active=eq.true",
                accessToken,
                body: null,
                cancellationToken);

            var byName = new Dictionary<string, Guid>(StringComparer.OrdinalIgnoreCase);
            foreach (var row in document.RootElement.EnumerateArray())
            {
                var name = ReadString(row, "service_name");
                var id = ReadString(row, "service_id");
                if (name.Length > 0 && Guid.TryParse(id, out var serviceId))
                {
                    byName[name.Trim()] = serviceId;
                }
            }

            // A service whose own name contains " & " (e.g. "Hair & Makeup") has to
            // match as a whole before we try splitting a combined label.
            if (byName.TryGetValue(serviceLabel.Trim(), out var exactId))
            {
                return new List<Guid> { exactId };
            }

            var ids = new List<Guid>();
            var wanted = serviceLabel.Split(
                " & ",
                StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

            foreach (var name in wanted)
            {
                if (!byName.TryGetValue(name, out var id))
                {
                    throw new SupabaseDataException(
                        $"The service '{name}' is not available right now.",
                        400);
                }

                ids.Add(id);
            }

            return ids;
        }

        // ---------------------------------------------------------------
        // Bookings (signed-in user)
        // ---------------------------------------------------------------

        public async Task<Guid> CreateBookingAsync(
            string accessToken,
            BookingRequest request,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Post,
                "rpc/create_booking_request",
                accessToken,
                new
                {
                    p_time_slot_ids = request.TimeSlotIds,
                    p_service_ids = request.ServiceIds,
                    p_event_type = request.EventType,
                    p_budget = request.Budget,
                    p_requirements = request.Requirements,
                    p_number_of_people = request.NumberOfPeople,
                    p_location = request.Location,
                    p_terms_accepted = request.TermsAccepted,
                    p_latitude = request.Latitude,
                    p_longitude = request.Longitude
                },
                cancellationToken);

            if (document.RootElement.ValueKind == JsonValueKind.String &&
                Guid.TryParse(document.RootElement.GetString(), out var bookingId))
            {
                return bookingId;
            }

            throw new JsonException("Supabase returned no booking id.");
        }

        /// <summary>The signed-in user's bookings, newest first.</summary>
        public async Task<List<Booking>> GetMyBookingsAsync(
            string accessToken,
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Get,
                $"booking?select={Uri.EscapeDataString(BookingSelect)}&order=created_at.desc",
                accessToken,
                body: null,
                cancellationToken);

            // Row-level security already limits this to the user's own bookings
            // (or everything, for an admin), so also filter to the user here.
            return document.RootElement
                .EnumerateArray()
                .Select(ParseBooking)
                .Where(booking => booking.UserId == userId)
                .ToList();
        }

        public async Task<Booking?> GetMyBookingAsync(
            string accessToken,
            Guid userId,
            Guid bookingId,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Get,
                $"booking?select={Uri.EscapeDataString(BookingSelect)}&booking_id=eq.{bookingId}",
                accessToken,
                body: null,
                cancellationToken);

            return document.RootElement
                .EnumerateArray()
                .Select(ParseBooking)
                .FirstOrDefault(booking => booking.UserId == userId);
        }

        public async Task CancelBookingAsync(
            string accessToken,
            Guid bookingId,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Post,
                "rpc/tmv_cancel_my_booking",
                accessToken,
                new { p_booking_id = bookingId },
                cancellationToken);
        }

        // ---------------------------------------------------------------
        // Profile (signed-in user)
        // ---------------------------------------------------------------

        public async Task<SupabaseProfile?> GetMyProfileAsync(
            string accessToken,
            Guid userId,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Get,
                $"tmv_user?select=full_name,email,phone&auth_user_id=eq.{userId}",
                accessToken,
                body: null,
                cancellationToken);

            foreach (var row in document.RootElement.EnumerateArray())
            {
                var phone = ReadString(row, "phone");
                return new SupabaseProfile(
                    ReadString(row, "full_name"),
                    ReadString(row, "email"),
                    phone.Length == 0 ? null : phone);
            }

            return null;
        }

        public async Task UpdateMyProfileAsync(
            string accessToken,
            string fullName,
            string? phone,
            CancellationToken cancellationToken = default)
        {
            using var document = await SendAsync(
                HttpMethod.Post,
                "rpc/tmv_update_my_profile",
                accessToken,
                new { p_full_name = fullName, p_phone = phone },
                cancellationToken);
        }

        // ---------------------------------------------------------------
        // Mapping a database booking onto the app's Booking model
        // ---------------------------------------------------------------

        private static Booking ParseBooking(JsonElement row)
        {
            var client = FirstObject(row, "client");
            var user = client is null ? null : FirstObject(client.Value, "user");

            // Date and times come from the booking's time slots. Prefer the
            // selected ones; a cancelled booking only has cancelled slots left.
            var slots = new List<(string Status, DateOnly Date, TimeSpan Start, TimeSpan End)>();
            if (row.TryGetProperty("booking_slot", out var slotRows) &&
                slotRows.ValueKind == JsonValueKind.Array)
            {
                foreach (var slotRow in slotRows.EnumerateArray())
                {
                    var slot = FirstObject(slotRow, "time_slot");
                    if (slot is null)
                    {
                        continue;
                    }

                    slots.Add((
                        ReadString(slotRow, "selection_status"),
                        DateOnly.ParseExact(
                            ReadString(slot.Value, "slot_date"),
                            "yyyy-MM-dd",
                            CultureInfo.InvariantCulture),
                        TimeSpan.Parse(
                            ReadString(slot.Value, "start_time"),
                            CultureInfo.InvariantCulture),
                        TimeSpan.Parse(
                            ReadString(slot.Value, "end_time"),
                            CultureInfo.InvariantCulture)));
                }
            }

            var shown = slots.Where(slot => slot.Status == "selected").ToList();
            if (shown.Count == 0)
            {
                shown = slots;
            }

            DateTime? date = null;
            TimeSpan? start = null;
            TimeSpan? finish = null;
            if (shown.Count > 0)
            {
                var day = shown.Min(slot => slot.Date);
                var daySlots = shown.Where(slot => slot.Date == day).ToList();
                date = day.ToDateTime(TimeOnly.MinValue);
                start = daySlots.Min(slot => slot.Start);
                finish = daySlots.Max(slot => slot.End);
            }

            var serviceNames = new List<string>();
            if (row.TryGetProperty("booking_service", out var serviceRows) &&
                serviceRows.ValueKind == JsonValueKind.Array)
            {
                foreach (var serviceRow in serviceRows.EnumerateArray())
                {
                    var service = FirstObject(serviceRow, "service");
                    var name = service is null ? string.Empty : ReadString(service.Value, "service_name");
                    if (name.Length > 0)
                    {
                        serviceNames.Add(name);
                    }
                }
            }
            serviceNames.Sort(StringComparer.OrdinalIgnoreCase);

            // The newest active delivery link, if any.
            string? deliveryLink = null;
            if (row.TryGetProperty("client_content", out var contentRows) &&
                contentRows.ValueKind == JsonValueKind.Array)
            {
                deliveryLink = contentRows
                    .EnumerateArray()
                    .Where(content => ReadString(content, "access_status") == "active")
                    .OrderByDescending(content => ReadString(content, "uploaded_at"))
                    .Select(content => ReadString(content, "delivery_link"))
                    .FirstOrDefault(link => link.Length > 0);
            }

            var status = ReadString(row, "booking_status");

            return new Booking
            {
                Id = Guid.Parse(ReadString(row, "booking_id")),
                UserId = client is not null && Guid.TryParse(ReadString(client.Value, "user_id"), out var userId)
                    ? userId
                    : null,
                Name = user is null ? string.Empty : ReadString(user.Value, "full_name"),
                Email = user is null ? string.Empty : ReadString(user.Value, "email"),
                Phone = user is null ? string.Empty : ReadString(user.Value, "phone"),
                Service = string.Join(" & ", serviceNames),
                EventType = ReadString(row, "event_type"),
                Date = date,
                StartTime = start,
                FinishTime = finish,
                NumberOfPeople = ReadInt(row, "number_of_people"),
                Budget = ReadDecimal(row, "budget"),
                Location = ReadString(row, "location"),
                Latitude = ReadDouble(row, "latitude"),
                Longitude = ReadDouble(row, "longitude"),
                AcceptTerms = row.TryGetProperty("terms_accepted", out var terms) &&
                              terms.ValueKind == JsonValueKind.True,
                Status = status.Length == 0
                    ? "Pending"
                    : char.ToUpperInvariant(status[0]) + status[1..],
                DeliveryLink = deliveryLink,
                CreatedAtUtc = ReadDate(row, "created_at")?.UtcDateTime ?? default,
                ExpiresAtUtc = ReadDate(row, "hold_expires_at") ?? default
            };
        }

        // ---------------------------------------------------------------
        // HTTP and JSON helpers
        // ---------------------------------------------------------------

        private async Task<JsonDocument> SendAsync(
            HttpMethod method,
            string path,
            string? accessToken,
            object? body,
            CancellationToken cancellationToken)
        {
            var url = _configuration["Supabase:Url"]?.TrimEnd('/');
            var key = _configuration["Supabase:Key"]?.Trim();

            if (string.IsNullOrWhiteSpace(url) || string.IsNullOrWhiteSpace(key))
            {
                throw new InvalidOperationException("Supabase is not configured.");
            }

            using var request = new HttpRequestMessage(method, $"{url}/rest/v1/{path}");
            request.Headers.TryAddWithoutValidation("apikey", key);

            // Signed-in requests carry the user's token. Public requests send
            // only the project key and run as the anonymous role.
            if (!string.IsNullOrWhiteSpace(accessToken))
            {
                request.Headers.Authorization =
                    new AuthenticationHeaderValue("Bearer", accessToken);
            }

            if (body is not null)
            {
                request.Content = new StringContent(
                    JsonSerializer.Serialize(body),
                    Encoding.UTF8,
                    "application/json");
            }

            var client = _httpClientFactory.CreateClient("SupabaseData");
            using var response = await client.SendAsync(request, cancellationToken);
            var text = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                throw new SupabaseDataException(
                    ReadErrorMessage(text, (int)response.StatusCode),
                    (int)response.StatusCode);
            }

            // Functions that return nothing send an empty body.
            return JsonDocument.Parse(string.IsNullOrWhiteSpace(text) ? "null" : text);
        }

        private static string ReadErrorMessage(string body, int statusCode)
        {
            try
            {
                using var document = JsonDocument.Parse(body);
                if (document.RootElement.ValueKind == JsonValueKind.Object &&
                    document.RootElement.TryGetProperty("message", out var message) &&
                    message.ValueKind == JsonValueKind.String)
                {
                    return message.GetString() ?? $"HTTP {statusCode}";
                }
            }
            catch (JsonException)
            {
            }

            return $"HTTP {statusCode}";
        }

        // An embedded record comes back as an object, or as a one-item array
        // depending on how the relationship is detected. Handle both.
        private static JsonElement? FirstObject(JsonElement parent, string name)
        {
            if (parent.ValueKind != JsonValueKind.Object ||
                !parent.TryGetProperty(name, out var value))
            {
                return null;
            }

            if (value.ValueKind == JsonValueKind.Object)
            {
                return value;
            }

            if (value.ValueKind == JsonValueKind.Array)
            {
                foreach (var item in value.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Object)
                    {
                        return item;
                    }
                }
            }

            return null;
        }

        private static string ReadString(JsonElement element, string name) =>
            element.ValueKind == JsonValueKind.Object &&
            element.TryGetProperty(name, out var value) &&
            value.ValueKind == JsonValueKind.String
                ? value.GetString() ?? string.Empty
                : string.Empty;

        private static int? ReadInt(JsonElement element, string name) =>
            element.TryGetProperty(name, out var value) &&
            value.ValueKind == JsonValueKind.Number &&
            value.TryGetInt32(out var number)
                ? number
                : null;

        private static decimal? ReadDecimal(JsonElement element, string name) =>
            element.TryGetProperty(name, out var value) &&
            value.ValueKind == JsonValueKind.Number &&
            value.TryGetDecimal(out var number)
                ? number
                : null;

        private static double? ReadDouble(JsonElement element, string name) =>
            element.TryGetProperty(name, out var value) &&
            value.ValueKind == JsonValueKind.Number &&
            value.TryGetDouble(out var number)
                ? number
                : null;

        private static DateTimeOffset? ReadDate(JsonElement element, string name) =>
            element.TryGetProperty(name, out var value) &&
            value.ValueKind == JsonValueKind.String &&
            value.TryGetDateTimeOffset(out var date)
                ? date
                : null;
    }
}