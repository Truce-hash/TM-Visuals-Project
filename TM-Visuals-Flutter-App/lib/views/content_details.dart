import 'package:flutter/material.dart';
import 'package:photography_flutter_application/models/content_model.dart';
import 'package:photography_flutter_application/viewmodels/content_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentDetailsView extends StatefulWidget {
  const ContentDetailsView({super.key, required this.content});
  final ContentModel content;

  @override
  State<ContentDetailsView> createState() => _ContentDetailsViewState();
}

class _ContentDetailsViewState extends State<ContentDetailsView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _linkController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.content.title);
    _linkController = TextEditingController(text: widget.content.deliveryLink);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await context.read<ContentViewModel>().updateContent(
        content: widget.content,
        title: _titleController.text,
        deliveryLink: _linkController.text,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update content: $error')),
      );
    }
  }

  Future<void> _delete() async {
    if (!await _confirmDelete() || !mounted) return;

    try {
      await context.read<ContentViewModel>().deleteContent(
        widget.content.contentId,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete content: $error')),
      );
    }
  }

  Future<bool> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete delivery?'),
        content: const Text('This removes the delivery record for the client.'),
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

  Future<void> _openLink() async {
    final uri = Uri.tryParse(widget.content.deliveryLink);
    if (uri == null ||
        (uri.scheme != 'http' && uri.scheme != 'https') ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this delivery link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentViewModel = context.watch<ContentViewModel>();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Content Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              tooltip: 'Edit content',
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
            ),
          if (!_isEditing)
            IconButton(
              tooltip: 'Delete content',
              onPressed: contentViewModel.isSaving ? null : _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.content.eventType.isEmpty
                  ? 'Client delivery'
                  : widget.content.eventType,
              style: const TextStyle(color: Colors.orange, fontSize: 18),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              enabled: _isEditing,
              maxLength: 120,
              decoration: const InputDecoration(labelText: 'Content title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a title.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              enabled: _isEditing,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'Delivery link'),
              validator: (value) => isValidDeliveryLink(value ?? '')
                  ? null
                  : 'Enter a valid http or https link.',
            ),
            const SizedBox(height: 12),
            Text(
              'Uploaded: ${widget.content.uploadedAt.isEmpty ? 'Unknown' : widget.content.uploadedAt}',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            if (!_isEditing)
              OutlinedButton.icon(
                onPressed: _openLink,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open delivery link'),
              )
            else ...[
              FilledButton(
                onPressed: contentViewModel.isSaving ? null : _save,
                child: contentViewModel.isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
              TextButton(
                onPressed: contentViewModel.isSaving
                    ? null
                    : () => setState(() {
                        _isEditing = false;
                        _titleController.text = widget.content.title;
                        _linkController.text = widget.content.deliveryLink;
                      }),
                child: const Text('Cancel'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
