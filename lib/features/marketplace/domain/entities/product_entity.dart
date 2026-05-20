import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_entity.freezed.dart';
part 'product_entity.g.dart';

@freezed
class ProductEntity with _$ProductEntity {
  const ProductEntity._();

  const factory ProductEntity({
    required String id,
    @JsonKey(name: 'seller_id') required String sellerId,
    required String name,
    String? description,
    @JsonKey(name: 'category_id') required String categoryId,
    required double price,
    @Default('each') String unit,
    @JsonKey(name: 'stock_quantity') @Default(0) int stockQuantity,
    @JsonKey(name: 'image_urls') @Default([]) List<String> imageUrls,
    @JsonKey(name: 'is_featured') @Default(false) bool isFeatured,
    @Default(0.0) double rating,
    @JsonKey(name: 'review_count') @Default(0) int reviewCount,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _ProductEntity;

  factory ProductEntity.fromJson(Map<String, dynamic> json) =>
      _$ProductEntityFromJson(json);

  bool get inStock => stockQuantity > 0;

  String get availabilityLabel => inStock ? 'In Stock' : 'Out of Stock';

  String formattedPrice({String currency = 'RWF'}) =>
      '${price.toStringAsFixed(0)} $currency';

  String get ratingDisplay =>
      '${rating.toStringAsFixed(1)} ($reviewCount reviews)';

  String get ratingBadge {
    if (rating >= 4.5) return 'Top Rated';
    if (rating >= 4.0) return 'Highly Rated';
    return 'New';
  }

  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
}
