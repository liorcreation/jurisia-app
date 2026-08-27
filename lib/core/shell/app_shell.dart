import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/contact_professional/presentation/contact_professional_providers.dart';
import '../../features/contact_professional/presentation/controllers/contact_professional_controller.dart';
import '../../features/contact_professional/presentation/screens/contact_professional_screen.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/library/presentation/library_providers.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/litigation/presentation/controllers/litigation_chat_controller.dart';
import '../../features/litigation/presentation/litigation_providers.dart';
import '../../features/litigation/presentation/screens/litigation_screen.dart';
import '../../features/profile/presentation/controllers/profile_controller.dart';
import '../../features/profile/presentation/profile_providers.dart';
import '../../features/professional/presentation/controllers/professional_documents_controller.dart';
import '../../features/professional/presentation/professional_providers.dart';
import '../../features/professional/presentation/screens/professional_screen.dart';
import '../../features/student/presentation/controllers/student_controller.dart';
import '../../features/student/presentation/screens/student_screen.dart';
import '../../features/student/presentation/student_providers.dart';
import '../navigation/nav_destinations.dart';
import '../platform/app_platform_style.dart';
import '../widgets/command_palette.dart';
import '../widgets/luxury_scaffold_background.dart';
import 'jurisia_sidebar.dart';

/// Contrat exposé par [AppShell] à ses descendants via [AppShellScope] :
/// changer d'espace, ouvrir/replier la navigation. Une interface publique
/// plutôt que l'`State` privé pour rester dans les clous du lint.
abstract class AppShellController {
  int get selectedIndex;

  /// `true` quand la sidebar permanente (desktop) est réduite à un rail
  /// d'icônes.
  bool get railCollapsed;

  void selectModule(int index);

  /// Ouvre la navigation : le tiroir sur mobile, ou déplie le rail sur
  /// desktop s'il était replié.
  void openNav();

  /// Bascule la navigation : replie/déplie le rail desktop, ouvre le tiroir
  /// sur mobile.
  void toggleNav();
}

/// Portée héritée donnant accès au [AppShellController] depuis n'importe quel
/// écran monté dans la coquille.
class AppShellScope extends InheritedWidget {
  const AppShellScope({
    super.key,
    required this.controller,
    required this.selectedIndex,
    required this.railCollapsed,
    required super.child,
  });

  final AppShellController controller;
  final int selectedIndex;
  final bool railCollapsed;

  static AppShellController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppShellScope>();
    assert(scope != null, 'AppShellScope.of() appelé hors d\'un AppShell');
    return scope!.controller;
  }

  static AppShellController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppShellScope>()?.controller;
  }

  @override
  bool updateShouldNotify(AppShellScope oldWidget) {
    return selectedIndex != oldWidget.selectedIndex || railCollapsed != oldWidget.railCollapsed;
  }
}

