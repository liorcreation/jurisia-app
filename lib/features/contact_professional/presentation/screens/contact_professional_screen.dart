import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/platform/app_platform_style.dart';
import '../../../../core/widgets/app_shell_menu_button.dart';
import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/gradient_icon_badge.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../core/widgets/shimmer_sweep.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/contact_request.dart';
import '../../domain/entities/professional_category.dart';
import '../controllers/contact_professional_controller.dart';
import '../widgets/contact_request_sheet.dart';
import '../widgets/professional_category_card.dart';

/// Section 5 — Contacter un professionnel : mise en relation avec un
/// notaire, avocat, juriste, huissier, greffier ou juge partenaire, via une
/// demande de contact enregistrée et suivie dans Supabase. Le
/// [ContactProfessionalController] est fourni par la coquille applicative
/// ([AppShell]).
class ContactProfessionalScreen extends StatelessWidget {
  const ContactProfessionalScreen({super.key});

  @override
  Widget build(BuildContext context) => const _ContactProfessionalView();
}

class _ContactProfessionalView extends StatelessWidget {
  const _ContactProfessionalView();

  void _openRequestSheet(BuildContext context, ProfessionalCategory category) {
    final controller = context.read<ContactProfessionalController>();
    controller.resetStatus();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider<ContactProfessionalController>.value(
        value: controller,
        child: ContactRequestSheet(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ContactProfessionalController>();

    if (AppPlatformStyle.of(context) == AppPlatformStyle.desktop) {
      return _DesktopContactView(
        controller: controller,
        onOpenRequest: (category) => _openRequestSheet(context, category),
      );
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Contacter un professionnel'),
          leading: const AppShellMenuButton(),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Mise en relation avec un professionnel du droit',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choisissez le type de professionnel qu\'il vous faut : votre demande est transmise '
                'et un partenaire vous recontacte directement.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ProfessionalCategory.values.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final category = ProfessionalCategory.values[index];
                  return EntranceFadeSlide(
                    index: index,
                    child: ProfessionalCategoryCard(
                      category: category,
                      onTap: () => _openRequestSheet(context, category),
                    ),
                  );
                },
              ),
              if (controller.requests.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text('Mes demandes', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < controller.requests.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: EntranceFadeSlide(
                      index: ProfessionalCategory.values.length + i,
                      child: _ContactRequestTile(request: controller.requests[i]),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRequestTile extends StatelessWidget {
  const _ContactRequestTile({required this.request});

  final ContactRequest request;

  Color _statusColor(ContactRequestStatus status) {
    switch (status) {
      case ContactRequestStatus.pending:
        return AppColors.warning;
      case ContactRequestStatus.contacted:
        return AppColors.success;
      case ContactRequestStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(request.status);

    return GlassContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientIconBadge(icon: iconForCategory(request.category), size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.category.label, style: textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  request.message,
                  style: textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              request.status.label,
              style: textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
//  DESKTOP — « La mise en relation »
// ===========================================================================

typedef _OpenRequest = void Function(ProfessionalCategory category);

/// Teinte métallique propre à chaque profession — le greffe et la
/// magistrature en gunmetal (registre neutre), les professions de conseil
/// et d'exécution dans des tons plus chauds.
Color _categoryTint(ProfessionalCategory category) {
  switch (category) {
    case ProfessionalCategory.notaire:
      return AppColors.metalDeepGold;
    case ProfessionalCategory.avocat:
      return AppColors.metalCobalt;
    case ProfessionalCategory.juriste:
      return AppColors.metalEmerald;
    case ProfessionalCategory.huissier:
      return AppColors.metalCopper;
    case ProfessionalCategory.greffier:
      return AppColors.metalSilver;
    case ProfessionalCategory.juge:
      return AppColors.metalGunmetal;
  }
}

Gradient _categoryGradient(ProfessionalCategory category) {
  final tint = _categoryTint(category);
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.lerp(tint, Colors.white, 0.35)!,
      tint,
      Color.lerp(tint, AppColors.nightBlueDeep, 0.35)!,
    ],
  );
}

/// Spécialités d'une profession, dérivées de sa description (liste séparée
/// par des virgules), pour un affichage en pastilles.
List<String> _specialties(ProfessionalCategory category) {
  return category.description
      .split(RegExp(r'[,.:]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty && part.length <= 26)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .take(3)
      .toList();
}

String _relativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'à l\'instant';
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'hier';
  if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _DesktopContactView extends StatelessWidget {
  const _DesktopContactView({required this.controller, required this.onOpenRequest});

  final ContactProfessionalController controller;
  final _OpenRequest onOpenRequest;

  @override
  Widget build(BuildContext context) {
    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _ContactAmbience())),
              Column(
                children: [
                  const _DesktopContactHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1240),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xl,
                              AppSpacing.xxl,
                            ),
                            child: _ContactBody(
                              requests: controller.requests,
                              onOpenRequest: onOpenRequest,
                            ),
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

class _DesktopContactHeader extends StatelessWidget {
  const _DesktopContactHeader();

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
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          const Icon(Icons.diversity_3_rounded, size: 18, color: AppColors.gold),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Contacter un professionnel', style: textTheme.headlineSmall),
                const SizedBox(height: 3),
                Text(
                  'Mise en relation avec le réseau de partenaires du droit',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.requests, required this.onOpenRequest});

  final List<ContactRequest> requests;
  final _OpenRequest onOpenRequest;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final categoriesGrid = LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 680
            ? 3
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        final cats = ProfessionalCategory.values;
        final rows = <Widget>[];

        for (var start = 0; start < cats.length; start += columns) {
          final slice = cats.skip(start).take(columns).toList();
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: j < slice.length
                          ? EntranceFadeSlide(
                              index: start + j,
                              child: _ProfessionCard(
                                category: slice[j],
                                onTap: () => onOpenRequest(slice[j]),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          );
          if (start + columns < cats.length) {
            rows.add(const SizedBox(height: AppSpacing.md));
          }
        }

        return Column(children: rows);
      },
    );

    final sideColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RequestPanel(requests: requests),
        const SizedBox(height: AppSpacing.md),
        const _ConfidentialityNote(),
      ],
    );

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Eyebrow('Mise en relation'),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Le bon professionnel, au bon moment',
          style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            'Choisissez le professionnel qu\'il vous faut : votre demande est transmise au '
            'réseau de partenaires JurisIA, un membre vous recontacte directement. Rien '
            'n\'est engagé sans votre accord.',
            style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        categoriesGrid,
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 980) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              mainColumn,
              const SizedBox(height: AppSpacing.xl),
              sideColumn,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: mainColumn),
            const SizedBox(width: AppSpacing.xl),
            SizedBox(width: 320, child: sideColumn),
          ],
        );
      },
    );
  }
}

