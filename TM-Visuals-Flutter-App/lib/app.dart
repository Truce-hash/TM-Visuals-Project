import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin/admin_repository.dart';
import 'admin/calendar_screen.dart';
import 'admin/invoices_screen.dart';
import 'admin/supabase_admin_repository.dart';
import 'admin/widgets.dart';
import 'routes/route_manager.dart';

ThemeData tmVisualsTheme() => ThemeData(
  fontFamily: 'Inter',
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: gold,
    brightness: Brightness.dark,
    primary: gold,
    onPrimary: Colors.black,
    surface: const Color(0xFF202020),
  ),
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    filled: true,
    fillColor: Color(0xFF202020),
  ),
  cardTheme: CardThemeData(
    color: const Color(0xFF252525),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFF6B5300)),
    ),
  ),
  navigationBarTheme: const NavigationBarThemeData(
    backgroundColor: Color.fromARGB(255, 49, 49, 49),
    indicatorColor: Color.fromARGB(255, 143, 143, 143),
  ),
);

class TMVisualsApp extends StatelessWidget {
  const TMVisualsApp({super.key, this.client, this.startupError});
  final SupabaseClient? client;
  final Object? startupError;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'TM Visuals Admin',
    debugShowCheckedModeBanner: false,
    theme: tmVisualsTheme(),
    initialRoute: RouteManager.root,
    home: client == null
        ? _SetupScreen(error: startupError)
        : AdminAuthGate(client: client!),
  );
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen({this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TM Visuals')),
    body: ContentWidth(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.camera_alt_outlined, size: 64, color: gold),
          const SizedBox(height: 24),
          Text(
            'Connect TM Visuals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            error == null
                ? 'The app needs its Supabase connection settings before admin sign-in is available.'
                : 'The app could not start its Supabase connection. Check the configuration and restart.',
          ),
          const SizedBox(height: 16),
          const SelectableText(
            'Set SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in config/supabase.local.json. Then stop the app and launch with: flutter run --dart-define-from-file=config/supabase.local.json. In VS Code, use the TM Visuals (local Supabase config) launch profile. Editing the JSON alone does not update a running app.',
          ),
        ],
      ),
    ),
  );
}

class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key, required this.client});
  final SupabaseClient client;
  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  StreamSubscription<AuthState>? subscription;
  String? userId, adminId;
  bool checking = true;
  Object? error;
  int version = 0;
  late final AdminRepository repository;
  @override
  void initState() {
    super.initState();
    repository = SupabaseAdminRepository(widget.client);
    subscription = widget.client.auth.onAuthStateChange.listen(
      (_) => _check(),
      onError: (Object e) {
        if (mounted) {
          setState(() {
            error = e;
            checking = false;
            adminId = null;
          });
        }
      },
    );
    _check();
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    final current = ++version;
    final user = widget.client.auth.currentUser;
    final keepNavigator = user != null && userId == user.id && adminId != null;
    setState(() {
      userId = user?.id;
      if (!keepNavigator) adminId = null;
      checking = !keepNavigator && user != null;
      error = null;
    });
    if (user == null) return;
    try {
      final id = await SupabaseAdminRepository(widget.client).currentAdminId();
      if (mounted && current == version) setState(() => adminId = id);
    } catch (e) {
      if (mounted && current == version) {
        if (keepNavigator) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(readableError(e))));
        } else {
          setState(() => error = e);
        }
      }
    } finally {
      if (mounted && current == version) setState(() => checking = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await widget.client.auth.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(readableError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) return _LoginScreen(client: widget.client);
    if (checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null || adminId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TM Visuals')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error == null
                      ? 'This account does not have administrator access.'
                      : readableError(error!),
                ),
                TextButton(onPressed: _check, child: const Text('Check again')),
                OutlinedButton(
                  onPressed: _signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    // Removing this nested navigator also removes open admin routes on sign-out.
    return Navigator(
      key: ValueKey(userId),
      onGenerateRoute: (settings) => RouteManager.getRoute(
        settings,
        repository: repository,
        homeBuilder: (_) =>
            AdminWorkspace(repository: repository, onSignOut: _signOut),
      ),
    );
  }
}

class _LoginScreen extends StatefulWidget {
  const _LoginScreen({required this.client});
  final SupabaseClient client;
  @override
  State<_LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<_LoginScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  Object? error;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.client.auth.signInWithPassword(
        email: email.text.trim(),
        password: password.text,
      );
    } catch (e) {
      if (mounted) setState(() => error = e);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TM Visuals')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            const Icon(Icons.camera_alt_outlined, color: gold, size: 64),
            const SizedBox(height: 24),
            Text(
              'Admin sign in',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text('Manage your calendar, availability and invoices.'),
            const SizedBox(height: 24),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: email,
                    enabled: !busy,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Enter your email address.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: password,
                    enabled: !busy,
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your password.' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        readableError(error!),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : _login,
                    child: Text(busy ? 'Signing in…' : 'Sign in'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class AdminWorkspace extends StatefulWidget {
  const AdminWorkspace({
    super.key,
    required this.repository,
    required this.onSignOut,
  });
  final AdminRepository repository;
  final Future<void> Function() onSignOut;
  @override
  State<AdminWorkspace> createState() => _AdminWorkspaceState();
}

class _AdminWorkspaceState extends State<AdminWorkspace> {
  int index = 0;
  bool signingOut = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'TM '),
            TextSpan(
              text: 'Visuals',
              style: TextStyle(color: gold),
            ),
          ],
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Admin pages',
          onSelected: (route) => Navigator.of(context).pushNamed(route),
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: RouteManager.bookings,
              child: Text('Bookings'),
            ),
            PopupMenuItem(
              value: RouteManager.portfolioContent,
              child: Text('Portfolio'),
            ),
            PopupMenuItem(value: RouteManager.profile, child: Text('Profile')),
            PopupMenuItem(
              value: RouteManager.settings,
              child: Text('Settings'),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: signingOut
              ? null
              : () async {
                  setState(() => signingOut = true);
                  try {
                    await widget.onSignOut();
                  } finally {
                    if (mounted) setState(() => signingOut = false);
                  }
                },
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    body: IndexedStack(
      index: index,
      children: [
        AdminCalendarScreen(repository: widget.repository),
        AdminInvoicesScreen(repository: widget.repository),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (v) => setState(() => index = v),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month, color: Colors.black),
          label: 'Calendar',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: Colors.black),
          label: 'Invoices',
        ),
      ],
    ),
  );
}
