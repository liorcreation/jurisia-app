import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'admin/admin_app.dart';
import 'core/monitoring/crash_reporting.dart';
import 'core/storage/local_cache.dart';
import 'core/supabase/supabase_config.dart';
import 'theme/app_theme.dart';

/// Point d'entrée de la **console d'administration** JurisIA — une
/// application web distincte de l'application grand public, à compiler et
/// déployer séparément :
///
/// ```
/// flutter run  -d chrome -t lib/admin_main.dart
/// flutter build web -t lib/admin_main.dart
/// ```
///
/// Elle partage le projet Supabase, le design system et les modèles, mais
/// jamais son code n'entre dans le bundle grand public (`lib/main.dart` ne
/// l'importe pas). L'accès est filtré par un rôle de personnel (table
/// `staff_roles`, voir `server/supabase/migration_006_roles_and_audit.sql`).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Environnement distinct de l'app grand public dans Sentry, pour ne
  // jamais confondre une erreur de la console avec une erreur utilisateur —
  // partage toutefois le même SENTRY_DSN (un seul projet Sentry suffit).
  await CrashReporting.runGuarded(() async {
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
    runApp(const JurisIAAdminApp());
  }, environment: 'admin');
}
