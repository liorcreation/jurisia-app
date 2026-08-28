import 'package:flutter/material.dart';

import 'auth/admin_auth_gate.dart';
import 'theme/admin_theme.dart';

/// Racine de la console d'administration JurisIA.
class JurisIAAdminApp extends StatelessWidget {
  const JurisIAAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JurisIA — Administration',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.dark,
      darkTheme: AdminTheme.dark,
      themeMode: ThemeMode.dark,
      home: const AdminAuthGate(),
    );
  }
}
