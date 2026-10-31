import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import '/models/portfolio_model.dart';
import '../services/portfolio_service.dart';

class PortfolioViewModel extends ChangeNotifier {
  final PortfolioService _service = PortfolioService();
  final ImagePicker picker = ImagePicker();

  static const int maxFileBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxCategoryLength = 50;
  static const int maxTitleLength = 100;

  static const Map<String, String> imageTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static const Map<String, String> videoTypes = {
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
  };

  List<PortfolioCategory> categories = [];
  String? selectedCategoryId;
  XFile? selectedFile;
  int? selectedFileBytes;
  Uint8List? selectedFileData;

  VideoPlayerController? videoController;
  bool isVideoLoading = false;
  bool isLoadingCategories = true;
  bool isUploading = false;

  // HELPERS
  static String extensionOf(String pathOrName) {
    final name = pathOrName.split(RegExp(r'[\\/]')).last;
    final dot = name.lastIndexOf('.');
    return dot == -1 ? '' : name.substring(dot + 1).toLowerCase();
  }

  static String extensionFor(XFile file) {
    final fromPath = extensionOf(file.path);
    return fromPath.isNotEmpty ? fromPath : extensionOf(file.name);
  }

  static bool isVideo(XFile file) => videoTypes.containsKey(extensionFor(file));

  static String formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String friendlyError(Object error) {
    debugPrint('Portfolio error: $error');

    if (error is PortfolioError) return error.message;
    if (error is PostgrestException) {
      switch (error.code) {
        case '42501':
          return 'You do not have permission to do that.';
        case '23505':
          return 'A record with the same information already exists.';
        case '23503':
          return 'A related record could not be found.';
        case '22P02':
          return 'One of the values provided is invalid.';
      }
    }

    if (error is StorageException) {
      final code = error.statusCode;
      if (code == '413') return 'That file is too large for the server.';
      if (code == '401' || code == '403') {
        return 'You do not have permission to upload files.';
      }
    }

    return 'Something went wrong. Please check your connection and try again.';
  }

  Future<void> disposeVideo() async {
    final controller = videoController;
    if (controller == null) return;

    videoController = null;
    notifyListeners();
    await controller.dispose();
  }

