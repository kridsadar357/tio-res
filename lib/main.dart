import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart' as p;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'screens/table_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'services/database_helper.dart';
import 'services/api_service.dart';
import 'services/edc_service.dart';
import 'services/printer_service.dart';
import 'providers/settings_provider.dart';
import 'theme/app_theme.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  final dbHelper = DatabaseHelper();
  await dbHelper.database;

  // Initialize settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();

  // Initialize API service
  await ApiService().init();

  // Initialize EDC service
  await EdcService().init();

  // Initialize Printer service (auto-connect to saved printer)
  await PrinterService().init();

  runApp(
    ProviderScope(
      child: p.ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const ResPOSApp(),
      ),
    ),
  );
}

/// Main Application Widget
///
/// Features:
/// - Material Design 3 theme
/// - Responsive design for tablets
/// - Multi-language support (TH/EN)
class ResPOSApp extends StatelessWidget {
  const ResPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return p.Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return ScreenUtilInit(
          // Set default design size for flutter_screenutil (Tablet 10.1")
          designSize: const Size(1280, 800),
          minTextAdapt: true,
          splitScreenMode: true,
          child: const TableSelectionScreen(),
          builder: (context, child) {
            return MaterialApp(
              title: 'ResPOS',
              debugShowCheckedModeBanner: false,
              
              // Performance optimizations
              builder: (context, child) {
                return MediaQuery(
                  // Disable text scaling for better performance
                  data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                  child: child!,
                );
              },

              // Localization
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('th'), // Thai (default)
                Locale('en'), // English
              ],
              locale: Locale(settings.language),

              // Themes (locale-aware for Thai font support)
              theme: AppTheme.lightTheme(Locale(settings.language)),
              darkTheme: AppTheme.darkTheme(Locale(settings.language)),

              // Dynamic theme mode from settings
              themeMode: settings.themeModeEnum,

              // Home screen wrapped in splash screen
              home: SplashScreen(
                child: child!,
              ),
            );
          },
        );
      },
    );
  }
}
