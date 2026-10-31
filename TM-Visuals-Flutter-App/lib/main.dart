import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
export 'app.dart' show MyApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  SupabaseClient? client;
  Object? error;
  if (url.isNotEmpty && key.isNotEmpty && key != 'YOUR_PUBLISHABLE_KEY') {
    try {
      if (key.startsWith('sb_secret_')) {
        throw const FormatException('Use a public publishable key.');
      }
      await Supabase.initialize(
        url: url.trim(),
        publishableKey: key.trim(),
        debug: false,
      );
      client = Supabase.instance.client;
    } catch (e) {
      error = e;
    }
  }
  runApp(MyApp(client: client, startupError: error));
}
