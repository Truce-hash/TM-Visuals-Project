using System.ComponentModel.DataAnnotations;

namespace TMVisualsWebApp.Models.Account
{
    public class ForgotPasswordViewModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; } = string.Empty;
    }
}
