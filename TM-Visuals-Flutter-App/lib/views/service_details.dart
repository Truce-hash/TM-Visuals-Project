import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/service_list_model.dart';
import 'package:photography_flutter_application/viewmodels/service_list_viewmodel.dart';
import 'package:photography_flutter_application/views/edit_service.dart';
import 'package:provider/provider.dart';

class ServiceDetailsView extends StatefulWidget {
  final ServicesListModel service;
  const ServiceDetailsView({super.key, required this.service});

  @override
  State<ServiceDetailsView> createState() => _ServiceDetailsViewState();
}

class _ServiceDetailsViewState extends State<ServiceDetailsView> {
  late ServicesListModel _service;
  bool _isUpdatingStatus = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  Future<void> _setAvailable(bool isAvailable) async {
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await context.read<ServiceViewModel>().updateService(
        _service.copyWith(
          availability: isAvailable ? 'Available' : 'Unavailable',
        ),
      );
      if (mounted) setState(() => _service = updated);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update service status: $error')),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  Future<void> _editService() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditServiceView(service: _service)),
    );
    if (!mounted || changed != true) return;
    final updated = context.read<ServiceViewModel>().services.where(
      (item) => item.id == _service.id,
    );
    if (updated.isNotEmpty) setState(() => _service = updated.first);
  }

  Future<void> _deleteService() async {
    final confirmed = await _confirmDelete();
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await context.read<ServiceViewModel>().deleteService(_service.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete service. It may be linked to existing bookings. $error',
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text(
          'Delete "${_service.serviceName}"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = _service.availability == 'Available';
    final isBusy = _isUpdatingStatus || _isDeleting;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Service Details',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Delete service',
            onPressed: isBusy ? null : _deleteService,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
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
                    _service.serviceName,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 28),
                  _DetailField(
                    label: 'Description',
                    value: _service.description.isEmpty
                        ? 'No description provided.'
                        : _service.description,
                  ),
                  const SizedBox(height: 18),
                  _DetailField(
                    label: 'Created',
                    value: _service.dateTime.isEmpty
                        ? 'Not available'
                        : _service.dateTime,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for booking'),
                    value: isAvailable,
                    activeTrackColor: Colors.orange,
                    onChanged: isBusy ? null : _setAvailable,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isBusy ? null : _editService,
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit service'),
                    ),
                  ),
                  if (_isDeleting)
                    const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 5),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
    ],
  );
}
