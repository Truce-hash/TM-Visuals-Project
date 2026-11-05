[CmdletBinding()]
param(
    [ValidateSet('Both','Website','App')][string]$Target = 'Both',
    [string]$ConfigFile = '',
    [switch]$Stop,
    [switch]$Check,
    [switch]$NoBrowser,
    [switch]$Worker,
    [ValidateRange(10,600)][int]$StartupTimeoutSeconds = 240
)

function Get-TMConfiguration([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw 'Create TM-Visuals-Flutter-App/config/supabase.local.json from config/supabase.example.json and fill in the project URL and public key. See SETUP.md.'
    }
    try { $raw = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json } catch {
        throw 'The Supabase configuration is not valid JSON. Check supabase.local.json against the example file.'
    }
    if ($null -eq $raw -or $null -eq $raw.PSObject.Properties['SUPABASE_URL'] -or
        $null -eq $raw.PSObject.Properties['SUPABASE_PUBLISHABLE_KEY']) {
        throw 'The configuration needs SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.'
    }
    $url = ([string]$raw.SUPABASE_URL).Trim()
    $key = ([string]$raw.SUPABASE_PUBLISHABLE_KEY).Trim()
    $uri = $null
    if (-not [Uri]::TryCreate($url,[UriKind]::Absolute,[ref]$uri) -or
        $uri.Scheme -notin @('http','https') -or $uri.AbsolutePath -ne '/' -or
        $uri.Query -or $uri.Fragment -or $url -match 'YOUR_PROJECT') {
        throw 'Set SUPABASE_URL to your project URL, such as https://PROJECT_REF.supabase.co.'
    }
    $publicKey = $key.StartsWith('sb_publishable_') -and $key.Length -gt 15
    if (-not $publicKey -and $key.Split('.').Count -eq 3) {
        try {
            $payload = $key.Split('.')[1].Replace('-','+').Replace('_','/')
            $payload = $payload.PadRight($payload.Length + (4 - $payload.Length % 4) % 4,'=')
            $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($payload)) | ConvertFrom-Json
            $publicKey = $claims.PSObject.Properties['role'] -and $claims.role -eq 'anon'
        } catch { $publicKey = $false }
    }
    if (-not $publicKey) { throw 'Use a public Supabase publishable key or legacy anon key. Secret and service-role keys are not allowed.' }
    return [pscustomobject]@{ Url=$url.TrimEnd('/'); Key=$key }
}

function ConvertTo-TMArgument([string]$Value) {
    if ($Value.Contains('"') -or $Value.Contains([char]0)) { throw 'A launcher argument contains an unsupported character.' }
    return '"' + $Value + '"'
}

function Test-TMPort([ValidateRange(1,65535)][int]$Port) {
    foreach ($address in @([Net.IPAddress]::Loopback,[Net.IPAddress]::IPv6Loopback)) {
        $client = $null
        try {
            $client = [Net.Sockets.TcpClient]::new($address.AddressFamily)
            if ($client.ConnectAsync($address,$Port).Wait(400) -and $client.Connected) { return $true }
        } catch { }
        finally { if ($null -ne $client) { $client.Dispose() } }
    }
    return $false
}

function Get-TMOwnedProcess([string]$StatePath,[string]$WorkerPath) {
    if (-not (Test-Path -LiteralPath $StatePath)) { return $null }
    try {
        $state = Get-Content -Raw -LiteralPath $StatePath | ConvertFrom-Json
        if ($state.WorkerPath -ne $WorkerPath) { return $null }
        $process = Get-Process -Id ([int]$state.ProcessId) -ErrorAction Stop
        $started = [DateTimeOffset]::Parse([string]$state.StartedUtc).UtcDateTime
        if ($process.StartTime.ToUniversalTime().Ticks -ne $started.Ticks) { return $null }
        $info = Get-CimInstance Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction Stop
        if (-not $info.CommandLine -or
            $info.CommandLine.IndexOf($WorkerPath,[StringComparison]::OrdinalIgnoreCase) -lt 0 -or
            $info.CommandLine -notmatch '(?i)(?:^|\s)-Worker(?:\s|$)') { return $null }
        return $process
    } catch { return $null }
}

function Test-TMHttpReady([string]$Url,[switch]$JavaScript) {
    $response = $null
    try {
        $request = [Net.HttpWebRequest]::Create($Url)
        $request.Timeout = 1200
        $request.ReadWriteTimeout = 1200
        $request.AllowAutoRedirect = $false
        $request.Proxy = $null
        $response = $request.GetResponse()
        return [int]$response.StatusCode -eq 200 -and (-not $JavaScript -or $response.ContentType -match '(java|ecma)script')
    } catch { return $false }
    finally { if ($null -ne $response) { $response.Dispose() } }
}

