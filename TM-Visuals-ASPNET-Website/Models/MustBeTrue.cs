using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Mvc.ModelBinding.Validation;

namespace TMVisualsWebApp.Models
{
    /// <summary>
    /// Requires a bool to be true (e.g. "accept terms" checkboxes).
    /// Works on the server and, with the small script in Create.cshtml, in the browser.
    /// </summary>
    [AttributeUsage(AttributeTargets.Property)]
    public sealed class MustBeTrueAttribute : ValidationAttribute, IClientModelValidator
    {
        public override bool IsValid(object? value) => value is bool accepted && accepted;

        public void AddValidation(ClientModelValidationContext context)
        {
            Merge(context.Attributes, "data-val", "true");
            Merge(context.Attributes, "data-val-mustbetrue",
                FormatErrorMessage(context.ModelMetadata.GetDisplayName()));
        }
        private static void Merge(IDictionary<string, string> attributes, string key, string value)
        {
            if (!attributes.ContainsKey(key))
            {
                attributes.Add(key, value);
            }
        }
    }
}