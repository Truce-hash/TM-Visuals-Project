import 'package:flutter/material.dart';
import '../widgets/admin_page_app_bar.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_settings_viewmodel.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AdminSettingsViewModel>().load();
    });
  }

  Future<void> _save(AdminSettingsViewModel vm) async {
    final saved = await vm.save();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Settings saved. Check your email if an address change requires confirmation.'
                : vm.error ?? 'Settings could not be saved.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminSettingsViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const AdminPageAppBar(title: 'Settings'),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                if (vm.error != null && vm.settings.email.isEmpty)
                  Text(
                    vm.error!,
                    style: const TextStyle(color: Colors.redAccent),
                  )
                else ...[
                  TextFormField(
                    enabled: !vm.saving,
                    initialValue: vm.settings.email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onChanged: (value) => vm.settings.email = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !vm.saving,
                    initialValue: vm.settings.phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    onChanged: (value) => vm.settings.phone = value,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Change password',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !vm.saving,
                    obscureText: vm.hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Current password',
                      suffixIcon: IconButton(
                        onPressed: vm.toggleHidePassword,
                        icon: Icon(
                          vm.hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                    onChanged: (value) => vm.settings.currentPassword = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !vm.saving,
                    obscureText: vm.hidePassword,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      helperText: 'Use at least 8 characters.',
                    ),
                    onChanged: (value) => vm.settings.newPassword = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    enabled: !vm.saving,
                    obscureText: vm.hidePassword,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                    ),
                    onChanged: (value) => vm.settings.confirmPassword = value,
                  ),
                  if (vm.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        vm.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: vm.saving ? null : () => _save(vm),
                    child: vm.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save settings'),
                  ),
                ],
              ],
            ),
    );
  }
}
