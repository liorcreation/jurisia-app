import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'glass_container.dart';

/// Variantes de surface du langage visuel JurisIA.
enum PremiumSurfaceTone { glass, elevated, cobalt }

/// Primitive de surface partagée par les features.
///
/// Ce composant garde l'effet de verre existant dans [GlassContainer], mais
/// centralise les choix de contraste, de rayon et de bordure. Une feature ne
/// devrait choisir une couleur de panneau qu'en passant explicitement un
/// [PremiumSurfaceTone].
class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.margin,
    this.radius = AppRadius.large,
    this.tone = PremiumSurfaceTone.glass,
    this.onTap,
    this.width,
    this.height,
    this.blurSigma = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final PremiumSurfaceTone tone;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double blurSigma;

  Gradient get _gradient => switch (tone) {
    PremiumSurfaceTone.glass => AppGradients.glassCard,
    PremiumSurfaceTone.elevated => const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x3318273A), Color(0x14111827)],
    ),
    PremiumSurfaceTone.cobalt => AppGradients.heroCard,
  };

  Color get _borderColor => switch (tone) {
    PremiumSurfaceTone.glass => AppColors.glassBorder,
    PremiumSurfaceTone.elevated => AppColors.cobalt.withValues(alpha: 0.25),
    PremiumSurfaceTone.cobalt => AppColors.gold.withValues(alpha: 0.42),
  };

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: padding,
      margin: margin,
      borderRadius: radius,
      blurSigma: blurSigma,
      gradient: _gradient,
      borderColor: _borderColor,
      borderWidth: 0.7,
      width: width,
      height: height,
      onTap: onTap,
      child: child,
    );
  }
}

/// En-tête de section responsive : eyebrow en capitales, titre juridique en
/// serif et action optionnelle. Le [Wrap] permet à l'action de passer sous le
/// titre sur les fenêtres étroites sans provoquer d'overflow.
class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null)
          Text(
            eyebrow!.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: AppLetterSpacing.caps,
            ),
          ),
        Text(
          title,
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontFamily: 'Libre Caslon Display',
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle!, style: textTheme.bodyMedium),
        ],
      ],
    );

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.sm,
      spacing: AppSpacing.md,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 760),
          child: heading,
        ),
        ?action,
      ],
    );
  }
}

enum PremiumStatusTone { neutral, gold, success, warning, danger, info }

/// Badge d'état à contraste contrôlé, utilisable pour les états d'examen,
/// d'abonnement, de traitement IA ou de demande professionnelle.
class PremiumStatusPill extends StatelessWidget {
  const PremiumStatusPill({
    super.key,
    required this.label,
    this.tone = PremiumStatusTone.neutral,
    this.icon,
    this.compact = false,
  });

  final String label;
  final PremiumStatusTone tone;
  final IconData? icon;
  final bool compact;

  Color get _color => switch (tone) {
    PremiumStatusTone.neutral => AppColors.textSecondary,
    PremiumStatusTone.gold => AppColors.gold,
    PremiumStatusTone.success => AppColors.success,
    PremiumStatusTone.warning => AppColors.warning,
    PremiumStatusTone.danger => AppColors.error,
    PremiumStatusTone.info => AppColors.cobaltLight,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final textStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w700,
      letterSpacing: compact ? 0.3 : AppLetterSpacing.label,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 13 : 15, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

/// Carte KPI générique utilisée par les cockpits et tableaux de bord.
class PremiumMetricCard extends StatelessWidget {
  const PremiumMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.accentColor = AppColors.gold,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PremiumSurface(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.36),
                width: 0.7,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.18),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.headlineMedium?.copyWith(
              fontFamily: 'Libre Caslon Display',
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label.toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: AppLetterSpacing.caps,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              hint!,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