  Future<void> loadVideoPreview(
    XFile file, {
    void Function(String)? onError,
  }) async {
    isVideoLoading = true;
    notifyListeners();

    VideoPlayerController? controller;

    try {
      controller = kIsWeb
          ? VideoPlayerController.networkUrl(Uri.parse(file.path))
          : VideoPlayerController.file(File(file.path));

      await controller.initialize();
      await controller.setLooping(true);

      if (selectedFile?.path != file.path) {
        await controller.dispose();
        return;
      }

      final previousController = videoController;
      videoController = controller;

      if (previousController != null) {
        await previousController.dispose();
      }
    } catch (e) {
      debugPrint('Video preview failed: $e');

      if (controller != null) {
        await controller.dispose();
      }

      onError?.call('Could not preview this video. Please try another video.');
    } finally {
      isVideoLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCategories({void Function(String)? onError}) async {
    isLoadingCategories = true;
    notifyListeners();

    try {
      categories = await _service.fetchCategories();
    } catch (e) {
      onError?.call('Could not load categories. Please try again.');
      debugPrint('Load categories failed: $e');
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  void _sortCategories() {
    categories.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );
  }

  Future<void> addCategory(
    String categoryName, {
    required void Function(String) onMessage,
  }) async {
    final name = categoryName.trim();

    if (name.isEmpty) {
      onMessage('Please enter a category name.');
      return;
    }

    if (name.length > maxCategoryLength) {
      onMessage(
        'Category name is too long. Maximum length is $maxCategoryLength characters.',
      );
      return;
    }

    final existingIndex = categories.indexWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );

    if (existingIndex != -1) {
      selectedCategoryId = categories[existingIndex].id;
      notifyListeners();
      onMessage(const DuplicateCategoryError().message);
      return;
    }

    try {
      final inserted = await _service.insertCategory(name);

      categories.add(PortfolioCategory.fromMap(inserted));
      _sortCategories();

      selectedCategoryId = inserted['category_id'].toString();
      notifyListeners();

      onMessage('Category added successfully!');
    } on PostgrestException catch (e) {
      // 23505 = unique violation (e.g. created by another session)
      onMessage(
        e.code == '23505'
            ? const DuplicateCategoryError().message
            : friendlyError(e),
      );
    } catch (e) {
      onMessage(friendlyError(e));
    }
  }

  Future<void> renameCategory(
    String id,
    String newName, {
    required void Function(String) onMessage,
  }) async {
    final name = newName.trim();

    if (name.isEmpty) {
      onMessage('Please enter a category name.');
      return;
    }

    if (name.length > maxCategoryLength) {
      onMessage(
        'Category name is too long. Maximum length is $maxCategoryLength characters.',
      );
      return;
    }

    final index = categories.indexWhere((c) => c.id == id);
    if (index != -1 && categories[index].name == name) {
      return; // nothing changed
    }

    final duplicate = categories.any(
      (c) => c.id != id && c.name.toLowerCase() == name.toLowerCase(),
    );

    if (duplicate) {
      onMessage(const DuplicateCategoryError().message);
      return;
    }

    try {
      await _service.updateCategory(id, name);

      if (index != -1) {
        categories[index] = PortfolioCategory(id: id, name: name);
      }
      _sortCategories();
      notifyListeners();

      onMessage('Category updated.');
    } on PostgrestException catch (e) {
      onMessage(
        e.code == '23505'
            ? const DuplicateCategoryError().message
            : friendlyError(e),
      );
    } catch (e) {
      onMessage(friendlyError(e));
    }
  }

  Future<void> removeCategory(
    String id, {
    required void Function(String) onMessage,
  }) async {
    try {
      await _service.deleteCategory(id);

      categories.removeWhere((c) => c.id == id);
      if (selectedCategoryId == id) selectedCategoryId = null;
      notifyListeners();

      onMessage('Category removed.');
    } on PostgrestException catch (e) {
      // 23503 = foreign key violation: portfolio items still use this category
      if (e.code == '23503') {
        debugPrint('Portfolio error: $e');
        onMessage(
          'This category still has portfolio items. Move or delete them first.',
        );
      } else {
        onMessage(friendlyError(e));
      }
    } catch (e) {
      onMessage(friendlyError(e));
    }
  }

  Future<void> pickPortfolioContent({
    required void Function(String) onMessage,
  }) async {
    try {
      final XFile? file = await picker.pickMedia();

      if (file == null) return;

      final extension = extensionFor(file);
      final allowed =
          imageTypes.containsKey(extension) ||
          videoTypes.containsKey(extension);

      if (!allowed) {
        onMessage('Unsupported file type. Use JPG, PNG, WebP, MP4 or MOV.');
        return;
      }

      final fileSize = await file.length();

      if (fileSize > maxFileBytes) {
        onMessage('That file is too large. The maximum size is 50 MB.');
        return;
      }

      final fileData = await file.readAsBytes();

      await disposeVideo();

      selectedFile = file;
      selectedFileBytes = fileSize;
      selectedFileData = fileData;
      notifyListeners();

      if (videoTypes.containsKey(extension)) {
        await loadVideoPreview(file, onError: onMessage);
      }
    } catch (e) {
      onMessage(friendlyError(e));
    }
  }

  void setSelectedCategoryId(String? value) {
    selectedCategoryId = value;
    notifyListeners();
  }

  Future<void> uploadPortfolioContent({
    required String titleText,
    required void Function(String) onMessage,
    required VoidCallback onSuccess,
  }) async {
    final file = selectedFile;
    final categoryId = selectedCategoryId;
    final title = titleText.trim();

    if (file == null) {
      onMessage('Please select a photo or video.');
      return;
    }

    if (categoryId == null) {
      onMessage('Please select a category.');
      return;
    }

    if (title.isEmpty) {
      onMessage('Please enter a title.');
      return;
    }

    if (title.length > maxTitleLength) {
      onMessage(
        'Title is too long. Maximum length is $maxTitleLength characters.',
      );
      return;
    }

    isUploading = true;
    notifyListeners();

    await videoController?.pause();

    String? uploadedPath;

    try {
      final String adminId = await _service.requireAdminId();

      final String extension = extensionFor(file);
      final String? contentType =
          imageTypes[extension] ?? videoTypes[extension];

      if (contentType == null) {
        throw const PortfolioError(
          'Unsupported file type. Use JPG, PNG, WebP, MP4 or MOV.',
        );
      }

      final String mediaType = videoTypes.containsKey(extension)
          ? 'video'
          : 'image';

      final fileData = selectedFileData;

      if (fileData == null) {
        throw const PortfolioError(
          'Could not read the selected file. Please select it again.',
        );
      }

      if (fileData.length > maxFileBytes) {
        throw const PortfolioError(
          'That file is too large. The maximum size is 50 MB.',
        );
      }

      final String path =
          '$categoryId/${DateTime.now().microsecondsSinceEpoch}.$extension';

      final String mediaUrl = await _service.uploadFile(
        path: path,
        fileData: fileData,
        contentType: contentType,
      );

      uploadedPath = path;

      await _service.insertPortfolioItem(
        adminId: adminId,
        categoryId: categoryId,
        title: title,
        mediaUrl: mediaUrl,
        mediaType: mediaType,
      );

      onMessage('Portfolio content uploaded successfully!');

      selectedFile = null;
      selectedFileBytes = null;
      selectedFileData = null;
      selectedCategoryId = null;

      await disposeVideo();
      onSuccess();
    } catch (e) {
      if (uploadedPath != null) {
        await _service.removeFile(uploadedPath);
      }
      onMessage(friendlyError(e));
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    final controller = videoController;
    videoController = null;

    controller?.dispose();

    super.dispose();
  }
}