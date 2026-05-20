class CategoryEntity {
  final String id;
  final String name;
  final String slug;
  final String? icon;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
  });

  factory CategoryEntity.fromJson(Map<String, dynamic> json) => CategoryEntity(
        id: json['id'] as String,
        name: json['name'] as String,
        slug: json['slug'] as String,
        icon: json['icon'] as String?,
      );

  static const List<Map<String, String>> defaults = [
    {'name': 'Food', 'slug': 'food', 'icon': '🍞'},
    {'name': 'Vegetables', 'slug': 'vegetables', 'icon': '🥦'},
    {'name': 'Clothes', 'slug': 'clothes', 'icon': '👗'},
    {'name': 'Electronics', 'slug': 'electronics', 'icon': '📱'},
    {'name': 'Hardware', 'slug': 'hardware', 'icon': '🔧'},
    {'name': 'Other', 'slug': 'other', 'icon': '🛒'},
  ];
}