function Assert-TMPrerequisites([string[]]$Targets,[string]$Root) {
    if ($Targets -contains 'Website') {
        if (-not (Get-Command dotnet.exe -ErrorAction SilentlyContinue)) { throw 'Install the .NET 9 SDK and reopen the launcher. See SETUP.md.' }
        $sdks = @(& dotnet.exe --list-sdks)
        if (-not ($sdks | Where-Object { $_ -match '^(9|[1-9][0-9]+)\.' })) { throw 'The website needs a .NET SDK version 9 or newer. See SETUP.md.' }
        $runtimes = @(& dotnet.exe --list-runtimes)
        if (-not ($runtimes | Where-Object { $_ -match '^Microsoft\.AspNetCore\.App 9\.' }) -or
            -not ($runtimes | Where-Object { $_ -match '^Microsoft\.NETCore\.App 9\.' })) {
            throw 'Install the .NET 9 SDK, which supplies the website''s .NET 9 and ASP.NET Core 9 runtimes.'
        }
        & dotnet.exe dev-certs https --check --trust --quiet
        if ($LASTEXITCODE -ne 0) { throw 'Run dotnet dev-certs https --trust once, accept the Windows certificate prompt, then launch again.' }
    }
    if ($Targets -contains 'App' -and -not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        throw 'Install Flutter, add its bin folder to PATH, and reopen the launcher. See SETUP.md.'
    }
}

