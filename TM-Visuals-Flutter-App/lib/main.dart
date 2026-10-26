import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'viewmodels/portfolio_view_model.dart';
import 'routes/route_manager.dart';
import 'viewmodels/admin_profile_viewmodel.dart';
import 'viewmodels/invoice_list_viewmodel.dart';
import 'viewmodels/admin_settings_viewmodel.dart';
import 'views/admin_profile_screen.dart';
import 'views/invoice_list_screen.dart';
import 'views/admin_settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase with your test credentials
  await Supabase.initialize(
    url: 'https://YOUR_SUPABASE_PROJECT.supabase.co',
    publishableKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PortfolioViewModel>(
          create: (_) => PortfolioViewModel(),
        ),
        ChangeNotifierProvider(create: (_) => AdminProfileViewModel()),
        ChangeNotifierProvider(create: (_) => InvoiceListViewModel()),
        ChangeNotifierProvider(create: (_) => AdminSettingsViewModel()),
      ],
      child: MaterialApp(
        title: 'TM Visuals',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        initialRoute: Routes.adminProfile,
        routes: {
          '/admin-profile': (context) => AdminProfileScreen(),
          '/invoices': (context) => InvoiceListScreen(),
          '/settings': (context) => AdminSettingsScreen(),
        },
        onGenerateRoute: RouteManager.getRoute,
      ),
    );
  }
}