class AppConstants {
  static const String defaultLocation = '📍 Kimironko, Kigali';
  
  static const List<String> productCategories = [
    'Vegetables',
    'Clothes',
    'Electronics',
    'Food',
    'Hardware',
    'Other',
  ];
  
  static const Map<String, String> categoryLabels = {
    'all': 'All',
    'vegetables': 'Produce',
    'clothes': 'Clothes',
    'electronics': 'Tech',
    'food': 'Food & Bakery',
    'hardware': 'Hardware',
    'other': 'Other',
  };
  
  static const Map<String, String> categoryEmojis = {
    'vegetables': '🥦',
    'clothes': '👗',
    'electronics': '📱',
    'food': '🍞',
    'hardware': '🔧',
    'other': '🛒',
  };
  
  static const List<String> paymentMethods = [
    'MTN MoMo',
    'Airtel Money',
    'Cash on Delivery',
  ];
  
  static const double minRating = 0.0;
  static const double maxRating = 5.0;
  
  static const int maxSearchHistory = 10;
  static const int minPasswordLength = 8;
}

class StorageBuckets {
  static const String products = 'products';
  static const String sellers = 'sellers';
  static const String profiles = 'profiles';
}

class DatabaseTables {
  static const String profiles = 'profiles';
  static const String sellers = 'sellers';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String cartItems = 'cart_items';
  static const String orders = 'orders';
  static const String orderItems = 'order_items';
  static const String favorites = 'favorites';
  static const String reviews = 'reviews';
  static const String notifications = 'notifications';
}
