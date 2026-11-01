using System.Collections.Generic;

namespace TMVisualsWebApp.Models
{
    public class UserProfile
    {

        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? PhoneNumber { get; set;}
        public List<Booking> Bookings { get; set; } = new();
        public List<InvoiceDownload> Invoices { get; set; } = new();

    }
}
