import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class _PaletteAction {
  const _PaletteAction({
    required this.icon,
    required this.label,
    required this.shortcutLabel,
    required this.moduleIndex,
  });

  final IconData icon;
  final String label;
  final String shortcutLabel;
  final int moduleIndex;
}

const _actions = [
  _PaletteAction(icon: Icons.forum_rounded, label: 'Nouvelle consultation', shortcutLabel: 'L', moduleIndex: 0),
  _PaletteAction(
    icon: Icons.local_library_rounded,
    label: 'Rechercher dans la Bibliothèque',
    shortcutLabel: 'B',
    moduleIndex: 1,
  ),
  _PaletteAction(icon: Icons.school_rounded, label: 'Espace étudiant', shortcutLabel: 'E', moduleIndex: 2),
  _PaletteAction(
    icon: Icons.edit_document,
    label: 'Nouveau brouillon professionnel',
    shortcutLabel: 'D',
    moduleIndex: 3,
  ),
  _PaletteAction(
    icon: Icons.support_agent_rounded,
    label: 'Contacter un professionnel',
    shortcutLabel: 'C',
    moduleIndex: 4,
  ),
];

/// Enveloppe la coquille desktop avec le raccourci ⌘K / Ctrl+K qui ouvre la
/// palette de commandes — le registre « cabinet numérique » pensé pour un
/// juriste qui travaille au clavier.
class CommandPaletteShortcut extends StatelessWidget {
  const CommandPaletteShortcut({super.key, required this.onSelectModule, required this.child});

  final ValueChanged<int> onSelectModule;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK): () => _open(context),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): () => _open(context),
      },
      child: Focus(autofocus: true, child: child),
    );
  }

  void _open(BuildContext context) {
    showCommandPalette(context, onSelectModule: onSelectModule);
  }
}

/// Affiche la palette de commandes flottante par-dessus l'écran courant.
Future<void> showCommandPalette(BuildContext context, {required ValueChanged<int> onSelectModule}) {
  return showGeneralDialog<void>(
    context: context,
    barrierLabel: 'Palette de commandes',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (context, animation, secondaryAnimation) => _CommandPalette(onSelectModule: onSelectModule),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _CommandPalette extends StatefulWidget {
  const _CommandPalette({required this.onSelectModule});

  final ValueChanged<int> onSelectModule;

  @override
  State<_CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<_CommandPalette> {
  final TextEditingController _searchController = TextEditingController();
  int _highlighted = 0;
  List<_PaletteAction> _filtered = _actions;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _filtered =
          query.isEmpty ? _actions : _actions.where((a) => a.label.toLowerCase().contains(query)).toList();
      _highlighted = 0;
    });
  }

  void _select(_PaletteAction action) {
    Navigator.of(context).pop();
    widget.onSelectModule(action.moduleIndex);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (_filtered.isEmpty) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() => _highlighted = (_highlighted + 1) % _filtered.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() => _highlighted = (_highlighted - 1 + _filtered.length) % _filtered.length);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _select(_filtered[_highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKey,
      child: Align(
        alignment: const Alignment(0, -0.55),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 640,
            constraints: const BoxConstraints(maxWidth: 640),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.legalBlueLight, AppColors.nightBlueDeep],
              ),
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
              boxShadow: AppShadows.cardElevated,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onSubmitted: (_) {
                            if (_filtered.isNotEmpty) _select(_filtered[_highlighted]);
                          },
                          decoration: const InputDecoration.collapsed(hintText: 'Rechercher une action…'),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const _KeyTag(label: 'Échap'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    children: [
                      for (var i = 0; i < _filtered.length; i++)
                        _PaletteRow(
                          action: _filtered[i],
                          highlighted: i == _highlighted,
                          onTap: () => _select(_filtered[i]),
                        ),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                          child: Text(
                            'Aucune action ne correspond.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Text('↑↓ naviguer', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(width: AppSpacing.md),
                      Text('↵ ouvrir', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(width: AppSpacing.md),
                      Text('Échap fermer', style: Theme.of(context).textTheme.labelSmall),
                    ],
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

class _KeyTag extends StatelessWidget {
  const _KeyTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _PaletteRow extends StatelessWidget {
  const _PaletteRow({required this.action, required this.highlighted, required this.onTap});

  final _PaletteAction action;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? AppColors.gold.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          child: Row(
            children: [
              Icon(action.icon, size: 18, color: highlighted ? AppColors.gold : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  action.label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                ),
              ),
              _KeyTag(label: action.shortcutLabel),
            ],
          ),
        ),
      ),
    );
  }
}
