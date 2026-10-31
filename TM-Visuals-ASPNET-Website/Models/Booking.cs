using Microsoft.AspNetCore.Mvc.ModelBinding;
using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

namespace TMVisualsWebApp.Models
{
    public class Booking
    {
        public int Id { get; set; }

        [Required(ErrorMessage = "Please select a service.")]
        [Display(Name = "Service Type")]
        public string Service { get; set; } = string.Empty;

        [Required(ErrorMessage = "Please enter your full name.")]
        [StringLength(100)]
        [Display(Name = "Full Name")]
        public string Name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Please enter your phone number.")]
        [Phone(ErrorMessage = "Please enter a valid phone number.")]
        [StringLength(30, ErrorMessage = "The phone number is too long.")]
        [Display(Name = "Phone Number")]
        public string Phone { get; set; } = string.Empty;

        [Required(ErrorMessage = "Please enter your email address.")]
        [EmailAddress(ErrorMessage = "Please enter a valid email address.")]
        [StringLength(254, ErrorMessage = "The email address is too long.")]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Please select an event type.")]
        [Display(Name = "Type of Event")]
        public string EventType { get; set; } = string.Empty;

        [Required(ErrorMessage = "Please select a date.")]
        [DataType(DataType.Date)]
        public DateTime? Date { get; set; }

        [Required(ErrorMessage = "Please select a start time.")]
        [Display(Name = "Start Time")]
        public TimeSpan? StartTime { get; set; }

        [Required(ErrorMessage = "Please select a finish time.")]
        [Display(Name = "Finish Time")]
        public TimeSpan? FinishTime { get; set; }

        [Required(ErrorMessage = "Please enter the number of people.")]
        [Range(1, 10000, ErrorMessage = "The number of people must be at least 1.")]
        [Display(Name = "Number of People")]
        public int? NumberOfPeople { get; set; }

        [Required(ErrorMessage = "Please enter your estimated budget.")]
        [Range(typeof(decimal), "0.01", "99999999", ErrorMessage = "The budget must be greater than R0.")]
        public decimal? Budget { get; set; }

        [Required(ErrorMessage = "Please enter or select a location.")]
        [StringLength(300, ErrorMessage = "The location cannot exceed 300 characters.")]
        public string Location { get; set; } = string.Empty;

        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        [MustBeTrue(ErrorMessage = "You must accept the terms and conditions.")]
        public bool AcceptTerms { get; set; }

        [BindNever]
        public string Status { get; set; } = "Pending";

        [Url]
        public string? DeliveryLink { get; set; }
    }
}