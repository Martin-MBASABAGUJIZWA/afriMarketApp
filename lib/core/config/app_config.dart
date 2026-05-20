import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabaseAnonKey => dotenv.get('SUPABASE_ANON_KEY');
  static String get environment => dotenv.get('ENVIRONMENT', fallback: 'development');
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  
  static const String appName = 'AfriMarket';
  static const String appVersion = '2.0.0';
  
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(minutes: 5);
  
  static const int productsPerPage = 20;
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  
  static const String defaultCurrency = 'RWF';
  static const double deliveryFee = 500.0;
}
