import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import '../supabase/supabase_config.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_icon_badge.dart';
import '../widgets/luxury_elevated_button.dart';
import 'staff_status.dart';

/// URL publique de la console d'administration — un déploiement Cloudflare
/// Pages séparé (voir `lib/admin_main.dart`), jamais atteignable depuis
/// cette app grand public autrement que par ce lien externe.
const String kAdminConsoleUrl = 'https://jurisia-admin.pages.dev/';

/// Enveloppe [child] (la destination une fois connecté) et propose, une
/// seule fois par session, aux comptes du personnel de rejoindre la
/// console d'administration — même compte, deux applications déployées
/// séparément. Web uniquement : sur mobile, la console n'a pas vocation à
/// s'ouvrir dans un navigateur embarqué.
class StaffRedirectPrompt extends StatefulWidget {
  const StaffRedirectPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<StaffRedirectPrompt> createState() => _StaffRedirectPromptState();
}

class _StaffRedirectPromptState extends State<StaffRedirectPrompt> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb && SupabaseConfig.isReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrompt());
    }
  }

  Future<void> _maybePrompt() async {
    final isStaff = await isStaffAccount();
    if (!mounted || !isStaff) return;
    await showDialog<void>(
      context: context,
      builder: (context) => const _StaffRedirectDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _StaffRedirectDialog extends StatelessWidget {
  const _StaffRedirectDialog();

  Future<void> _openAdmin(BuildContext context) async {
    await launchUrl(Uri.parse(kAdminConsoleUrl), webOnlyWindowName: '_blank');
    if (context.mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: GradientIconBadge(icon: Icons.shield_moon_rounded, size: 52),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Bienvenue, personnel JurisIA',
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Ce compte a aussi accès à la console d\'administration. Où voulez-vous aller ?',
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                LuxuryElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Continuer vers JurisIA'),
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () => _openAdmin(context),
                  icon: const Icon(Icons.admin_panel_settings_rounded, size: 16, color: AppColors.cobalt),
                  label: const Text('Ouvrir la console d\'administration'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cobalt,
                    side: BorderSide(color: AppColors.cobalt.withValues(alpha: 0.6), width: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