function Start-TMService([string]$Name,[string]$Root,[string]$WorkerPath,[string]$SettingsPath,[string]$RuntimePath,[int]$Timeout) {
    $port = if ($Name -eq 'Website') { 7139 } else { 5191 }
    $url = if ($Name -eq 'Website') { 'https://localhost:7139' } else { 'http://localhost:5191' }
    $stem = $Name.ToLowerInvariant()
    $statePath = Join-Path $RuntimePath "$stem.json"
    $process = Get-TMOwnedProcess -StatePath $statePath -WorkerPath $WorkerPath
    if ($null -eq $process) {
        if ((Test-TMPort -Port $port) -or ($Name -eq 'Website' -and (Test-TMPort -Port 5064))) {
            throw "$Name port is already in use. Stop the existing app/website terminal first. This launcher will not stop an untracked process."
        }
        $arguments = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',
            (ConvertTo-TMArgument $WorkerPath),'-Worker','-Target',$Name,'-ConfigFile',(ConvertTo-TMArgument $SettingsPath))
        $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $process = Start-Process -FilePath $powershell -ArgumentList $arguments -WorkingDirectory $Root -WindowStyle Hidden -PassThru `
            -RedirectStandardOutput (Join-Path $RuntimePath "$stem.log") -RedirectStandardError (Join-Path $RuntimePath "$stem.error.log")
        [ordered]@{ ProcessId=$process.Id; StartedUtc=$process.StartTime.ToUniversalTime().ToString('O'); WorkerPath=$WorkerPath } |
            ConvertTo-Json | Set-Content -Encoding utf8 -LiteralPath $statePath
        Write-Host "Starting $Name. First launch may take a few minutes while dependencies restore..."
    } else { Write-Host "$Name is already managed by this launcher; reusing it." }
    $deadline = [DateTime]::UtcNow.AddSeconds($Timeout)
    while ([DateTime]::UtcNow -lt $deadline) {
        if (Test-Path -LiteralPath (Join-Path $RuntimePath 'stop.request')) { throw 'Startup cancelled by Stop.' }
        $process.Refresh()
        if ($process.HasExited) { throw "$Name exited. Read $RuntimePath\$stem.log and $RuntimePath\$stem.error.log, fix the error, then launch again." }
        $ready = if ($Name -eq 'App') { Test-TMHttpReady -Url "$url/main.dart.js" -JavaScript } else { Test-TMHttpReady -Url "$url/" }
        if ($ready) { Write-Host "$Name ready: $url"; return $url }
        Start-Sleep -Milliseconds 400
    }
    throw "$Name is still starting. Read $RuntimePath\$stem.log, then run Start again to wait or Stop to cancel."
}

function Stop-TMService([string]$Name,[string]$WorkerPath,[string]$RuntimePath) {
    $statePath = Join-Path $RuntimePath ($Name.ToLowerInvariant() + '.json')
    $process = Get-TMOwnedProcess -StatePath $statePath -WorkerPath $WorkerPath
    if ($null -ne $process) {
        & taskkill.exe /PID $process.Id /T /F | Out-Null
        if ($LASTEXITCODE -ne 0 -and (Get-Process -Id $process.Id -ErrorAction SilentlyContinue)) { throw "Could not stop $Name. See SETUP.md." }
        Write-Host "Stopped $Name."
    } else { Write-Host "No launcher-managed $Name process is running." }
    if (Test-Path -LiteralPath $statePath) { Remove-Item -LiteralPath $statePath }
}

# Dot-sourcing exposes the helpers to the offline checks without launching anything.
if ($MyInvocation.InvocationName -eq '.') { return }
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path $PSScriptRoot -Parent
$workerPath = $PSCommandPath
$runtimePath = Join-Path $root '.local-run'
$targets = if ($Target -eq 'Both') { @('Website','App') } else { @($Target) }
$mutex = $null
$mutexOwned = $false
$stopRequest = Join-Path $runtimePath 'stop.request'
if (-not $ConfigFile) { $ConfigFile = Join-Path $root 'TM-Visuals-Flutter-App\config\supabase.local.json' }
try {
    if (-not $Worker) {
        $hashAlgorithm = [Security.Cryptography.SHA256]::Create()
        try { $rootHash = [BitConverter]::ToString($hashAlgorithm.ComputeHash([Text.Encoding]::UTF8.GetBytes($root.ToLowerInvariant()))).Replace('-','') }
        finally { $hashAlgorithm.Dispose() }
        $mutex = [Threading.Mutex]::new($false,"Local\TMVisualsLauncher-$rootHash")
        if ($Stop) {
            New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
            Set-Content -LiteralPath $stopRequest -Value 'Cancel startup before stopping the managed workers.'
            $mutexOwned = $mutex.WaitOne(15000)
            if (-not $mutexOwned) { throw 'Stop was requested while startup is busy. Wait a moment and run Stop again.' }
        } else {
            $mutexOwned = $mutex.WaitOne(0)
            if (-not $mutexOwned) { Write-Host 'TM Visuals is already starting or stopping. Wait for that operation to finish.'; exit 0 }
        }
    }
    if ($Stop) {
        foreach ($name in $targets) { Stop-TMService -Name $name -WorkerPath $workerPath -RuntimePath $runtimePath }
        if (Test-Path -LiteralPath $stopRequest) { Remove-Item -LiteralPath $stopRequest }
        exit 0
    }
    $settings = Get-TMConfiguration -Path $ConfigFile
    $ConfigFile = (Resolve-Path -LiteralPath $ConfigFile).Path
    if ($Worker) {
        if ($Target -eq 'Website') {
            $env:Supabase__Url = $settings.Url
            $env:Supabase__Key = $settings.Key
            Set-Location -LiteralPath (Join-Path $root 'TM-Visuals-ASPNET-Website')
            & dotnet.exe run --project TMVisualsWebApp.csproj --launch-profile https
        } elseif ($Target -eq 'App') {
            Set-Location -LiteralPath (Join-Path $root 'TM-Visuals-Flutter-App')
            & flutter run -d web-server --web-hostname localhost --web-port 5191 "--dart-define-from-file=$ConfigFile"
        } else { throw 'Worker mode requires Website or App.' }
        exit $LASTEXITCODE
    }
    Assert-TMPrerequisites -Targets $targets -Root $root
    if ($Check) { Write-Host "Setup checks passed. Supabase: $($settings.Url)"; exit 0 }
    New-Item -ItemType Directory -Path $runtimePath -Force | Out-Null
    foreach ($name in $targets) {
        if (Test-Path -LiteralPath $stopRequest) { throw 'Startup cancelled by Stop.' }
        $url = Start-TMService -Name $name -Root $root -WorkerPath $workerPath -SettingsPath $ConfigFile -RuntimePath $runtimePath -Timeout $StartupTimeoutSeconds
        if (-not $NoBrowser) { Start-Process $url | Out-Null }
    }
    Write-Host 'Use Stop-TM-Visuals.cmd to stop these development servers. Closing a browser tab does not stop them.'
} catch {
    if (-not $Worker -and -not $Stop -and $mutexOwned -and (Test-Path -LiteralPath $stopRequest)) {
        foreach ($name in $targets) { Stop-TMService -Name $name -WorkerPath $workerPath -RuntimePath $runtimePath }
        Remove-Item -LiteralPath $stopRequest
        Write-Host 'Startup cancelled. Managed servers have been stopped.'
        exit 0
    }
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
} finally {
    if ($mutexOwned) { $mutex.ReleaseMutex() }
    if ($null -ne $mutex) { $mutex.Dispose() }
}
