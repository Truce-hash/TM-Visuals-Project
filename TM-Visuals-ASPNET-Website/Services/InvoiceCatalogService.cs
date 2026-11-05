using System.Text;
using System.Text.Json;
using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services
{
    public sealed class InvoiceCatalogService
    {
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IConfiguration _configuration;

        public InvoiceCatalogService(
            IHttpClientFactory httpClientFactory,
            IConfiguration configuration)
        {
            _httpClientFactory = httpClientFactory;
            _configuration = configuration;
        }


        public async Task<IReadOnlyList<InvoiceDownload>> FetchForClientAsync(
            string email,
            CancellationToken cancellationToken = default,
            string? accessToken = null)
        {
            if (string.IsNullOrWhiteSpace(email))
            {
                return Array.Empty<InvoiceDownload>();
            }

            if (!TryGetSettings(out var url, out var key))
            {
                throw new InvalidOperationException("Supabase is not configured.");
            }

            var client = _httpClientFactory.CreateClient("SupabaseInvoice");
            var request = new HttpRequestMessage(
                HttpMethod.Post,
                $"{url}/rest/v1/rpc/tmv_get_my_invoices");
            AddSupabaseHeaders(request, key, accessToken);
            request.Content = new StringContent("{}", Encoding.UTF8, "application/json");

            using var response = await client.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Supabase invoice query returned HTTP {(int)response.StatusCode}: {body}");
            }

            using var document = JsonDocument.Parse(body);
            var invoices = new List<InvoiceDownload>();
            foreach (var row in document.RootElement.EnumerateArray())
            {
                var clientEmail = GetString(row, "client_email");
                if (!string.Equals(clientEmail, email, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var filePath = GetString(row, "file_path");
                if (string.IsNullOrWhiteSpace(filePath))
                {
                    continue;
                }

                invoices.Add(new InvoiceDownload
                {
                    Id = GetString(row, "invoice_id"),
                    Reference = GetString(row, "reference"),
                    FilePath = filePath,
                    CreatedAt = ParseDate(GetString(row, "created_at")),
                    ClientEmail = clientEmail
                });
            }

            return invoices
                .OrderByDescending(invoice => invoice.CreatedAt)
                .ThenBy(invoice => invoice.Reference)
                .ToList();
        }

        public async Task<string> CreateSignedDownloadUrlAsync(
            string filePath,
            string fileName,
            CancellationToken cancellationToken = default,
            string? accessToken = null)
        {
            if (!TryGetSettings(out var url, out var key))
            {
                throw new InvalidOperationException("Supabase is not configured.");
            }

            var encodedPath = string.Join("/", filePath
                .Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Select(Uri.EscapeDataString));
            var client = _httpClientFactory.CreateClient("SupabaseInvoice");
            var request = new HttpRequestMessage(
                HttpMethod.Post,
                $"{url}/storage/v1/object/sign/invoices/{encodedPath}");
            AddSupabaseHeaders(request, key, accessToken);
            request.Content = new StringContent(
                JsonSerializer.Serialize(new { expiresIn = 300 }),
                Encoding.UTF8,
                "application/json");

            using var response = await client.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Supabase storage sign returned HTTP {(int)response.StatusCode}: {body}");
            }

            using var document = JsonDocument.Parse(body);
            var signedPath = document.RootElement.TryGetProperty("signedURL", out var signedUrl)
                ? signedUrl.GetString()
                : document.RootElement.TryGetProperty("signedUrl", out var signedUrlLower)
                    ? signedUrlLower.GetString()
                    : null;

            if (string.IsNullOrWhiteSpace(signedPath))
            {
                throw new InvalidOperationException("Supabase returned no signed invoice URL.");
            }

            var downloadUrl = signedPath.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
                              signedPath.StartsWith("https://", StringComparison.OrdinalIgnoreCase)
                ? new Uri(signedPath)
                : signedPath.StartsWith("/storage/v1/", StringComparison.OrdinalIgnoreCase)
                    ? new Uri($"{url}{signedPath}")
                    : new Uri($"{url}/storage/v1{signedPath}");
            var separator = downloadUrl.Query.Length == 0 ? "?" : "&";
            var downloadName = Path.GetFileNameWithoutExtension(fileName) + ".pdf";
            return $"{downloadUrl}{separator}download={Uri.EscapeDataString(downloadName)}";
        }

        // With the signed-in user's token, row-level security returns only that
        // user's invoices. Without it the request runs as the anonymous role.
        private static void AddSupabaseHeaders(
            HttpRequestMessage request,
            string key,
            string? accessToken = null)
        {
            request.Headers.Add("apikey", key);
            request.Headers.Add(
                "Authorization",
                $"Bearer {(string.IsNullOrWhiteSpace(accessToken) ? key : accessToken)}");
        }

        private bool TryGetSettings(out string url, out string key)
        {
            url = _configuration["Supabase:Url"]?.TrimEnd('/') ?? string.Empty;
            key = _configuration["Supabase:Key"]?.Trim() ?? string.Empty;
            return !string.IsNullOrWhiteSpace(url) && !string.IsNullOrWhiteSpace(key);
        }

        private static string GetString(JsonElement element, string propertyName)
        {
            return element.TryGetProperty(propertyName, out var value)
                ? value.GetString() ?? string.Empty
                : string.Empty;
        }

        private static DateTime? ParseDate(string value)
        {
            return DateTime.TryParse(value, out var date) ? date : null;
        }
    }
}
