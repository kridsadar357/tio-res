import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

/// ImageStorageService: Handles local storage of menu item images
///
/// Design Principles:
/// - Images are stored in the app's documents directory
/// - NOT stored as BLOBs in SQLite (to prevent DB bloat)
/// - File paths are stored in the database instead
/// - Each image gets a unique filename based on timestamp
class ImageStorageService {
  static final ImageStorageService _instance = ImageStorageService._internal();
  factory ImageStorageService() => _instance;
  ImageStorageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Directory name for storing menu images
  static const String _imageDirectoryName = 'menu_images';

  /// Get the application documents directory
  Future<Directory> _getAppDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  /// Get or create the menu images directory
  Future<Directory> _getImagesDirectory() async {
    final appDir = await _getAppDirectory();
    final imagesDir = Directory('${appDir.path}/$_imageDirectoryName');

    // Create directory if it doesn't exist
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    return imagesDir;
  }

  /// Generate a unique filename for an image
  /// Format: item_<timestamp>_<random>.jpg
  String _generateUniqueFileName({String? prefix}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final safePrefix = prefix?.replaceAll(RegExp(r'[^\w-]'), '') ?? 'item';
    return '${safePrefix}_$timestamp _$random.jpg';
  }

  /// Pick an image from the camera
  /// Returns null if user cancels or error occurs
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Balance quality and file size
        maxWidth: 1024, // Limit resolution for storage efficiency
        maxHeight: 1024,
      );

      if (photo == null) return null;

      return File(photo.path);
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error picking image from camera', error: e);
      }
      return null;
    }
  }

  /// Pick an image from the gallery
  /// Returns null if user cancels or error occurs
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error picking image from gallery', error: e);
      }
      return null;
    }
  }

  /// Save an image file to the local app directory
  ///
  /// Parameters:
  /// - imageFile: The source image file to save
  /// - itemId: Optional item ID for filename prefix
  /// - itemName: Optional item name for filename prefix
  ///
  /// Returns the relative path to the saved image (to store in DB)
  /// Returns null if save fails
  Future<String?> saveImage(File imageFile,
      {int? itemId, String? itemName}) async {
    try {
      final imagesDir = await _getImagesDirectory();

      // Generate unique filename
      final prefix = itemName ?? (itemId != null ? 'item_$itemId' : 'item');
      final filename = _generateUniqueFileName(prefix: prefix);

      // Copy image to app directory
      await imageFile.copy('${imagesDir.path}/$filename');

      // Store relative path (not absolute path) for better portability
      return '$_imageDirectoryName/$filename';
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error saving image', error: e);
      }
      return null;
    }
  }

  /// Get the full file path from a stored relative path
  Future<File?> getImageFile(String relativePath) async {
    try {
      final appDir = await _getAppDirectory();
      final fullPath = '${appDir.path}/$relativePath';
      final file = File(fullPath);

      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error getting image file', error: e);
      }
      return null;
    }
  }

  /// Delete an image file
  Future<bool> deleteImage(String relativePath) async {
    try {
      final appDir = await _getAppDirectory();
      final fullPath = '${appDir.path}/$relativePath';
      final file = File(fullPath);

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error deleting image', error: e);
      }
      return false;
    }
  }

  /// Delete all images in the menu images directory
  /// Useful for cleanup or reset operations
  Future<int> deleteAllImages() async {
    try {
      final imagesDir = await _getImagesDirectory();

      if (!await imagesDir.exists()) return 0;

      int deleteCount = 0;
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          await entity.delete();
          deleteCount++;
        }
      }

      return deleteCount;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error deleting all images', error: e);
      }
      return 0;
    }
  }

  /// Get the total size of all stored images (in bytes)
  Future<int> getTotalImagesSize() async {
    try {
      final imagesDir = await _getImagesDirectory();

      if (!await imagesDir.exists()) return 0;

      int totalSize = 0;
      await for (final entity in imagesDir.list()) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }

      return totalSize;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error calculating images size', error: e);
      }
      return 0;
    }
  }

  /// Get the number of stored images
  Future<int> getImagesCount() async {
    try {
      final imagesDir = await _getImagesDirectory();

      if (!await imagesDir.exists()) return 0;

      int count = 0;
      await for (final entity in imagesDir.list()) {
        if (entity is File) count++;
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error counting images', error: e);
      }
      return 0;
    }
  }

  /// Replace an existing image with a new one
  ///
  /// Parameters:
  /// - oldImagePath: Path of image to replace
  /// - newImageFile: New image file to save
  /// - itemId: Optional item ID for filename
  /// - itemName: Optional item name for filename
  ///
  /// Returns the new relative path, or null if save fails
  Future<String?> replaceImage(
    String oldImagePath,
    File newImageFile, {
    int? itemId,
    String? itemName,
  }) async {
    try {
      // Delete old image
      await deleteImage(oldImagePath);

      // Save new image
      return await saveImage(newImageFile, itemId: itemId, itemName: itemName);
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error replacing image', error: e);
      }
      return null;
    }
  }

  /// Copy an image from one path to another within the app directory
  Future<String?> copyImage(String sourceRelativePath,
      {String? newName}) async {
    try {
      final sourceFile = await getImageFile(sourceRelativePath);
      if (sourceFile == null) return null;

      final imagesDir = await _getImagesDirectory();
      final filename =
          newName ?? _generateUniqueFilenameFromPath(sourceRelativePath);

      await sourceFile.copy('${imagesDir.path}/$filename');
      return '$_imageDirectoryName/$filename';
    } catch (e) {
      if (kDebugMode) {
        Logger.error('Error copying image', error: e);
      }
      return null;
    }
  }

  /// Generate a unique filename based on an existing path
  String _generateUniqueFilenameFromPath(String path) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final baseName = path.split('/').last.split('.')[0];
    return '${baseName}_copy_$timestamp _$random.jpg';
  }

  /// Validate if an image file exists and is readable
  Future<bool> validateImage(String relativePath) async {
    try {
      final file = await getImageFile(relativePath);
      if (file == null) return false;

      // Try to read a small portion to verify it's a valid image
      final bytes = await file.openRead(0, 1024).first;
      return bytes.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating image: $e');
      return false;
    }
  }
}
