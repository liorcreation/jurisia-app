import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../platform/app_platform_style.dart';
import '../widgets/entrance_fade.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_icon_badge.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/luxury_scaffold_background.dart';
import '../../theme/app_theme.dart';
import 'legal_document_screen.dart';
import 'legal_documents.dart';

/// Écran « Avertissement » : la charte de l'assistance par IA, ouverte
/// depuis le rappel sous le composeur de la page « Litiges ». Le contenu
/// vient de [LegalDocuments] (forme structurée). Mise en page éditoriale
/// dédiée sur desktop ; version compacte sur mobile.
class AiDisclaimerScreen extends StatelessWidget {
  const AiDisclaimerScreen({super.key});

  static const _icons = <IconData>[
    Icons.gavel_rounded,
    Icons.help_outline_rounded,
    Icons.fact_check_rounded,
    Icons.cloud_outlined,
  ];

  static const _tints = <Color>[
    AppColors.metalDeepGold,
    AppColors.metalCopper,
    AppColors.metalCobalt,
    AppColors.metalGunmetal,
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppPlatformStyle.of(context) == AppPlatformStyle.desktop;

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: isDesktop ? null : AppBar(title: const Text('Avertissement')),
        body: SafeArea(
          child: Stack(
            children: [
              if (isDesktop)
                const Positioned.fill(child: IgnorePointer(child: _DisclaimerAmbience())),
              Column(
                children: [
                  if (isDesktop) const _DesktopDisclaimerHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isDesktop ? 980 : 640),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              isDesktop ? AppSpacing.xl : AppSpacing.lg,
                              isDesktop ? AppSpacing.xl : AppSpacing.lg,
                              isDesktop ? AppSpacing.xl : AppSpacing.lg,
                              AppSpacing.xxl,
                            ),
                            child: _DisclaimerBody(isDesktop: isDesktop),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopDisclaimerHeader extends StatelessWidget {
  const _DesktopDisclaimerHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Retour',
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Text('Avertissement', style: textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _DisclaimerBody extends StatelessWidget {
  const _DisclaimerBody({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final points = LegalDocuments.aiDisclaimerPoints;

    final grid = LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = isDesktop && constraints.maxWidth >= 720;
        if (!twoCol) {
          return Column(
            children: [
              for (var i = 0; i < points.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == points.length - 1 ? 0 : AppSpacing.md),
                  child: EntranceFadeSlide(
                    index: i,
                    child: _PrincipleCard(
                      index: i,
                      icon: AiDisclaimerScreen._icons[i],
                      tint: AiDisclaimerScreen._tints[i],
                      title: points[i].title,
                      body: points[i].body,
                    ),
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            for (var row = 0; row < points.length; row += 2)
              Padding(
                padding: EdgeInsets.only(bottom: row + 2 >= points.length ? 0 : AppSpacing.md),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col > 0) const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: (row + col) < points.length
                              ? EntranceFadeSlide(
                                  index: row + col,
                                  child: _PrincipleCard(
                                    index: row + col,
                                    icon: AiDisclaimerScreen._icons[row + col],
                                    tint: AiDisclaimerScreen._tints[row + col],
                                    title: points[row + col].title,
                                    body: points[row + col].body,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            JurisIAMark(size: isDesktop ? 30 : 26),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'AVERTISSEMENT',
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: AppLetterSpacing.caps,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? AppSpacing.md : AppSpacing.sm),
        Text(
          LegalDocuments.aiDisclaimerTitle,
          softWrap: true,
          style: (isDesktop ? textTheme.displaySmall : textTheme.headlineSmall)
              ?.copyWith(fontFamily: 'Libre Caslon Display', height: 1.15),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(width: 54, height: 2, color: AppColors.gold.withValues(alpha: 0.7)),
        const SizedBox(height: AppSpacing.md),
        Text(
          LegalDocuments.aiDisclaimerIntro,
          style: (isDesktop ? textTheme.bodyLarge : textTheme.bodyMedium)?.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
        SizedBox(height: isDesktop ? AppSpacing.xxl : AppSpacing.xl),
        grid,
        SizedBox(height: isDesktop ? AppSpacing.xxl : AppSpacing.xl),
        _ClosingPanel(isDesktop: isDesktop),
      ],
    );
  }
}

class _PrincipleCard extends StatelessWidget {
  const _PrincipleCard({
    required this.index,
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
  });

  final int index;
  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: tint.withValues(alpha: 0.24),
      borderWidth: 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientIconBadge(
                icon: icon,
                size: 42,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(tint, Colors.white, 0.35)!,
                    tint,
                    Color.lerp(tint, AppColors.nightBlueDeep, 0.35)!,
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '0${index + 1}',
                style: textTheme.titleMedium?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  color: AppColors.gold.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Libre Caslon Display',
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _ClosingPanel extends StatelessWidget {
  const _ClosingPanel({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.all(isDesktop ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.10),
            AppColors.gold.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_moon_rounded, size: 18, color: AppColors.goldLight),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  LegalDocuments.aiDisclaimerClosing,
                  style: (isDesktop ? textTheme.bodyMedium : textTheme.bodySmall)?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nightBlueDeep,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                  textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('J\'ai compris'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LegalDocumentScreen(
                      title: 'Politique de confidentialité',
                      content: LegalDocuments.privacyPolicy,
                    ),
                  ),
                ),
                icon: const Icon(Icons.privacy_tip_outlined, size: 15),
                label: const Text('Politique de confidentialité'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _DisclaimerAmbience extends StatefulWidget {
  const _DisclaimerAmbience();

  @override
  State<_DisclaimerAmbience> createState() => _DisclaimerAmbienceState();
}

class _DisclaimerAmbienceState extends State<_DisclaimerAmbience>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 36))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _DisclaimerAmbiencePainter(_controller.value)),
    );
  }
}

class _DisclaimerAmbiencePainter extends CustomPainter {
  const _DisclaimerAmbiencePainter(this.t);

  final double t;
  static const int _count = 14;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 59.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 20;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.6;
      final opacity = 0.05 + 0.08 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DisclaimerAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
