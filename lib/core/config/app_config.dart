import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // --dart-define values injected at build time (web CI/CD).
  // Falls back to flutter_dotenv for local development on mobile/desktop.
  static const String _buildUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String _buildKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String _buildEnv =
      String.fromEnvironment('ENVIRONMENT', defaultValue: '');

  static String get supabaseUrl {
    if (_buildUrl.isNotEmpty) return _buildUrl;
    return dotenv.get('SUPABASE_URL',
        fallback: 'https://uttckehvmojzmibodlhs.supabase.co');
  }

  static String get supabaseAnonKey {
    if (_buildKey.isNotEmpty) return _buildKey;
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  static String get environment {
    if (_buildEnv.isNotEmpty) return _buildEnv;
    return dotenv.get('ENVIRONMENT', fallback: 'development');
  }

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isWeb => kIsWeb;

  static const String appName = 'AfriMarket';
  static const String appVersion = '2.0.0';
  static const String appTagline = 'Find it nearby. Buy with trust.';

  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration cacheTimeout = Duration(minutes: 5);

  static const int productsPerPage = 20;
  static const int maxImageSizeMB = 5;
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  static const String defaultCurrency = 'RWF';
  static const double deliveryFee = 500.0;
  static const double platformCommissionRate = 0.05; // 5 %
}
