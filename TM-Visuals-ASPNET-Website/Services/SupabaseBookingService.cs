using System.Globalization;
using System.Text.Json;
using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services;

public sealed class SupabaseBookingService(SupabaseApiClient api)
{
    public async Task<Guid> CreateAsync(Booking booking, CancellationToken cancellationToken = default)
    {
        if (booking.Date == null || booking.StartTime == null || booking.FinishTime == null)
            throw new ArgumentException("Choose a date and session times.");
        await api.RpcAsync("tmv_update_my_profile", new {
            p_full_name = booking.Name,
            p_phone = booking.Phone,
        }, authenticated: true, cancellationToken: cancellationToken);
        var result = await api.RpcAsync("tmv_create_public_booking", new {
            p_name = booking.Name,
            p_phone = booking.Phone,
            p_email = booking.Email,
            p_service = booking.Service,
            p_event_type = booking.EventType,
            p_date = booking.Date.Value.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
            p_start_time = booking.StartTime.Value.ToString(@"hh\:mm\:ss", CultureInfo.InvariantCulture),
            p_finish_time = booking.FinishTime.Value.ToString(@"hh\:mm\:ss", CultureInfo.InvariantCulture),
            p_location = booking.Location,
            p_number_of_people = booking.NumberOfPeople,
            p_budget = booking.Budget,
            p_requirements = booking.Requirements,
            p_accept_terms = booking.AcceptTerms,
        }, authenticated: true, cancellationToken: cancellationToken);
        return result.GetGuid();
    }

    public async Task CancelAsync(Guid id, CancellationToken cancellationToken = default) =>
        _ = await api.RpcAsync("tmv_cancel_my_booking", new { p_booking_id = id }, true, cancellationToken);

    public async Task<List<Booking>> FetchMineAsync(Guid? id = null, CancellationToken cancellationToken = default)
    {
        var rows = await api.RpcAsync("tmv_get_my_calendar_bookings", new { p_booking_id = id }, true, cancellationToken);
        return rows.EnumerateArray().Select(ReadBooking).ToList();
    }

    private static Booking ReadBooking(JsonElement row)
    {
        var slots = row.GetProperty("slots").EnumerateArray().ToList();
        var first = slots.FirstOrDefault();
        var last = slots.LastOrDefault();
        var booking = new Booking {
            Id = row.GetProperty("booking_id").GetGuid(), Name=Text(row,"full_name"),
            Email=Text(row,"email"), Phone=Text(row,"phone"), Service=Text(row,"services"),
            EventType=Text(row,"event_type"), Location=Text(row,"location"), Requirements=Text(row,"requirements"),
            Status=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(Text(row,"booking_status")),
            AcceptTerms=row.GetProperty("terms_accepted").GetBoolean(),
            Budget=Number(row,"budget"), NumberOfPeople=(int?)Number(row,"number_of_people"),
            CreatedAtUtc=DateTime.Parse(Text(row,"created_at"),CultureInfo.InvariantCulture,DateTimeStyles.AdjustToUniversal),
            DeliveryLink=Text(row,"delivery_link"),
        };
        if (slots.Count>0)
        {
            booking.Date=DateTime.Parse(Text(first,"slot_date"),CultureInfo.InvariantCulture);
            booking.StartTime=TimeSpan.Parse(Text(first,"start_time"),CultureInfo.InvariantCulture);
            booking.FinishTime=TimeSpan.Parse(Text(last,"end_time"),CultureInfo.InvariantCulture);
        }
        if (DateTimeOffset.TryParse(Text(row,"hold_expires_at"),CultureInfo.InvariantCulture,DateTimeStyles.None,out var expires))
            booking.ExpiresAtUtc=expires;
        return booking;
    }

    private static string Text(JsonElement row,string key) =>
        row.TryGetProperty(key,out var value) && value.ValueKind==JsonValueKind.String ? value.GetString()! : "";
    private static decimal? Number(JsonElement row,string key) =>
        row.TryGetProperty(key,out var value) && value.ValueKind==JsonValueKind.Number ? value.GetDecimal() : null;
}
