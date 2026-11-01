using System.Net.Http.Headers;
using System.Text.Json;
using TMVisualsWebApp.Models;

namespace TMVisualsWebApp.Services
{
    public class ServicesCatalogService
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _configuration;

        public ServicesCatalogService(
            HttpClient httpClient,
            IConfiguration configuration)
        {
            _httpClient = httpClient;
            _configuration = configuration;
        }

        public async Task<List<ServiceItem>> FetchActiveServicesAsync(
            CancellationToken cancellationToken = default)
        {
            var supabaseUrl = _configuration["Supabase:Url"]?.TrimEnd('/');
            var publicKey = _configuration["Supabase:Key"]?.Trim();

            if (string.IsNullOrWhiteSpace(supabaseUrl) ||
                string.IsNullOrWhiteSpace(publicKey))
            {
                throw new InvalidOperationException(
                    "Supabase service configuration is missing.");
            }

            using var request = new HttpRequestMessage(
                HttpMethod.Get,
                $"{supabaseUrl}/rest/v1/service?select=service_name,description&is_active=eq.true&order=created_at.desc");
            request.Headers.TryAddWithoutValidation("apikey", publicKey);
            request.Headers.Authorization =
                new AuthenticationHeaderValue("Bearer", publicKey);

            using var response = await _httpClient.SendAsync(
                request,
                cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException(
                    $"Supabase service query returned HTTP {(int)response.StatusCode}.");
            }

            await using var stream = await response.Content.ReadAsStreamAsync(
                cancellationToken);
            using var document = await JsonDocument.ParseAsync(
                stream,
                cancellationToken: cancellationToken);

            if (document.RootElement.ValueKind != JsonValueKind.Array)
            {
                throw new JsonException(
                    "Supabase returned an unexpected services response.");
            }

            return document.RootElement
                .EnumerateArray()
                .Select(service => new ServiceItem
                {
                    Name = ReadString(service, "service_name"),
                    Description = ReadString(service, "description")
                })
                .ToList();
        }

        private static string ReadString(JsonElement element, string propertyName) =>
            element.TryGetProperty(propertyName, out var value) &&
            value.ValueKind == JsonValueKind.String
                ? value.GetString() ?? string.Empty
                : string.Empty;
    }
}
