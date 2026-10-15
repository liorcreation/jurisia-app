import 'package:flutter/material.dart';

import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../theme/app_theme.dart';
import '../../domain/entities/professional_service_category.dart';
import '../widgets/professional_service_request_wizard.dart';

const _canvas = Color(0xFFF3F6FA);
const _paper = Colors.white;
const _ink = Color(0xFF10233F);
const _muted = Color(0xFF52647C);
const _line = Color(0xFFDCE4EE);

/// Catalogue de prestations d'un pôle. Chaque prestation démarre directement
/// sa demande pré-orientée, sans renvoyer l'utilisateur à l'accueil.
class ProfessionalServiceCatalogScreen extends StatefulWidget {
  const ProfessionalServiceCatalogScreen({super.key, required this.category});

  final ProfessionalServiceCategory category;

  @override
  State<ProfessionalServiceCatalogScreen> createState() =>
      _ProfessionalServiceCatalogScreenState();
}

class _ProfessionalServiceCatalogScreenState
    extends State<ProfessionalServiceCatalogScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _openRequest(String service) =>
      showProfessionalServiceRequestWizard(
        context,
        initialCategory: widget.category,
        initialActType: service,
      );

  @override
  Widget build(BuildContext context) {
    final services = widget.category.serviceTypes
        .where((service) =>
            service.toLowerCase().contains(_search.text.trim().toLowerCase()))
        .toList(growable: false);

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          title: Text(widget.category.label),
          backgroundColor: _paper,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, color: _line),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1E4168), Color(0xFF101C2D)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: .3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.category.icon, color: AppColors.goldLight),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Les prestations de votre parcours',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontFamily: 'Libre Caslon Display',
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          widget.category.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFD9E3F0),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '${widget.category.serviceTypes.length} prestations disponibles · prise en charge par des professionnels',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.goldLight,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une prestation…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer',
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        borderSide: const BorderSide(color: _line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        borderSide: const BorderSide(color: _line),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 900
                          ? 3
                          : constraints.maxWidth >= 560
                              ? 2
                              : 1;
                      final gap = AppSpacing.sm * (columns - 1);
                      final width = (constraints.maxWidth - gap) / columns;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (var i = 0; i < services.length; i++)
                            SizedBox(
                              width: width,
                              child: _ServiceTile(
                                number: (i + 1).toString().padLeft(2, '0'),
                                title: services[i],
                                onTap: () => _openRequest(services[i]),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  if (services.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Text(
                        'Aucune prestation ne correspond à cette recherche.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme.bodyMedium
                            ?.copyWith(color: _muted),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Sélectionnez un service pour préparer votre demande. Vous resterez dans ce parcours jusqu’à la confirmation.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _muted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({
    required this.number,
    required this.title,
    required this.onTap,
  });

  final String number;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: _paper,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Container(
            constraints: const BoxConstraints(minHeight: 86),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: _line),
            ),
            child: Row(
              children: [
                Text(
                  number,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_rounded,
                    color: AppColors.goldDark, size: 19),
              ],
            ),
          ),
        ),
      );
}
