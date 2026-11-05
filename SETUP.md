# Run TM Visuals

This setup launches the client website and the Flutter admin app's web preview on your computer. Both connect to the Supabase project in your local configuration. Changes made while using them affect that project's data.

## Install once

1. Install the [.NET 9 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/9.0). The website targets `net9.0`; a newer SDK also works if the .NET 9 and ASP.NET Core 9 runtimes are installed.
2. Install [Flutter](https://docs.flutter.dev/install) and add its `bin` folder to `PATH`. The app requires a Flutter SDK containing Dart 3.9.2 or newer, compatible with its `pubspec.yaml` constraints.
3. Install Git and a supported browser such as Chrome or Edge. VS Code is optional.
4. Clone/download this repository, extract it to a normal local folder if needed, and open a new PowerShell window in the repository root.

Confirm the tools are available:

```powershell
dotnet --list-sdks
dotnet --list-runtimes
flutter doctor
```

Trust the website's local HTTPS certificate once:

```powershell
dotnet dev-certs https --trust
```

Accept the Windows certificate prompt. This is the standard [.NET development certificate setup](https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-dev-certs).

The launcher uses Windows PowerShell, which is included with Windows. It applies the execution-policy option only to its own process; it does not change your system-wide policy. If your organization blocks scripts, ask its administrator rather than changing managed policies.

## Configure Supabase 

Both projects use this same file:

```text
TM-Visuals-Flutter-App/config/supabase.local.json
```

If it already contains your settings, keep it. Otherwise, from the repository root:

```powershell
$configPath = '.\TM-Visuals-Flutter-App\config\supabase.local.json'
if (-not (Test-Path $configPath)) {
    Copy-Item .\TM-Visuals-Flutter-App\config\supabase.example.json $configPath
}
notepad $configPath
```

Fill in the project's values, preserving valid JSON:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_PUBLISHABLE_KEY"
}
```

## Launch and stop

Double-click **Start-TM-Visuals.cmd** in the repository root. It restores dependencies, builds both projects, starts their development servers in the background, and opens your default browser after the website responds and Flutter's compiled JavaScript is available. Allow a few minutes on the first run and keep an internet connection available for dependency downloads and Supabase.

| Application | Address | Sign in as |
|---|---|---|
| Client website | https://localhost:7139 | A client account |
| Flutter admin web preview | http://localhost:5191 | An administrator account |

Double-click **Stop-TM-Visuals.cmd** when finished. Closing browser tabs does not stop the servers. Stop and start again after changing the source code or Supabase configuration. Running Start again while the launcher already owns the servers reuses them; it does not rebuild them.

To launch only one project, or check setup without starting anything, use PowerShell from the root:

```powershell
.\Start-TM-Visuals.cmd -Target Website
.\Start-TM-Visuals.cmd -Target App
.\Start-TM-Visuals.cmd -Check
```

For a terminal-only launch without opening browser tabs:

```powershell
.\Start-TM-Visuals.cmd -NoBrowser
```

## Logs and common problems

Logs and process records are saved in the ignored `.local-run` folder:

- `website.log` and `website.error.log`
- `app.log` and `app.error.log`

| Problem | What to do |
|---|---|
| Missing configuration or placeholder key | Complete `config/supabase.local.json` using the project URL and public key. |
| `dotnet` or `flutter` is not found | Install the SDK, add it to `PATH`, and reopen PowerShell/Explorer before retrying. |
| HTTPS certificate check fails | Run `dotnet dev-certs https --trust` once and accept the prompt. |
| Port already in use | Stop any earlier `dotnet run`/`flutter run` terminals with Ctrl+C. The launcher deliberately refuses to kill untracked processes. Website ports are 7139 and 5064; the app uses 5191. |
| Build says a file is being used by another process | Stop the running website before building/restarting it. |
| First launch times out | Inspect the relevant logs. Run Start again to keep waiting for its existing worker, or Stop to cancel. |
| Flutter web device is unavailable | Run `flutter config --enable-web`, then retry. |
| Startup settings changed but old data is still shown | Stop both servers, restart them, and refresh the browser. |
| Booking says the account has no client profile | Sign into the website with a client account; use the admin account in the Flutter app. |
| Registration cannot send a confirmation email | The project owner must correct Supabase Auth's SMTP settings. This is separate from local launch setup. |

Read logs without opening a terminal window for each server:

```powershell
Get-Content .\.local-run\website.log -Tail 50
Get-Content .\.local-run\app.error.log -Tail 50
```

## Run manually or debug in VS Code

For the Flutter app, open a terminal in `TM-Visuals-Flutter-App`:

```powershell
flutter pub get
flutter run -d chrome --web-port 5191 --dart-define-from-file=config/supabase.local.json
```

In VS Code, install the Flutter/Dart extension, choose **TM Visuals Flutter (Chrome)** in Run and Debug, and press F5. The profile works when opening either the repository root or the Flutter project folder. Stop the launcher-managed app first to avoid duplicate processes.

For the website, open another PowerShell window in the repository root:

```powershell
$cfg = Get-Content .\TM-Visuals-Flutter-App\config\supabase.local.json -Raw | ConvertFrom-Json
$env:Supabase__Url = $cfg.SUPABASE_URL
$env:Supabase__Key = $cfg.SUPABASE_PUBLISHABLE_KEY
dotnet run --project .\TM-Visuals-ASPNET-Website --launch-profile https
```

Open https://localhost:7139. Press Ctrl+C in each manual terminal to stop its server. The Stop CMD file stops only servers started and tracked by the launcher.
