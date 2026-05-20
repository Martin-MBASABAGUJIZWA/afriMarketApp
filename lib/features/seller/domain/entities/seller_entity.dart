import 'package:freezed_annotation/freezed_annotation.dart';

part 'seller_entity.freezed.dart';
part 'seller_entity.g.dart';

@freezed
class SellerEntity with _$SellerEntity {
  const SellerEntity._();

  const factory SellerEntity({
    required String id,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'business_name') required String businessName,
    required String category,
    String? description,
    required String location,
    required String phone,
    @JsonKey(name: 'logo_url') String? logoUrl,
    @JsonKey(name: 'is_verified') @Default(false) bool isVerified,
    @JsonKey(name: 'is_open') @Default(true) bool isOpen,
    @Default(0.0) double rating,
    @JsonKey(name: 'total_sales') @Default(0) int totalSales,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') required DateTime updatedAt,
  }) = _SellerEntity;

  factory SellerEntity.fromJson(Map<String, dynamic> json) =>
      _$SellerEntityFromJson(json);

  String get ratingLabel => rating.toStringAsFixed(1);

  String get categoryIcon {
    switch (category.toLowerCase()) {
      case 'vegetables':
      case 'produce':
        return '🥦';
      case 'clothes':
      case 'fashion':
        return '👗';
      case 'electronics':
      case 'tech':
        return '📱';
      case 'food':
      case 'bakery':
        return '🍞';
      case 'hardware':
        return '🔧';
      default:
        return '🛒';
    }
  }
}
