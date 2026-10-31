using System.ComponentModel.DataAnnotations;

namespace TMVisualsWebApp.Models
{
    public class Booking
    {
        public int Id { get; set; }
        public string Service { get; set; } = string.Empty;
        public string Name { get; set; } = string.Empty;
        public string Phone { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string EventType { get; set; } = string.Empty;
        public DateTime? Date { get; set; }
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? FinishTime { get; set; }
        public int? NumberOfPeople { get; set; }
        public decimal? Budget { get; set; }
        public string Location { get; set; } = string.Empty;
        // for location search
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public bool AcceptTerms { get; set; }
        public string Status { get; set; } = "Pending";

        //Client Content
        [Url]
        public string? DeliveryLink { get; set; }
    }
}