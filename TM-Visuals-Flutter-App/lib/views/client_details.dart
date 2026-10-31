import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/clients_model.dart';
import 'package:photography_flutter_application/models/content_model.dart';
import 'package:photography_flutter_application/viewmodels/content_viewmodel.dart';
import 'package:photography_flutter_application/views/add_content.dart';
import 'package:photography_flutter_application/views/content_details.dart';
import 'package:provider/provider.dart';

class ClientDetailsView extends StatelessWidget {
  const ClientDetailsView({super.key, required this.client});
  final Clients client;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ContentViewModel()..loadForClient(client.id),
    child: _ClientDetailsContent(client: client),
  );
}

class _ClientDetailsContent extends StatelessWidget {
  const _ClientDetailsContent({required this.client});
  final Clients client;

  Future<void> _addContent(BuildContext context) async {
    final contentViewModel = context.read<ContentViewModel>();
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: contentViewModel,
          child: AddContentView(clientId: client.id),
        ),
      ),
    );
    if (added == true) await contentViewModel.loadForClient(client.id);
  }

  Future<void> _openContent(BuildContext context, ContentModel content) async {
    final contentViewModel = context.read<ContentViewModel>();
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: contentViewModel,
          child: ContentDetailsView(content: content),
        ),
      ),
    );
    if (changed == true) await contentViewModel.loadForClient(client.id);
  }

  @override
  Widget build(BuildContext context) {
    final contentViewModel = context.watch<ContentViewModel>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Client Details',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    client.name.isEmpty ? '(No name)' : client.name,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 28),
                  _ClientField(label: 'Email', value: client.email),
                  _ClientField(label: 'Phone', value: client.phone),
                  _ClientField(
                    label: 'Previous bookings',
                    value: client.previousBookings,
                  ),
                  _ClientField(
                    label: 'Last booking',
                    value: client.lastBooking,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bookings',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (client.bookings.isEmpty)
            const Text(
              'This client has no bookings yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...client.bookings.map(
              (booking) => Card(
                color: const Color(0xFF1C1C1C),
                child: ListTile(
                  title: Text(
                    booking.eventType.isEmpty ? 'Booking' : booking.eventType,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    booking.date.isEmpty ? 'Date not available' : booking.date,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Text(
                    booking.status,
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Delivered Content',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          if (contentViewModel.isLoading && contentViewModel.items.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            )
          else if (contentViewModel.errorMessage != null &&
              contentViewModel.items.isEmpty)
            Text(
              contentViewModel.errorMessage!,
              style: const TextStyle(color: Colors.redAccent),
            )
          else if (contentViewModel.items.isEmpty)
            const Text(
              'No content has been delivered to this client yet.',
              style: TextStyle(color: Colors.grey),
            )
          else
            ...contentViewModel.items.map(
              (item) => Card(
                color: const Color(0xFF1C1C1C),
                child: ListTile(
                  onTap: () => _openContent(context, item),
                  title: Text(
                    item.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${item.eventType} • ${item.uploadedAt}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          if (contentViewModel.errorMessage != null &&
              contentViewModel.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                contentViewModel.errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _addContent(context),
            icon: const Icon(Icons.add),
            label: const Text('Add client content'),
          ),
        ],
      ),
    );
  }
}

class _ClientField extends StatelessWidget {
  const _ClientField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    ),
  );
}
