import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:afrimarket/core/services/supabase_service.dart';

class ProductImageValidationError implements Exception {
  final String message;
  const ProductImageValidationError(this.message);
  @override
  String toString() => message;
}

class ProductImageUploadResult {
  final String url;
  final String storagePath;
  const ProductImageUploadResult({required this.url, required this.storagePath});
}

// Central service for product image upload, validation, and deletion.
// All uploads go to the 'products' Supabase Storage bucket.
// Bucket must have authenticated-write + public-read policies in Supabase dashboard.
class ProductImageService {
  static const String bucket = 'products';
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB
  static const Set<String> allowedExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  static SupabaseClient get _client => SupabaseService.client;

  // Validates type and size. Throws [ProductImageValidationError] on failure.
  static Future<void> validate(XFile file) async {
    final nameLower = file.name.toLowerCase();
    final ext = nameLower.contains('.')
        ? '.${nameLower.split('.').last}'
        : '';

    if (!allowedExtensions.contains(ext)) {
      throw ProductImageValidationError(
        'Unsupported file type "$ext". Use JPG, PNG, or WebP.',
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > maxFileSizeBytes) {
      final mb = (bytes.length / (1024 * 1024)).toStringAsFixed(1);
      throw ProductImageValidationError(
        'Image too large (${mb}MB). Maximum size is 5MB.',
      );
    }
  }

  // Uploads one image to the products bucket under {sellerId}/{timestamp}.{ext}.
  // Returns the public URL and storage path.
  // Caller must be authenticated — Supabase RLS enforces this on the bucket.
  static Future<ProductImageUploadResult> upload({
    required String sellerId,
    required XFile file,
  }) async {
    await validate(file);

    final nameLower = file.name.toLowerCase();
    final ext = nameLower.contains('.') ? '.${nameLower.split('.').last}' : '.jpg';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storagePath = '$sellerId/${timestamp}$ext';

    final bytes = await file.readAsBytes();

    await _client.storage.from(bucket).uploadBinary(
      storagePath,
      bytes,
      fileOptions: FileOptions(
        contentType: _contentType(ext),
        upsert: false,
      ),
    );

    final url = _client.storage.from(bucket).getPublicUrl(storagePath);
    return ProductImageUploadResult(url: url, storagePath: storagePath);
  }

  // Uploads multiple images, returning successful URLs in order.
  // Failed uploads are skipped (logged to onError callback).
  static Future<List<String>> uploadAll({
    required String sellerId,
    required List<XFile> files,
    void Function(int index, String error)? onError,
    void Function(int index, int total)? onProgress,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      onProgress?.call(i, files.length);
      try {
        final result = await upload(sellerId: sellerId, file: files[i]);
        urls.add(result.url);
      } catch (e) {
        onError?.call(i, e.toString());
      }
    }
    return urls;
  }

  // Deletes an image by its storage path (not its public URL).
  static Future<void> deleteByPath(String storagePath) async {
    try {
      await _client.storage.from(bucket).remove([storagePath]);
    } catch (_) {}
  }

  // Extracts the storage path from a Supabase public URL so it can be deleted.
  // URL format: https://{project}.supabase.co/storage/v1/object/public/products/{path}
  static String? storagePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final idx = segments.indexOf(bucket);
      if (idx == -1 || idx + 1 >= segments.length) return null;
      return segments.skip(idx + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  // Deletes images by their public URLs (for product update/delete flows).
  static Future<void> deleteUrls(List<String> urls) async {
    for (final url in urls) {
      final path = storagePathFromUrl(url);
      if (path != null) await deleteByPath(path);
    }
  }

  static String _contentType(String ext) {
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
