import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_page_app_bar.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/add_invoice_service.dart';
import '../viewmodels/add_invoice_view_model.dart';
import '../widgets/admin_widgets.dart';

class AddInvoiceScreen extends StatefulWidget {
  const AddInvoiceScreen({
    super.key,
    this.service,
    this.initialBookingId,
    this.viewModel,
  });
  final InvoiceDataSource? service;
  final String? initialBookingId;
  final AddInvoiceViewModel? viewModel;
  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  late final AddInvoiceViewModel vm;
  @override
  void initState() {
    super.initState();
    vm = widget.viewModel ?? AddInvoiceViewModel(service: widget.service);
    vm.prepareForBooking(widget.initialBookingId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        vm.loadBookings();
        vm.loadInvoices();
      }
    });
  }

  @override
  void dispose() {
    if (widget.viewModel == null) vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider.value(value: vm, child: const _AddInvoiceBody());
}

class _AddInvoiceBody extends StatelessWidget {
  const _AddInvoiceBody();
  Future<void> _pick(BuildContext context, AddInvoiceViewModel vm) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!context.mounted || result.isEmpty) return;
      final file = result.single;
      final length = await file.length();
      if (length != null && length > 10 * 1024 * 1024) {
        throw const FormatException('PDF files must be at most 10 MiB.');
      }
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      vm.selectPdf(file.name, bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(adminError(e))));
      }
    }
  }

  Future<void> _open(BuildContext context, AddInvoiceViewModel vm) async {
    try {
      final uri = await vm.service.signedInvoiceUrl(vm.invoice!.filePath);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Could not open the PDF.');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(adminError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AddInvoiceViewModel>();
    final validSelection = vm.bookings.any((b) => b.id == vm.bookingId);
    return PopScope(
      canPop: !vm.isLoading,
      child: Scaffold(
        appBar: const AdminPageAppBar(title: 'Add invoice'),
        body: AdminContent(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Upload an existing invoice',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Choose a booking and a PDF invoice (up to 10 MiB).'),
              const SizedBox(height: 24),
              if (vm.loadingBookings)
                const Center(child: CircularProgressIndicator())
              else if (vm.loadError != null)
                AdminErrorNotice(error: vm.loadError!, retry: vm.loadBookings)
              else if (vm.bookings.isEmpty)
                const Text(
                  'No bookings are available. Add a booking before uploading its invoice.',
                )
              else
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: validSelection ? vm.bookingId : null,
                  decoration: const InputDecoration(labelText: 'Booking'),
                  items: vm.bookings
                      .map(
                        (b) => DropdownMenuItem(
                          value: b.id,
                          child: Text(b.label, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: vm.locked ? null : vm.selectBooking,
                ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: vm.reference,
                enabled: !vm.locked,
                decoration: const InputDecoration(labelText: 'Reference'),
                maxLength: 120,
                onChanged: vm.setReference,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: vm.locked ? null : () => _pick(context, vm),
                icon: const Icon(Icons.upload_file),
                label: const Text('Choose PDF'),
              ),
              if (vm.fileName != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(vm.fileName!),
                ),
              if (vm.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    vm.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              if (vm.invoice != null) ...[
                const Text(
                  'Invoice saved.',
                  style: TextStyle(color: Colors.greenAccent),
                ),
                FilledButton(
                  onPressed: () => _open(context, vm),
                  child: const Text('Open PDF'),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Done'),
                ),
              ] else ...[
                if (vm.locked && !vm.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'An earlier upload still needs confirmation. Its details are kept while you are signed in. Retry to check whether it was saved.',
                    ),
                  ),
                FilledButton(
                  onPressed:
                      vm.isLoading ||
                          vm.loadingBookings ||
                          vm.loadError != null ||
                          vm.bookings.isEmpty
                      ? null
                      : vm.submit,
                  child: Text(
                    vm.isLoading
                        ? 'UploadingÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦'
                        : vm.locked
                        ? 'Retry upload'
                        : 'Upload invoice',
                  ),
                ),
                OutlinedButton(
                  onPressed: vm.isLoading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Uploaded invoices',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh invoices',
                    onPressed: vm.loadingInvoices ? null : vm.loadInvoices,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              if (vm.loadingInvoices)
                const Center(child: CircularProgressIndicator())
              else if (vm.invoiceListError != null)
                AdminErrorNotice(
                  error: vm.invoiceListError!,
                  retry: vm.loadInvoices,
                )
              else if (vm.invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No invoices have been uploaded yet.'),
                )
              else
                for (final invoice in vm.invoices)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: adminGold,
                      ),
                      title: Text(invoice.reference),
                      subtitle: Text(
                        invoice.createdAt == null
                            ? 'Booking ${invoice.bookingId}'
                            : 'Uploaded ${DateFormat.yMMMd().format(invoice.createdAt!.toLocal())}',
                      ),
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        try {
                          final uri = await vm.service.signedInvoiceUrl(
                            invoice.filePath,
                          );
                          if (!await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          )) {
                            throw StateError('Could not open the invoice PDF.');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(adminError(error))),
                            );
                          }
                        }
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
