using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Supabase.Extensions.DependencyInjection;
using TMVisualsWebApp.Data;
using TMVisualsWebApp.Models;
using TMVisualsWebApp.Services;


var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddDatabaseDeveloperPageExceptionFilter();
builder.Services.AddDbContext<TMVisualsDBContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("SupabaseConnection")));

//builder.Services.AddDefaultIdentity<IdentityUser>(options => options.SignIn.RequireConfirmedAccount = true)
    //.AddEntityFrameworkStores<ApplicationDbContext>();
builder.Services.AddControllersWithViews();


builder.Services.AddSupabase(
    builder.Configuration["Supabase:Url"]!,
    builder.Configuration["Supabase:Key"]!
);
// Registers Supabase.Client and each of its sub-clients (Auth, Postgrest,
// Storage, Functions, Realtime) in the DI container, backed by pooled HttpClients from IHttpClientFactory.
// Blazor registers the client the same way: use this in your Blazor Server /
// Web App Program.cs, or WebAssemblyHostBuilder.CreateDefault(args) for a
// Blazor WebAssembly client.

builder.Services.AddHttpClient("SupabaseAuth");

builder.Services
    .AddAuthentication(CookieAuthenticationDefaults.AuthenticationScheme)
    .AddCookie(options =>
    {
        options.LoginPath = "/Account/Login";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.Cookie.HttpOnly = true;
        options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
        options.SlidingExpiration = true;
    });

//added this cause i can't test the website 
builder.Services.AddHttpClient<PortfolioCatalogService>(client =>
{
    client.BaseAddress = new Uri("https://YOUR-SUPABASE-URL/");   // adjust to your real endpoint
});

builder.Services.AddAuthorization();

//Services for the location search
builder.Services.AddControllersWithViews();
builder.Services.AddHttpClient("photon", client =>
{
    client.BaseAddress = new Uri("https://photon.komoot.io/");
    client.Timeout = TimeSpan.FromSeconds(8);
    client.DefaultRequestHeaders.UserAgent.ParseAdd("TMVisualsWebApp/1.0");
});

//availability and booking store
builder.Services.AddSingleton<BookingStore>();
builder.Services.AddSingleton<BookingAvailabilityService>();

var app = builder.Build();

//For budget, location South African
var culture = new System.Globalization.CultureInfo("en-GB");
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new Microsoft.AspNetCore.Localization.RequestCulture(culture),
    SupportedCultures = new[] { culture },
    SupportedUICultures = new[] { culture }
});

//Middleware Pipeline
app.MapGet("/todos", async (Supabase.Client supabase) =>
{
        await supabase.InitializeAsync();
        var response = await supabase.From<Todo>().Get();
        return response.Models;
    });

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseRouting();

app.UseAuthorization();

app.MapStaticAssets();

app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}")
    .WithStaticAssets();


app.UseAuthentication();
app.UseAuthorization();


app.Run();
