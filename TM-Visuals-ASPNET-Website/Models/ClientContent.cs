namespace TMVisualsWebApp.Models
{
    public enum ContentAccessStatus
    {
        Pending,
        Available,
        Expired
    }
    /// <summary>
    /// A read-only view of a Booking for the "My Content" page.
    /// Nothing is copied: every value is read from the booking itself.
    /// </summary>
    public class ClientContent
    {
        public ClientContent(Booking booking)
        {
            Booking = booking;
        }
        public Booking Booking { get; }
        public int BookingId => Booking.Id;
        public string EventType => Booking.EventType;
        public string Location => Booking.Location;
        public DateTime BookingDate => Booking.Date ?? default;
        public TimeSpan? StartTime => Booking.StartTime;
        public TimeSpan? FinishTime => Booking.FinishTime;
        public string? DeliveryLink => Booking.DeliveryLink;

        // "Photography & Videography" shows as two badges.
        public IReadOnlyList<string> Services =>
            Booking.Service.Split(" & ",
                StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

        // Worked out from the booking, not stored, so it can't go out of date.
        public ContentAccessStatus AccessStatus =>
            string.IsNullOrWhiteSpace(Booking.DeliveryLink)
                ? ContentAccessStatus.Pending
                : ContentAccessStatus.Available;
    }
}