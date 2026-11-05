import 'package:flutter/material.dart';
import '../widgets/admin_widgets.dart';

class SupabaseSetupScreen extends StatelessWidget {
  const SupabaseSetupScreen({super.key, this.error});
  final Object? error;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TM Visuals')),
    body: AdminContent(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Connect TM Visuals',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Text(
            error == null
                ? 'Add the Supabase connection settings to enable admin sign-in.'
                : 'The Supabase connection could not start. Check the settings and restart.',
          ),
          const SizedBox(height: 16),
          const SelectableText(
            'Copy config/supabase.example.json to config/supabase.local.json and set the project URL and public publishable key. Start with:\nflutter run --dart-define-from-file=config/supabase.local.json\n\nOr double-click Start-TM-Visuals.cmd in the repository root. In VS Code, choose TM Visuals Flutter (Chrome). Stop and restart after changing configuration.',
          ),
        ],
      ),
    ),
  );
}
