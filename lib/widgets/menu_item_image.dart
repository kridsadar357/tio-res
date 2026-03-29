import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/image_storage_service.dart';

/// MenuItemImage: Helper widget for rendering menu item images
/// 
/// Features:
/// - Handles null/empty image paths with placeholder
/// - Verifies file existence before rendering
/// - Graceful error handling for corrupted files
/// - Uses BoxFit.cover for consistent appearance
class MenuItemImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const MenuItemImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    // Case 1: No image path provided
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    return FutureBuilder<File?>(
      future: ImageStorageService().getImageFile(imagePath!),
      builder: (context, snapshot) {
        // Case 2: Error loading image
        if (snapshot.hasError) {
          return _buildPlaceholder(
            error: true,
            errorMessage: 'Error loading image',
          );
        }

        // Case 3: Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }

        // Case 4: File not found
        if (!snapshot.hasData || snapshot.data == null) {
          return _buildPlaceholder(
            error: true,
            errorMessage: 'Image not found',
          );
        }

        final file = snapshot.data!;

        // Case 5: Verify file exists
        if (!file.existsSync()) {
          return _buildPlaceholder(
            error: true,
            errorMessage: 'File missing',
          );
        }

        // Case 6: Render actual image
        return _buildImage(file);
      },
    );
  }

  /// Build the actual image widget
  Widget _buildImage(File file) {
    final imageWidget = Image.file(
      file,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: width?.toInt(),
      cacheHeight: height?.toInt(),
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder(
          error: true,
          errorMessage: 'Corrupted image',
        );
      },
    );

    // Wrap with size constraints if specified
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Build placeholder when no image or error occurs
  Widget _buildPlaceholder({bool error = false, String? errorMessage}) {
    final container = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: error ? Colors.red.shade50 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              error ? Icons.broken_image : Icons.image_outlined,
              size: (width ?? 100).sp * 0.4,
              color: error ? Colors.red.shade300 : Colors.grey.shade400,
            ),
            if (errorMessage != null) ...[
              SizedBox(height: 8.h),
              Text(
                errorMessage,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: error ? Colors.red.shade600 : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );

    return container;
  }

  /// Build loading placeholder
  Widget _buildLoading() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Factory constructor for use in GridView cards
  factory MenuItemImage.card({
    Key? key,
    required String? imagePath,
  }) {
    return MenuItemImage(
      key: key,
      imagePath: imagePath,
      width: double.infinity,
      height: 120.h,
      fit: BoxFit.cover,
    );
  }

  /// Factory constructor for small thumbnail
  factory MenuItemImage.thumbnail({
    Key? key,
    required String? imagePath,
    double size = 48.0,
  }) {
    return MenuItemImage(
      key: key,
      imagePath: imagePath,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  /// Factory constructor for list item thumbnail
  factory MenuItemImage.listItem({
    Key? key,
    required String? imagePath,
  }) {
    return MenuItemImage(
      key: key,
      imagePath: imagePath,
      width: 60.w,
      height: 60.h,
      fit: BoxFit.cover,
    );
  }
}

/// Alternative simple placeholder widget using asset
/// Use this if you want a static asset placeholder instead of dynamic widget
class AssetPlaceholderImage extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const AssetPlaceholderImage({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade400,
          ],
        ),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: (width ?? 100).sp * 0.4,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            SizedBox(height: 8.h),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
