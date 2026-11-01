import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/models/portfolio_model.dart';
import '/viewmodels/portfolio_view_model.dart';
import '/widgets/portfolio_widgets.dart';

const Color _yellow = Color(0xFFFFB900);
const Color _background = Colors.black;

class PortfolioContentScreen extends StatefulWidget {
  const PortfolioContentScreen({super.key});

  @override
  State<PortfolioContentScreen> createState() => _PortfolioContentScreenState();
}

class _PortfolioContentScreenState extends State<PortfolioContentScreen> {
  final TextEditingController titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch categories after the first frame via the ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioViewModel>().loadCategories(onError: showMessage);
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          backgroundColor: const Color(0xFF292929),
        ),
      );
  }

  Future<void> showAddCategoryDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const AddCategoryDialog(
        maxLength: PortfolioViewModel.maxCategoryLength,
      ),
    );

    if (name != null && mounted) {
      await context
          .read<PortfolioViewModel>()
          .addCategory(name, onMessage: showMessage);
    }
  }

  Future<void> showManageCategoriesDialog() async {
    final vm = context.read<PortfolioViewModel>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => ListenableBuilder(
        listenable: vm,
        builder: (_, __) => AlertDialog(
          backgroundColor: const Color(0xFF1C1C1C),
          title: const Text(
            'Manage Categories',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: 320,
            child: vm.categories.isEmpty
                ? const Text(
                    'No categories yet.',
                    style: TextStyle(color: Colors.white70),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final c in vm.categories)
                        ListTile(
                          title: Text(
                            c.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Rename',
                                icon: const Icon(Icons.edit, color: _yellow),
                                onPressed: () => renameCategoryFlow(c),
                              ),
                              IconButton(
                                tooltip: 'Remove',
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => removeCategoryFlow(c),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close', style: TextStyle(color: _yellow)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> renameCategoryFlow(PortfolioCategory c) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _RenameCategoryDialog(initial: c.name),
    );

    if (newName != null && mounted) {
      await context
          .read<PortfolioViewModel>()
          .renameCategory(c.id, newName, onMessage: showMessage);
    }
  }

  Future<void> removeCategoryFlow(PortfolioCategory c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove "${c.name}"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context
          .read<PortfolioViewModel>()
          .removeCategory(c.id, onMessage: showMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listens to notifyListeners() from PortfolioViewModel automatically
    final vm = context.watch<PortfolioViewModel>();
    final file = vm.selectedFile;

    return PopScope(
      canPop: !vm.isUploading,
      child: Scaffold(
        backgroundColor: _background,
        appBar: AppBar(
          backgroundColor: _background,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'TM Visuals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed:
                vm.isUploading ? null : () => Navigator.maybePop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: _yellow, height: 1),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Portfolio Content',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),

                // FILE UPLOAD / PREVIEW AREA
                Center(
                  child: Semantics(
                    button: file == null,
                    label: file == null
                        ? 'Choose a photo or video to upload'
                        : 'Preview of the selected file',
                    child: GestureDetector(
                      onTap: (vm.isUploading || file != null)
                          ? null
                          : () =>
                              vm.pickPortfolioContent(onMessage: showMessage),
                      child: Container(
                        width: 230,
                        height: 190,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: const Color(0xFF303030),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: file == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cloud_upload_outlined,
                                    size: 42,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 28),
                                  Text(
                                    'Click to Upload',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              )
                            : MediaPreview(
                                isVideo: PortfolioViewModel.isVideo(file),
                                imageBytes: vm.selectedFileData,
                                videoController: vm.videoController,
                                isVideoLoading: vm.isVideoLoading,
                                onReturnFromFullscreen: () async {
                                  if (mounted &&
                                      PortfolioViewModel.isVideo(file) &&
                                      vm.selectedFile?.path == file.path) {
                                    await vm.loadVideoPreview(
                                      file,
                                      onError: showMessage,
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                  ),
                ),

                if (file != null) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      '${PortfolioViewModel.isVideo(file) ? 'Video' : 'Photo'} - '
                      '${PortfolioViewModel.formatSize(vm.selectedFileBytes)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Center(
                    child: TextButton.icon(
                      onPressed: vm.isUploading
                          ? null
                          : () =>
                              vm.pickPortfolioContent(onMessage: showMessage),
                      icon: const Icon(Icons.swap_horiz, color: _yellow),
                      label: const Text(
                        'Change file',
                        style: TextStyle(color: _yellow),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // TITLE
                const Text(
                  'Portfolio Title',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  enabled: !vm.isUploading,
                  maxLength: PortfolioViewModel.maxTitleLength,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter portfolio title',
                    hintStyle: const TextStyle(color: Colors.white54),
                    counterText: '',
                    filled: true,
                    fillColor: const Color(0xFF202020),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: _yellow),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // CATEGORIES
                const Center(
                  child: Text(
                    'Categories',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 18),

                Center(
                  child: vm.isLoadingCategories
                      ? const CircularProgressIndicator(color: _yellow)
                      : vm.categories.isEmpty
                          ? const Text(
                              'No categories available',
                              style: TextStyle(color: Colors.white70),
                            )
                          : Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: _yellow,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButton<String>(
                                value: vm.selectedCategoryId,
                                hint: const Text(
                                  'Choose a category',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                                dropdownColor: _yellow,
                                underline: const SizedBox(),
                                icon: const Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black,
                                ),
                                items: vm.categories.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Text(
                                      category.name,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: vm.isUploading
                                    ? null
                                    : (value) =>
                                        vm.setSelectedCategoryId(value),
                              ),
                            ),
                ),

                const SizedBox(height: 12),

                // ADD / MANAGE CATEGORY BUTTONS
                Center(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed:
                            vm.isUploading ? null : showAddCategoryDialog,
                        icon: const Icon(Icons.add, color: _yellow),
                        label: const Text(
                          'Add Category',
                          style: TextStyle(color: _yellow),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _yellow),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: vm.isUploading
                            ? null
                            : showManageCategoriesDialog,
                        icon: const Icon(Icons.edit_outlined, color: _yellow),
                        label: const Text(
                          'Manage Categories',
                          style: TextStyle(color: _yellow),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _yellow),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 55),

                // UPLOAD BUTTON
                Center(
                  child: SizedBox(
                    width: 230,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: vm.isUploading
                          ? null
                          : () {
                              vm.uploadPortfolioContent(
                                titleText: titleController.text,
                                onMessage: showMessage,
                                onSuccess: () => titleController.clear(),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey.shade700,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: vm.isUploading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Upload Content',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // CANCEL BUTTON
                Center(
                  child: SizedBox(
                    width: 230,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: vm.isUploading
                          ? null
                          : () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: _yellow),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns and disposes its own TextEditingController.
class _RenameCategoryDialog extends StatefulWidget {
  const _RenameCategoryDialog({required this.initial});

  final String initial;

  @override
  State<_RenameCategoryDialog> createState() => _RenameCategoryDialogState();
}

class _RenameCategoryDialogState extends State<_RenameCategoryDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename category'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: PortfolioViewModel.maxCategoryLength,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}