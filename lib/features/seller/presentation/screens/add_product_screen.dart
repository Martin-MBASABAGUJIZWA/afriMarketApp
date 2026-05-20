import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
import 'package:afrimarket/core/services/product_image_service.dart';
import 'package:afrimarket/features/seller/presentation/providers/seller_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/marketplace_providers.dart';
import 'package:afrimarket/features/marketplace/presentation/providers/category_provider.dart';
import 'package:afrimarket/features/marketplace/domain/entities/category_entity.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/core/errors/exceptions.dart' as app_exceptions;

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  CategoryEntity? _selectedCategory;
  String _selectedUnit = 'each';
  final List<XFile> _selectedImages = [];

  // Upload state
  bool _isSaving = false;
  int _uploadingIndex = -1; // which image is currently uploading (-1 = not uploading)
  int _uploadTotal = 0;
  String? _uploadError;

  static const _units = ['each', 'kg', 'g', 'litre', 'bundle', 'piece'];
  static const _maxImages = 5;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // Image picking
  // ──────────────────────────────────────────────────────────

  Future<void> _pickGallery() async {
    final remaining = _maxImages - _selectedImages.length;
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage(limit: remaining);
    if (images.isEmpty) return;

    // Validate each image before adding it to the list
    final valid = <XFile>[];
    final errors = <String>[];
    for (final img in images) {
      try {
        await ProductImageService.validate(img);
        valid.add(img);
      } on ProductImageValidationError catch (e) {
        errors.add('${img.name}: $e');
      }
    }

    setState(() {
      _selectedImages.addAll(valid);
      if (_selectedImages.length > _maxImages) {
        _selectedImages.removeRange(_maxImages, _selectedImages.length);
      }
      _uploadError = errors.isNotEmpty ? errors.join('\n') : null;
    });
  }

  Future<void> _pickCamera() async {
    if (_selectedImages.length >= _maxImages) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (image == null) return;

    try {
      await ProductImageService.validate(image);
      setState(() {
        _selectedImages.add(image);
        _uploadError = null;
      });
    } on ProductImageValidationError catch (e) {
      setState(() => _uploadError = e.toString());
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ──────────────────────────────────────────────────────────
  // Save product
  // ──────────────────────────────────────────────────────────

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      setState(() => _uploadError = 'Please select a category');
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadError = null;
      _uploadingIndex = -1;
      _uploadTotal = _selectedImages.length;
    });

    try {
      final sellerAsync = ref.read(currentUserSellerProvider);
      final seller = sellerAsync.value;
      if (seller == null) {
        throw app_exceptions.ServerException('No seller account found');
      }

      final imageUrls = <String>[];

      if (SupabaseService.isInitialized && _selectedImages.isNotEmpty) {
        final urls = await ProductImageService.uploadAll(
          sellerId: seller.id,
          files: _selectedImages,
          onProgress: (index, total) {
            if (mounted) setState(() => _uploadingIndex = index);
          },
          onError: (index, error) {
            // Skip failed uploads — product saves without that image
          },
        );
        imageUrls.addAll(urls);
      }

      if (mounted) setState(() => _uploadingIndex = -1);

      await ref.read(marketplaceRepositoryProvider).createProduct(
            sellerId: seller.id,
            name: _nameController.text.trim(),
            categoryId: _selectedCategory!.id,
            price: double.parse(_priceController.text.trim()),
            stockQuantity: int.parse(_stockController.text.trim()),
            description: _descController.text.trim().isEmpty
                ? null
                : _descController.text.trim(),
            unit: _selectedUnit,
            imageUrls: imageUrls,
          );

      if (mounted) {
        ref.invalidate(currentUserSellerProvider);
        ref.invalidate(sellerProductsProvider(seller.id));
        ref.invalidate(featuredProductsProvider);
        ref.invalidate(productsProvider(null));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added!', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/seller-dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadError = 'Failed to save: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ──────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Add Product',
            style: GoogleFonts.poppins(
                fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/seller-dashboard'),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _saveProduct,
              child: Text('Save',
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Image upload section ───────────────────────────────
            _SectionCard(
              title: 'Product Photos',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add up to $_maxImages photos · JPG, PNG, WebP · Max 5MB each',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  // Image previews + add buttons
                  _ImagePickerRow(
                    images: _selectedImages,
                    uploadingIndex: _uploadingIndex,
                    uploadTotal: _uploadTotal,
                    maxImages: _maxImages,
                    onRemove: _removeImage,
                    onPickGallery: _pickGallery,
                    onPickCamera: _pickCamera,
                  ),

                  if (_uploadError != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppTheme.errorRed.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16, color: AppTheme.errorRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_uploadError!,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: AppTheme.errorRed)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Product details ────────────────────────────────────
            _SectionCard(
              title: 'Product Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Fresh Tomatoes',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Product name is required'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText:
                          'Describe freshness, origin, quality...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Consumer(builder: (context, ref, _) {
                    final catsAsync = ref.watch(categoriesProvider);
                    return catsAsync.when(
                      data: (cats) {
                        if (_selectedCategory == null &&
                            cats.isNotEmpty) {
                          WidgetsBinding.instance
                              .addPostFrameCallback((_) {
                            if (mounted) {
                              setState(
                                  () => _selectedCategory = cats.first);
                            }
                          });
                        }
                        return DropdownButtonFormField<CategoryEntity>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category *',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: cats
                              .map((cat) => DropdownMenuItem(
                                    value: cat,
                                    child: Row(children: [
                                      Text(cat.icon ?? '🛒'),
                                      const SizedBox(width: 8),
                                      Text(cat.name,
                                          style: GoogleFonts.poppins(
                                              fontSize: 14)),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedCategory = v),
                          validator: (v) => v == null
                              ? 'Please select a category'
                              : null,
                        );
                      },
                      loading: () =>
                          const LinearProgressIndicator(),
                      error: (_, __) => TextFormField(
                        enabled: false,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'Could not load categories',
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Pricing ────────────────────────────────────────────
            _SectionCard(
              title: 'Pricing & Inventory',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price (RWF) *',
                            hintText: '0',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Price is required';
                            }
                            if (double.tryParse(v.trim()) == null) {
                              return 'Enter a valid number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration:
                              const InputDecoration(labelText: 'Unit'),
                          items: _units
                              .map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u,
                                        style: GoogleFonts.poppins(
                                            fontSize: 13)),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedUnit = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity *',
                      hintText: '0',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Stock quantity is required';
                      }
                      if (int.tryParse(v.trim()) == null) {
                        return 'Enter a whole number';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProduct,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18)),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _uploadingIndex >= 0
                                ? 'Uploading photo ${_uploadingIndex + 1} of $_uploadTotal...'
                                : 'Saving...',
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      )
                    : Text('Save Product',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Image picker row widget
// ──────────────────────────────────────────────────────────

class _ImagePickerRow extends StatelessWidget {
  final List<XFile> images;
  final int uploadingIndex;
  final int uploadTotal;
  final int maxImages;
  final ValueChanged<int> onRemove;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;

  const _ImagePickerRow({
    required this.images,
    required this.uploadingIndex,
    required this.uploadTotal,
    required this.maxImages,
    required this.onRemove,
    required this.onPickGallery,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...images.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            final isUploading = uploadingIndex == i;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _ImagePreviewTile(
                file: file,
                isUploading: isUploading,
                onRemove: () => onRemove(i),
              ),
            );
          }),
          if (images.length < maxImages)
            Row(
              children: [
                _AddImageButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: onPickGallery,
                ),
                const SizedBox(width: 10),
                // Camera only on native (web doesn't have access to device camera via image_picker the same way)
                if (!kIsWeb)
                  _AddImageButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: onPickCamera,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ImagePreviewTile extends StatelessWidget {
  final XFile file;
  final bool isUploading;
  final VoidCallback onRemove;

  const _ImagePreviewTile({
    required this.file,
    required this.isUploading,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(
                    file.path,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : Image.file(
                    File(file.path),
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  ),
          ),
          // Upload progress overlay
          if (isUploading)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          // Remove button
          if (!isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 13, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(0xFFE8F5E9),
      child: const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.grey, size: 32),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// Shared UI helpers
// ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddImageButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.primaryGreen,
              width: 1.5,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE8F5E9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: AppTheme.primaryGreen),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryGreen)),
          ],
        ),
      ),
    );
  }
}
