import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/auth/auth_gate.dart';
import 'core/storage/local_cache.dart';
import 'core/supabase/supabase_config.dart';
import 'core/widgets/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([
    SupabaseConfig.initialize(),
    LocalCache.initialize(),
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.nightBlueDeep,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const JurisIAApp());
}

/// Point d'entrée de l'application JurisIA : assistant juridique
/// multiplateforme couvrant litiges et consultations, bibliothèque
/// juridique, parcours étudiant et espace professionnel.
class JurisIAApp extends StatelessWidget {
  const JurisIAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JurisIA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const JurisIASplashScreen(child: AuthGate()),
    );
  }
}
