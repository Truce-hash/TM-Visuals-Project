using System.ComponentModel.DataAnnotations;

namespace TMVisualsWebApp.Models.Account
{
    public class ResetPasswordViewModel
    {
        [Required]
        [StringLength(4096)]
        public string AccessToken { get; set; } = string.Empty;

        [Required]
        [MinLength(8)]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        [Compare(nameof(Password), ErrorMessage = "Passwords do not match.")]
        [Display(Name = "Confirm password")]
        public string ConfirmPassword { get; set; } = string.Empty;
    }
}
