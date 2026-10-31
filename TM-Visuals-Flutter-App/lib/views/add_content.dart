import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/content_model.dart';
import 'package:photography_flutter_application/viewmodels/content_viewmodel.dart';
import 'package:provider/provider.dart';

class AddContentView extends StatefulWidget {
  const AddContentView({super.key, required this.clientId});
  final String clientId;

  @override
  State<AddContentView> createState() => _AddContentViewState();
}

class _AddContentViewState extends State<AddContentView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  String? _bookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentViewModel>().loadBookings(widget.clientId);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final bookingId = _bookingId;
    if (bookingId == null) {
      _showMessage('Choose a booking for this delivery.');
      return;
    }
    try {
      await context.read<ContentViewModel>().addContent(
        bookingId: bookingId,
        title: _titleController.text,
        deliveryLink: _linkController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) _showMessage('Could not add content: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final contentViewModel = context.watch<ContentViewModel>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Add Client Content'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (contentViewModel.isLoading && contentViewModel.bookings.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              )
            else if (contentViewModel.errorMessage != null &&
                contentViewModel.bookings.isEmpty)
              Text(
                contentViewModel.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (contentViewModel.bookings.isEmpty)
              const Text(
                'This client has no bookings to attach content to.',
                style: TextStyle(color: Colors.grey),
              )
            else
              DropdownButtonFormField<String>(
                initialValue:
                    contentViewModel.bookings.any(
                      (booking) => booking.bookingId == _bookingId,
                    )
                    ? _bookingId
                    : null,
                decoration: const InputDecoration(labelText: 'Booking'),
                items: contentViewModel.bookings
                    .map(
                      (booking) => DropdownMenuItem(
                        value: booking.bookingId,
                        child: Text(
                          booking.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _bookingId = value),
                validator: (value) =>
                    value == null ? 'Choose a booking.' : null,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Content title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Delivery link',
                hintText: 'https://...',
              ),
              validator: (value) => isValidDeliveryLink(value ?? '')
                  ? null
                  : 'Enter a valid http or https link.',
            ),
            const SizedBox(height: 10),
            const Text(
              'This private link is saved against the selected booking; it is not shown in the public portfolio.',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed:
                  contentViewModel.isSaving ||
                      (contentViewModel.bookings.isEmpty &&
                          !contentViewModel.isLoading)
                  ? null
                  : _save,
              child: contentViewModel.isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save content'),
            ),
          ],
        ),
      ),
    );
  }
}
