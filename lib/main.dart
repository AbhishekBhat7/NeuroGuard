import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:neuroguard/screens/splashscreen.dart';
import 'package:provider/provider.dart';
import 'theme/app_colors.dart';
import 'services/ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Status bar styling for light theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => BleService(),
      child: const NeuroGuardApp(),
    ),
  );
}

class NeuroGuardApp extends StatelessWidget {
  const NeuroGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroGuard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
        colorSchemeSeed: AppColors.primaryBlue,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textNavy),
          bodyMedium: TextStyle(color: AppColors.textNavy),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textNavy,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: AppColors.primaryBlue),
          titleTextStyle: TextStyle(
            color: AppColors.textNavy,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        cardTheme: const CardThemeData(
          color: AppColors.surface,
          elevation: 1,
          shadowColor: AppColors.cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.borderLight,
          thickness: 1,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
 