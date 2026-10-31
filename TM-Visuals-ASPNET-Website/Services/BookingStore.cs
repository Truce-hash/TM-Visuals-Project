using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services
{
    /// <summary>
    /// In-memory stand-in for the database. Register as a singleton so the
    /// HomeController (Profile / BookingStatus) and BookingController share
    /// the same data. Replace with a Supabase-backed repository later.
    /// </summary>
    public class BookingStore
    {
        private readonly object _lock = new();
        private readonly List<Booking> _bookings;

        // Days the photographer is unavailable (holidays, leave, etc.).
        private readonly HashSet<DateTime> _blockedDates = new()
        {
            new DateTime(2026, 12, 25)
        };
        public BookingStore()
        {
            // Seed data moved here from HomeController.
            _bookings = new List<Booking>
            {
                new Booking
                {
                    Id = 1,
                    Name = "Musa Bonga",
                    Phone = "07123456789",
                    Email = "user@email.com",
                    Service = "Photography",
                    EventType = "Wedding",
                    NumberOfPeople = 25,
                    Location = "Johannesburg, Sandton",
                    Date = new DateTime(2026, 12, 14),
                    StartTime = new TimeSpan(11, 0, 0),
                    FinishTime = new TimeSpan(16, 0, 0),
                    Status = "Pending",
                    DeliveryLink = "https://example.com/wedding-gallery",

                },
                new Booking
                {
                    Id = 2,
                    Name = "Musa Bonga",
                    Phone = "07123456789",
                    Email = "user@email.com",
                    Service = "Video",
                    EventType = "Birthday Party",
                    NumberOfPeople = 40,
                    Location = "Cape Town",
                    Date = new DateTime(2026, 10, 30),
                    StartTime = new TimeSpan(13, 0, 0),
                    FinishTime = new TimeSpan(17, 0, 0),
                    Status = "Confirmed",
                    DeliveryLink = null,
                },
                new Booking
                {
                    Id = 3,
                    Name = "Thandi Mokoena",
                    Phone = "0821234567",
                    Email = "thandi@example.com",
                    Service = "Photography & Videography",
                    EventType = "Wedding",
                    NumberOfPeople = 120,
                    Budget = 25000m,
                    Location = "Bloem Hall, Bloemfontein",
                    Date = new DateTime(2026, 11, 20),
                    StartTime = new TimeSpan(7, 30, 0),
                    FinishTime = new TimeSpan(20, 30, 0),
                    AcceptTerms = true,
                    Status = "Confirmed"
                },
                new Booking
                {
                    Id = 4,
                    Name = "Sipho Dlamini",
                    Phone = "0739876543",
                    Email = "sipho@example.com",
                    Service = "Videography",
                    EventType = "Corporate Event",
                    NumberOfPeople = 60,
                    Budget = 8000m,
                    Location = "Windhoek Conference Centre, Bloemfontein",
                    Date = new DateTime(2026, 9, 19),
                    StartTime = new TimeSpan(9, 0, 0),
                    FinishTime = new TimeSpan(15, 0, 0),
                    AcceptTerms = true,
                    Status = "Confirmed",
                    DeliveryLink = "https://example.com/download-sipho"
                }
            };
        }
        public bool IsBlocked(DateTime date)
        {
            lock (_lock)
            {
                return _blockedDates.Contains(date.Date);
            }
        }
        /// <summary>Bookings on a date that still occupy the photographer's time.</summary>
        public List<Booking> BookingsOn(DateTime date)
        {
            lock (_lock)
            {
                return _bookings
                    .Where(b => b.Date?.Date == date.Date
                             && b.StartTime.HasValue
                             && b.FinishTime.HasValue
                             && b.Status != "Cancelled"
                             && b.Status != "Declined")
                    .ToList();
            }
        }
        public List<Booking> All()
        {
            lock (_lock)
            {
                return _bookings.ToList();
            }
        }

        public void Add(Booking booking)
        {
            lock (_lock)
            {
                booking.Id = _bookings.Count == 0 ? 1 : _bookings.Max(b => b.Id) + 1;
                _bookings.Add(booking);
            }
        }
    }
}