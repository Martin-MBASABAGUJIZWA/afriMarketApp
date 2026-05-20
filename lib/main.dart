import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:afrimarket/core/config/app_config.dart';
import 'package:afrimarket/core/config/router_config.dart';
import 'package:afrimarket/core/services/supabase_service.dart';
import 'package:afrimarket/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load env — try both files so the filename never depends on dotenv itself
  for (final file in ['.env.development', '.env.production', '.env']) {
    try {
      await dotenv.load(fileName: file);
      break; // stop after first successful load
    } catch (_) {}
  }

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Supabase init failed: $e');
  }

  runApp(
    const ProviderScope(
      child: AfriMarketApp(),
    ),
  );
}

class AfriMarketApp extends ConsumerWidget {
  const AfriMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
    );
  }
}
