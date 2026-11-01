import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/portfolio_model.dart';

const Color yellowColor = Color(0xFFFFB900);

// DIALOG WIDGET
class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({super.key, required this.maxLength});

  final int maxLength;

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();

    if (name.isEmpty) {
      setState(() => _error = 'Please enter a category name.');
      return;
    }

    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF202020),
      title: const Text('Add Category', style: TextStyle(color: Colors.white)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: widget.maxLength,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter category name',
          hintStyle: const TextStyle(color: Colors.white54),
          errorText: _error,
          counterText: '',
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: yellowColor),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: yellowColor,
            foregroundColor: Colors.black,
          ),
          onPressed: _submit,
          child: const Text('Save Category'),
        ),
      ],
    );
  }
}

// FULLSCREEN MEDIA PREVIEW WIDGET (shared by upload screen and gallery)
class FullscreenMediaPreview extends StatelessWidget {
  const FullscreenMediaPreview({
    super.key,
    required this.isVideo,
    this.controller,
    this.imageBytes,
    this.imageUrl,
  });

  final bool isVideo;
  final VideoPlayerController? controller;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(isVideo ? 'Video Preview' : 'Photo Preview'),
      ),
      body: Center(
        child: isVideo ? _buildVideoPreview() : _buildImagePreview(),
      ),
    );
  }

  Widget _buildImagePreview() {
    const broken = Icon(Icons.broken_image, color: Colors.white54, size: 60);

    final Widget? image = imageBytes != null
        ? Image.memory(
            imageBytes!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => broken,
          )
        : imageUrl != null
            ? Image.network(
                imageUrl!,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => broken,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: yellowColor),
                      ),
              )
            : null;

    if (image == null) return broken;

    return InteractiveViewer(minScale: 1, maxScale: 5, child: image);
  }

  Widget _buildVideoPreview() {
    final videoController = controller;

    if (videoController == null || !videoController.value.isInitialized) {
      return const CircularProgressIndicator(color: yellowColor);
    }

    return Center(
      child: AspectRatio(
        aspectRatio: videoController.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(videoController),
            ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: videoController,
              builder: (context, value, _) {
                return IconButton(
                  tooltip: value.isPlaying ? 'Pause video' : 'Play video',
                  iconSize: 70,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                  ),
                  onPressed: () {
                    value.isPlaying
                        ? videoController.pause()
                        : videoController.play();
                  },
                );
              },
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: VideoProgressIndicator(
                videoController,
                allowScrubbing: true,
                colors: const VideoProgressColors(playedColor: yellowColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// INLINE MEDIA PREVIEW WIDGET (upload screen)
// No longer depends on XFile or PortfolioViewModel.
class MediaPreview extends StatelessWidget {
  const MediaPreview({
    super.key,
    required this.isVideo,
    this.imageBytes,
    this.videoController,
    this.isVideoLoading = false,
    this.onReturnFromFullscreen,
  });

  final bool isVideo;
  final Uint8List? imageBytes;
  final VideoPlayerController? videoController;
  final bool isVideoLoading;
  final Future<void> Function()? onReturnFromFullscreen;

  @override
  Widget build(BuildContext context) {
    if (!isVideo) {
      if (imageBytes == null) {
        return const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 42),
        );
      }
      return Image.memory(
        imageBytes!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 42),
        ),
      );
    }

    if (isVideoLoading) {
      return const Center(child: CircularProgressIndicator(color: yellowColor));
    }

    final controller = videoController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: Icon(Icons.video_file, color: yellowColor, size: 45),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: controller,
          builder: (context, value, _) => Center(
            child: IconButton(
              tooltip: value.isPlaying ? 'Pause video' : 'Play video',
              iconSize: 55,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                foregroundColor: Colors.white,
              ),
              icon: Icon(
                value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_fill,
              ),
              onPressed: () =>
                  value.isPlaying ? controller.pause() : controller.play(),
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: IconButton(
            tooltip: 'View full screen',
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.fullscreen),
            onPressed: () async {
              await controller.pause();
              if (!context.mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullscreenMediaPreview(
                    isVideo: true,
                    controller: controller,
                  ),
                ),
              );
              await onReturnFromFullscreen?.call();
            },
          ),
        ),
      ],
    );
  }
}

// FULLSCREEN VIEWER FOR REMOTE MEDIA (gallery)
// Owns and disposes its own VideoPlayerController.
class RemoteMediaViewer extends StatefulWidget {
  const RemoteMediaViewer({
    super.key,
    required this.url,
    required this.isVideo,
  });

  final String url;
  final bool isVideo;

  @override
  State<RemoteMediaViewer> createState() => _RemoteMediaViewerState();
}

class _RemoteMediaViewerState extends State<RemoteMediaViewer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller = controller;

    try {
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) return;
      setState(() {});
      await controller.play();
    } catch (e) {
      debugPrint('Remote video failed: $e');
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Could not load this video.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return FullscreenMediaPreview(
      isVideo: widget.isVideo,
      controller: _controller,
      imageUrl: widget.isVideo ? null : widget.url,
    );
  }
}

// GALLERY THUMBNAIL (no video controllers in lists)
class PortfolioThumbnail extends StatelessWidget {
  const PortfolioThumbnail({
    super.key,
    required this.isVideo,
    required this.url,
    this.size = 56,
  });

  final bool isVideo;
  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: size,
        height: size,
        child: isVideo
            ? const ColoredBox(
                color: Color(0xFF303030),
                child: Icon(Icons.play_circle_fill, color: yellowColor),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: Color(0xFF303030),
                  child: Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
      ),
    );
  }
}

// EDIT PORTFOLIO ITEM DIALOG (gallery)
class PortfolioItemEdit {
  const PortfolioItemEdit({required this.title, required this.categoryId});

  final String title;
  final String categoryId;
}

class EditPortfolioItemDialog extends StatefulWidget {
  const EditPortfolioItemDialog({
    super.key,
    required this.item,
    required this.categories,
    required this.maxTitleLength,
  });

  final PortfolioItem item;
  final List<PortfolioCategory> categories;
  final int maxTitleLength;

  @override
  State<EditPortfolioItemDialog> createState() =>
      _EditPortfolioItemDialogState();
}

class _EditPortfolioItemDialogState extends State<EditPortfolioItemDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.item.title);

  late String? _categoryId =
      widget.categories.any((c) => c.id == widget.item.categoryId)
          ? widget.item.categoryId
          : null;

  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _controller.text.trim();
    final categoryId = _categoryId;

    if (title.isEmpty) {
      setState(() => _error = 'Please enter a title.');
      return;
    }

    if (categoryId == null) {
      setState(() => _error = 'Please choose a category.');
      return;
    }

    Navigator.pop(
      context,
      PortfolioItemEdit(title: title, categoryId: categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF202020),
      title: const Text('Edit Item', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: widget.maxTitleLength,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(color: Colors.white70),
                errorText: _error,
                counterText: '',
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: yellowColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Category',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            DropdownButton<String>(
              isExpanded: true,
              value: _categoryId,
              hint: const Text(
                'Choose a category',
                style: TextStyle(color: Colors.white54),
              ),
              dropdownColor: const Color(0xFF303030),
              underline: Container(height: 1, color: Colors.grey),
              icon: const Icon(Icons.arrow_drop_down, color: yellowColor),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.id,
                      child: Text(
                        c.name,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                _categoryId = value;
                _error = null;
              }),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: yellowColor,
            foregroundColor: Colors.black,
          ),
          onPressed: _submit,
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}