class _ProfessionCard extends StatefulWidget {
  const _ProfessionCard({required this.category, required this.onTap});

  final ProfessionalCategory category;
  final VoidCallback onTap;

  @override
  State<_ProfessionCard> createState() => _ProfessionCardState();
}

class _ProfessionCardState extends State<_ProfessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final category = widget.category;
    final tint = _categoryTint(category);
    final specialties = _specialties(category);
    final restricted = category.formNotice != null;

    Widget badge = GradientIconBadge(
      icon: iconForCategory(category),
      size: 50,
      gradient: _categoryGradient(category),
    );
    if (_hovered) {
      badge = ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: ShimmerSweep(duration: const Duration(milliseconds: 1600), child: badge),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedSlide(
        offset: _hovered ? const Offset(0, -0.014) : Offset.zero,
        duration: const Duration(milliseconds: 160),
        child: GlassContainer(
          onTap: widget.onTap,
          padding: const EdgeInsets.all(AppSpacing.lg),
          borderColor: _hovered
              ? tint.withValues(alpha: 0.6)
              : tint.withValues(alpha: 0.26),
          borderWidth: _hovered ? 1 : 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(alignment: Alignment.centerLeft, child: badge),
              const SizedBox(height: AppSpacing.md),
              Text(
                category.label,
                style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (restricted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 11, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Orientation générale',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Un juge ne se contacte pas à titre personnel. Cette demande sert à '
                  'obtenir une orientation générale, transmise par un partenaire juriste.',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
              ] else ...[
                Text(
                  category.description,
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final specialty in specialties)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.legalBlueDark.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: tint.withValues(alpha: 0.3), width: 0.7),
                        ),
                        child: Text(
                          specialty,
                          style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ],
              const Spacer(),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      restricted ? 'Demander une orientation' : 'Demander un contact',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.goldLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.goldLight),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequestPanel extends StatelessWidget {
  const _RequestPanel({required this.requests});

  final List<ContactRequest> requests;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Eyebrow('Mes demandes'),
          const SizedBox(height: AppSpacing.md),
          if (requests.isEmpty)
            const _HowItWorks()
          else
            for (var i = 0; i < requests.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == requests.length - 1 ? 0 : AppSpacing.sm),
                child: _RequestRow(request: requests[i]),
              ),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  static const _steps = <(IconData, String)>[
    (Icons.badge_rounded, 'Choisissez le type de professionnel'),
    (Icons.edit_note_rounded, 'Décrivez brièvement votre besoin'),
    (Icons.call_rounded, 'Un partenaire vous recontacte directement'),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos demandes de mise en relation et leur suivi apparaîtront ici.',
          style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == _steps.length - 1 ? 0 : AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '0${i + 1}',
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(_steps[i].$1, size: 14, color: AppColors.goldLight),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _steps[i].$2,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request});

  final ContactRequest request;

  Color _statusColor(ContactRequestStatus status) {
    switch (status) {
      case ContactRequestStatus.pending:
        return AppColors.warning;
      case ContactRequestStatus.contacted:
        return AppColors.success;
      case ContactRequestStatus.closed:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = _statusColor(request.status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.glassBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconForCategory(request.category), size: 15, color: _categoryTint(request.category)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        request.category.label,
                        style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      request.status.label,
                      style: textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  request.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, height: 1.3),
                ),
                const SizedBox(height: 2),
                Text(
                  _relativeDate(request.createdAt),
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfidentialityNote extends StatelessWidget {
  const _ConfidentialityNote();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2), width: 0.7),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.goldLight),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Vos coordonnées ne sont partagées qu\'avec le partenaire qui prend en charge '
              'votre demande, et l\'équipe JurisIA en assure le suivi.',
              style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// Fines poussières d'or en suspension — la même respiration « vivante »
/// que les autres écrans du registre desktop.
class _ContactAmbience extends StatefulWidget {
  const _ContactAmbience();

  @override
  State<_ContactAmbience> createState() => _ContactAmbienceState();
}

class _ContactAmbienceState extends State<_ContactAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 38))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _ContactAmbiencePainter(_controller.value)),
    );
  }
}

class _ContactAmbiencePainter extends CustomPainter {
  const _ContactAmbiencePainter(this.t);

  final double t;
  static const int _count = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 57.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 22;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.8 + (i % 3) * 0.7;
      final opacity = 0.05 + 0.09 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ContactAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
