import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/admin_auth_viewmodel.dart';
import '../widgets/admin_widgets.dart';

class AdminSignInScreen extends StatefulWidget {
  const AdminSignInScreen({super.key});
  @override
  State<AdminSignInScreen> createState() => _AdminSignInScreenState();
}

class _AdminSignInScreenState extends State<AdminSignInScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminAuthViewModel>();
    void submit() {
      if (form.currentState!.validate()) vm.signIn(email.text, password.text);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('TM Visuals')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.camera_alt_outlined, color: adminGold, size: 64),
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
                      enabled: !vm.busy,
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
                      enabled: !vm.busy,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Enter your password.'
                          : null,
                      onFieldSubmitted: (_) => submit(),
                    ),
                    if (vm.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          adminError(vm.error!),
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: vm.busy ? null : submit,   
                      child: Text(vm.busy ? 'Signing in…' : 'Sign in'),
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
}
