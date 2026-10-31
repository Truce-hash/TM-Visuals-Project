import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_auth_viewmodel.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/admin_widgets.dart';

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('More')),
    bottomNavigationBar: const AdminBottomNav(currentIndex: 3),
    body: AdminContent(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final item in const [
            ('/add-invoice', 'Upload invoice', Icons.upload_file),
            ('/invoices', 'Invoices', Icons.receipt_long),
            ('/portfolio-content', 'Upload Portfolio', Icons.photo_library_outlined),
            ('/portfolio-gallery', 'Portfolio gallery', Icons.collections_outlined),
            ('/clients', 'Clients', Icons.people_outline),
            ('/services', 'Services', Icons.camera_alt_outlined),
            ('/settings', 'Settings', Icons.settings_outlined),
          ])
            Card(
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: Icon(item.$3, color: adminGold),
                  title: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).pushNamed(item.$1),
                ),
              ),
            ),
          const SizedBox(height: 24),
          Consumer<AdminAuthViewModel>(
            builder: (context, vm, _) => Column(
              children: [
                if (vm.error != null)
                  Text(
                    adminError(vm.error!),
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                OutlinedButton.icon(
                  onPressed: vm.busy ? null : () => _confirmSignOut(context, vm),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _confirmSignOut(
    BuildContext context,
    AdminAuthViewModel viewModel,
  ) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await viewModel.signOut();
    }
  }
}
