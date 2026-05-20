import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:afrimarket/core/theme/app_theme.dart';
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
  bool _isSaving = false;

  static const _units = ['each', 'kg', 'g', 'litre', 'bundle', 'piece'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(limit: 5);
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
        if (_selectedImages.length > 5) {
          _selectedImages.removeRange(5, _selectedImages.length);
        }
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null && _selectedImages.length < 5) {
      setState(() => _selectedImages.add(image));
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final sellerAsync = ref.read(currentUserSellerProvider);
      final seller = sellerAsync.value;

      if (seller == null) {
        throw app_exceptions.ServerException('No seller account found');
      }
      if (_selectedCategory == null) {
        throw app_exceptions.ServerException('Please select a category');
      }

      final imageUrls = <String>[];

      if (SupabaseService.isInitialized) {
        for (final image in _selectedImages) {
          try {
            final bytes = await image.readAsBytes();
            final fileName =
                '${seller.id}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
            await SupabaseService.client.storage
                .from('products')
                .uploadBinary(fileName, bytes);
            final url = SupabaseService.client.storage
                .from('products')
                .getPublicUrl(fileName);
            imageUrls.add(url);
          } catch (_) {}
        }

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
      }

      if (mounted) {
        // Refresh the seller's product list and featured products before navigating back
        ref.invalidate(currentUserSellerProvider);
        ref.invalidate(sellerProductsProvider(seller.id));
        ref.invalidate(featuredProductsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully!', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Always go to seller dashboard regardless of where we came from
        context.go('/seller-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save product: $e', style: GoogleFonts.poppins()),
            backgroundColor: AppTheme.errorRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Add Product', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/seller-dashboard'),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            TextButton(
              onPressed: _saveProduct,
              child: Text('Save', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Upload Section
            _SectionCard(
              title: 'Product Images',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add up to 5 photos',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                    ? Image.network(
                                        entry.value.path,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(entry.value.path),
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedImages.removeAt(entry.key)),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (_selectedImages.length < 5)
                          Row(
                            children: [
                              _AddImageButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onTap: _pickImages,
                              ),
                              const SizedBox(width: 12),
                              _AddImageButton(
                                icon: Icons.camera_alt_outlined,
                                label: 'Camera',
                                onTap: _pickFromCamera,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Basic Info Section
            _SectionCard(
              title: 'Product Details',
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                      hintText: 'e.g. Fresh Tomatoes',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Product name is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Describe your product...',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Category Dropdown — loaded from Supabase
                  Consumer(builder: (context, ref, _) {
                    final catsAsync = ref.watch(categoriesProvider);
                    return catsAsync.when(
                      data: (cats) {
                        if (_selectedCategory == null && cats.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) setState(() => _selectedCategory = cats.first);
                          });
                        }
                        return DropdownButtonFormField<CategoryEntity>(
                          initialValue: _selectedCategory,
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
                                          style: GoogleFonts.poppins(fontSize: 14)),
                                    ]),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _selectedCategory = v),
                          validator: (v) =>
                              v == null ? 'Please select a category' : null,
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
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

            // Pricing Section
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
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Price (RWF) *',
                            hintText: '0',
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Price is required';
                            if (double.tryParse(v) == null) return 'Invalid price';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedUnit,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: _units.map((u) => DropdownMenuItem(
                            value: u,
                            child: Text(u, style: GoogleFonts.poppins(fontSize: 13)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
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
                      if (v == null || v.isEmpty) return 'Stock is required';
                      if (int.tryParse(v) == null) return 'Invalid quantity';
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
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 18)),
                child: _isSaving
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Save Product',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
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

  const _AddImageButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.primaryGreen, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFFE8F5E9),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppTheme.primaryGreen),
            const SizedBox(height: 6),
            Text(label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryGreen)),
          ],
        ),
      ),
    );
  }
}
