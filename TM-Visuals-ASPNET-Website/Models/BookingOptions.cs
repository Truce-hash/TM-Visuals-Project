namespace TMVisualsWebApp.Models
{
    /// <summary>
    /// Single source of truth for the Service and EventType dropdowns.
    /// The Create Booking view builds its options from these lists and the
    /// </summary>
    public static class BookingOptions
    {
        public static readonly IReadOnlyList<string> Services = new[]
        {
            "Photography",
            "Videography",
            "Photography & Videography"
        };

        public static readonly IReadOnlyList<string> EventTypes = new[]
        {
            "Graduation",
            "Wedding",
            "Birthday",
            "Corporate Event",
            "Portrait Shoot",
            "Other"
        };
    }
}