/// Coquille de navigation principale de JurisIA. Une **sidebar unifiée**
/// (marque, « Nouvelle consultation », recherche, les cinq espaces, contenu
/// contextuel de l'espace actif, carte profil) — permanente et repliable sur
/// desktop/macOS, tiroir coulissant sur Android/iOS. Plus aucune barre de
/// navigation inférieure : toute la navigation passe par la sidebar, comme
/// ChatGPT/Claude/Gemini, dans le registre « verre fumé & or brossé » de
/// JurisIA.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  /// Largeur minimale / maximale / par défaut de la sidebar permanente.
  static const double minSidebarWidth = 264;
  static const double maxSidebarWidth = 420;
  static const double defaultSidebarWidth = 304;
  static const double railWidth = 76;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> implements AppShellController {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _prefWidthKey = 'shell.sidebar.width';
  static const String _prefCollapsedKey = 'shell.sidebar.collapsed';

  int _selectedIndex = 0;
  bool _railCollapsed = false;
  double _sidebarWidth = AppShell.defaultSidebarWidth;

  @override
  void initState() {
    super.initState();
    _restoreSidebarLayout();
  }

  Future<void> _restoreSidebarLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final width = prefs.getDouble(_prefWidthKey);
      final collapsed = prefs.getBool(_prefCollapsedKey);
      if (!mounted) return;
      setState(() {
        if (width != null) {
          _sidebarWidth = width.clamp(AppShell.minSidebarWidth, AppShell.maxSidebarWidth);
        }
        if (collapsed != null) _railCollapsed = collapsed;
      });
    } catch (_) {
      // Persistance indisponible (ex. test de widget) : on garde les valeurs
      // par défaut, sans bruit.
    }
  }

  Future<void> _persistSidebarLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_prefWidthKey, _sidebarWidth);
      await prefs.setBool(_prefCollapsedKey, _railCollapsed);
    } catch (_) {
      // sans effet si indisponible
    }
  }

  static const List<Widget> _screens = [
    LitigationScreen(),
    LibraryScreen(),
    StudentScreen(),
    ProfessionalScreen(),
    ContactProfessionalScreen(),
  ];

  bool get _isDesktop => AppPlatformStyle.of(context) == AppPlatformStyle.desktop;

  // --- AppShellController -------------------------------------------------

  @override
  int get selectedIndex => _selectedIndex;

  @override
  bool get railCollapsed => _railCollapsed;

  @override
  void selectModule(int index) {
    if (index != _selectedIndex) setState(() => _selectedIndex = index);
    final scaffold = _scaffoldKey.currentState;
    if (scaffold != null && scaffold.isDrawerOpen) {
      Navigator.of(context).pop();
    }
  }

  @override
  void openNav() {
    if (_isDesktop) {
      if (_railCollapsed) setState(() => _railCollapsed = false);
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  void toggleNav() {
    if (_isDesktop) {
      setState(() => _railCollapsed = !_railCollapsed);
      _persistSidebarLayout();
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  void _newConsultation() {
    context.read<LitigationChatController>().startNewConsultation();
    selectModule(0);
  }

  void _resizeSidebar(double delta) {
    setState(() {
      _sidebarWidth = (_sidebarWidth + delta).clamp(
        AppShell.minSidebarWidth,
        AppShell.maxSidebarWidth,
      );
    });
  }

  // --- build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDesktop = _isDesktop;
    final body = IndexedStack(index: _selectedIndex, children: _screens);

    final scaffold = LuxuryScaffoldBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawerScrimColor: Colors.black.withValues(alpha: 0.55),
        drawer: isDesktop
            ? null
            : Drawer(
                backgroundColor: Colors.transparent,
                elevation: 0,
                width: math.min(360, MediaQuery.sizeOf(context).width * 0.86),
                child: const JurisIASidebar(variant: SidebarVariant.drawer),
              ),
        body: isDesktop
            ? Row(
                children: [
                  _DesktopSidebar(
                    collapsed: _railCollapsed,
                    width: _sidebarWidth,
                    onResize: _resizeSidebar,
                    onResizeEnd: _persistSidebarLayout,
                  ),
                  Expanded(child: body),
                ],
              )
            : body,
      ),
    );

    Widget shell = MultiProvider(
      providers: [
        ChangeNotifierProvider<LitigationChatController>(
          create: (_) => buildLitigationChatController(),
        ),
        ChangeNotifierProvider<ProfileController>(
          create: (_) => buildProfileController(),
        ),
        ChangeNotifierProvider<LibraryController>(
          create: (_) => buildLibraryController(),
        ),
        ChangeNotifierProvider<StudentController>(
          create: (_) => buildStudentController(),
        ),
        ChangeNotifierProvider<ContactProfessionalController>(
          create: (_) => buildContactProfessionalController(),
        ),
        ChangeNotifierProvider<ProfessionalDocumentsController>(
          create: (_) => buildProfessionalDocumentsController(),
        ),
      ],
      child: AppShellScope(
        controller: this,
        selectedIndex: _selectedIndex,
        railCollapsed: _railCollapsed,
        child: scaffold,
      ),
    );

    if (!isDesktop) return shell;

    // Registre desktop « cabinet numérique » : raccourcis clavier au-dessus
    // de la palette ⌘K existante.
    return CommandPaletteShortcut(
      onSelectModule: selectModule,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): _newConsultation,
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): _newConsultation,
          const SingleActivator(LogicalKeyboardKey.keyB, meta: true): toggleNav,
          const SingleActivator(LogicalKeyboardKey.keyB, control: true): toggleNav,
          for (var i = 0; i < kNavDestinations.length; i++) ...{
            SingleActivator(_digitKeys[i], meta: true): () => selectModule(i),
            SingleActivator(_digitKeys[i], control: true): () => selectModule(i),
          },
        },
        child: shell,
      ),
    );
  }
}

const List<LogicalKeyboardKey> _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
];

/// Enveloppe de la sidebar permanente sur desktop : marge flottante, ombre
/// portée, et une poignée de redimensionnement sur le bord droit (double-clic
/// pour replier).
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.collapsed,
    required this.width,
    required this.onResize,
    required this.onResizeEnd,
  });

  final bool collapsed;
  final double width;
  final ValueChanged<double> onResize;
  final VoidCallback onResizeEnd;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      width: collapsed ? AppShell.railWidth : width,
      padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
      child: Stack(
        children: [
          Positioned.fill(
            child: JurisIASidebar(
              variant: collapsed ? SidebarVariant.rail : SidebarVariant.permanent,
            ),
          ),
          if (!collapsed)
            Positioned(
              top: 0,
              bottom: 0,
              right: -4,
              width: 12,
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeLeftRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragUpdate: (details) => onResize(details.delta.dx),
                  onHorizontalDragEnd: (_) => onResizeEnd(),
                  onDoubleTap: () => AppShellScope.of(context).toggleNav(),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
