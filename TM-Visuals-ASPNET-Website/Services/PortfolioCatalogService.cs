using System.Net.Http.Headers;
using System.Text.Json;
using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services
{
    public class PortfolioCatalogService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public PortfolioCatalogService(
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task<List<PortfolioItem>> FetchPublicItemsAsync(
            CancellationToken cancellationToken = default)
        {
            var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
            var publicKey = _configuration["Supabase:Key"]?.Trim();

            if (string.IsNullOrWhiteSpace(supabaseUrl) ||
                string.IsNullOrWhiteSpace(publicKey))
            {
                throw new InvalidOperationException(
                    "Supabase portfolio configuration is missing.");
            }
            if (IsServiceRoleKey(publicKey))
            {
                throw new InvalidOperationException(
                    "Use a Supabase publishable or anon key for public portfolio reads.");
            }

            var selection = Uri.EscapeDataString(
                "title,media_location,media_type,category:tmv_portfolio_category(category_name)");
            using var request = new HttpRequestMessage(
                HttpMethod.Get,
                $"{supabaseUrl}/rest/v1/tmv_portfolio_item?select={selection}");
            request.Headers.TryAddWithoutValidation("apikey", publicKey);
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", publicKey);

            using var response = await _httpClient.SendAsync(
                request,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Supabase portfolio query returned HTTP {(int)response.StatusCode}.");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(
                cancellationToken);
            using var document = await JsonDocument.ParseAsync(
                stream,
                cancellationToken: cancellationToken);

            if (document.RootElement.ValueKind != JsonValueKind.Array)
            {
                throw new JsonException(
                    "Supabase returned an unexpected portfolio response.");
            }

            return document.RootElement
                .EnumerateArray()
                .Select(ParseItem)
                .ToList();
        }

        private static PortfolioItem ParseItem(JsonElement item)
        {
            var category = item.TryGetProperty("category", out var categoryElement)
                ? categoryElement
                : default;
            if (category.ValueKind == JsonValueKind.Array)
            {
                category = category.EnumerateArray().FirstOrDefault();
            }

            var categoryName = category.ValueKind == JsonValueKind.Object &&
                              category.TryGetProperty("category_name", out var name)
                ? name.GetString() ?? string.Empty
                : string.Empty;

            return new PortfolioItem
            {
                Title = ReadString(item, "title"),
                ImageUrl = ReadString(item, "media_location"),
                MediaType = ReadString(item, "media_type"),
                Category = categoryName
            };
        }

        private static string ReadString(JsonElement element, string propertyName) =>
            element.TryGetProperty(propertyName, out var value) &&
            value.ValueKind == JsonValueKind.String
                ? value.GetString() ?? string.Empty
                : string.Empty;

        private static bool IsServiceRoleKey(string key)
        {
            if (key.StartsWith("sb_secret_", StringComparison.Ordinal))
            {
                return true;
            }

            var segments = key.Split('.');
            if (segments.Length != 3)
            {
                return false;
            }

            try
            {
                var payload = segments[1].Replace('-', '+').Replace('_', '/');
                payload = payload.PadRight(payload.Length + (4 - payload.Length % 4) % 4, '=');
                using var document = JsonDocument.Parse(
                    Convert.FromBase64String(payload));
                return document.RootElement.TryGetProperty("role", out var role) &&
                       role.ValueKind == JsonValueKind.String &&
                       role.GetString() == "service_role";
            }
            catch (FormatException)
            {
                return false;
            }
            catch (JsonException)
            {
                return false;
            }
        }
    }
}
