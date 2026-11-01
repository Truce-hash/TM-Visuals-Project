import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/portfolio_model.dart';
import '../viewmodels/portfolio_gallery_viewmodel.dart';
import '../widgets/portfolio_widgets.dart';

enum _ItemAction { edit, delete }

class PortfolioGalleryScreen extends StatelessWidget {
  const PortfolioGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PortfolioGalleryViewModel()..loadGallery(),
      child: const _PortfolioGalleryContent(),
    );
  }
}

class _PortfolioGalleryContent extends StatelessWidget {
  const _PortfolioGalleryContent();

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;

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

  Future<void> _editItem(BuildContext context, PortfolioItem item) async {
    final vm = context.read<PortfolioGalleryViewModel>();

    final result = await showDialog<PortfolioItemEdit>(
      context: context,
      builder: (_) => EditPortfolioItemDialog(
        item: item,
        categories: vm.categories,
        maxTitleLength: PortfolioGalleryViewModel.maxTitleLength,
      ),
    );

    if (result == null || !context.mounted) return;

    await vm.updateItem(
      item,
      title: result.title,
      categoryId: result.categoryId,
      onMessage: (m) => _showMessage(context, m),
    );
  }

  Future<void> _deleteItem(BuildContext context, PortfolioItem item) async {
    final vm = context.read<PortfolioGalleryViewModel>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF202020),
        title: Text(
          'Delete "${item.title}"?',
          style: const TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This removes the item and its file permanently. '
          'This cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await vm.deleteItem(
      item,
      onMessage: (m) => _showMessage(context, m),
    );
  }

  void _openViewer(BuildContext context, PortfolioItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteMediaViewer(
          url: item.mediaLocation,
          isVideo: item.isVideo,
        ),
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
    PortfolioGalleryViewModel vm,
    PortfolioItem item,
  ) {
    if (!vm.isAdmin) {
      return const Icon(Icons.fullscreen, color: Colors.orange);
    }

    return PopupMenuButton<_ItemAction>(
      enabled: !vm.isBusy,
      tooltip: 'More options',
      color: const Color(0xFF292929),
      icon: const Icon(Icons.more_vert, color: Colors.orange),
      onSelected: (action) {
        switch (action) {
          case _ItemAction.edit:
            _editItem(context, item);
          case _ItemAction.delete:
            _deleteItem(context, item);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: _ItemAction.edit,
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.orange, size: 20),
              SizedBox(width: 12),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: _ItemAction.delete,
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, PortfolioGalleryViewModel vm) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Text(
          vm.errorMessage!,
          style: const TextStyle(color: Colors.redAccent),
        ),
      );
    }

    if (vm.items.isEmpty) {
      return const Center(
        child: Text(
          'No portfolio items yet.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      itemCount: vm.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = vm.items[index];
        final category = vm.categoryName(item.categoryId);
        final kind = item.isVideo ? 'Video' : 'Image';

        return Card(
          color: const Color(0xFF1C1C1C),
          child: ListTile(
            leading: PortfolioThumbnail(
              isVideo: item.isVideo,
              url: item.mediaLocation,
            ),
            title: Text(
              item.title,
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              category.isEmpty ? kind : '$kind • $category',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: _buildTrailing(context, vm, item),
            onTap: () => _openViewer(context, item),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PortfolioGalleryViewModel>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Portfolio gallery',
          style: TextStyle(color: Colors.orange),
        ),
      ),
      body: Column(
        children: [
          if (vm.isBusy)
            const LinearProgressIndicator(
              color: Colors.orange,
              backgroundColor: Colors.transparent,
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _buildBody(context, vm),
            ),
          ),
        ],
      ),
    );
  }
}
