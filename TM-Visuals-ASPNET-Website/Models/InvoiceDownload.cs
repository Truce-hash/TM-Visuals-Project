namespace TMVisualsWebApp.Models
{
    public sealed class InvoiceDownload
    {
        public string Id { get; set; } = string.Empty;
        public string Reference { get; set; } = string.Empty;
        public string FilePath { get; set; } = string.Empty;
        public DateTime? CreatedAt { get; set; }
        public string ClientEmail { get; set; } = string.Empty;
    }
}
