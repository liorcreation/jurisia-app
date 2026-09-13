import 'package:flutter/material.dart';

import '../../core/widgets/premium_surface.dart';
import '../theme/admin_theme.dart';

/// Carte KPI du cockpit : badge d'icône teinté, grand chiffre en serif,
/// libellé en capitales, indice optionnel. Toujours en `Expanded` dans une
/// rangée de hauteur égale côté appelant.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.accentColor = AdminTheme.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return PremiumMetricCard(
      icon: icon,
      label: label,
      value: value,
      hint: hint,
      accentColor: accentColor,
    );
  }
}
