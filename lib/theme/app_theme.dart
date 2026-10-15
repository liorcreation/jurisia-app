import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palette JurisIA : bleu nuit profond, cobalt en relief et or sablé.
class AppColors {
  const AppColors._();

  /// Couches nuit : fond, profondeur et surfaces de travail.
  static const Color deepSlate = Color(0xFF0B1220);
  static const Color deepSlateDeep = Color(0xFF070D17);
  static const Color deepSlateElevated = Color(0xFF111D2E);

  static const Color cobalt = Color(0xFF1D4C7D);
  static const Color cobaltLight = Color(0xFF7CA4D0);
  static const Color cobaltDeep = Color(0xFF0C2340);

  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD978);
  static const Color goldDark = Color(0xFF9A7A1E);
  static const Color roseGold = Color(0xFFD9A98A);
  static const Color agedGold = Color(0xFF7C6122);

  // Compatibilité avec les composants déjà livrés.
  static const Color nightBlue = Color(0xFF10243D);
  static const Color nightBlueDeep = Color(0xFF09182A);
  static const Color legalBlue = Color(0xFF142A45);
  static const Color legalBlueLight = cobalt;
  static const Color legalBlueDark = Color(0xFF0D2745);

  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFFAAB8CC);
  static const Color textDisabled = Color(0xFF718096);
  static const Color textOnDark = Color(0xFFF8FAFC);
  static const Color textSecondaryOnDark = Color(0xFFAAB8CC);

  /// Reflets bleutés discrets sur les surfaces nuit.
  static const Color glassFill = Color(0x241B4775);
  static const Color glassBorder = Color(0x35C7D6E8);
  static const Color glassHighlight = Color(0x18FFFFFF);

  /// Surface « verre fumé » des barres de navigation.
  static const Color smokedGlass = Color(0xF5071220);

  static const Color divider = Color(0x2EB7C3D6);

  static const Color success = Color(0xFF3FA772);
  static const Color warning = Color(0xFFE0A93E);
  static const Color error = Color(0xFFC85450);
  static const Color info = Color(0xFF6FA6E5);

  // Palette métallique des badges de catégorie de documents : chaque
  // branche/type reçoit un ton métallique distinct plutôt qu'une déclinaison
  // d'or, réservant l'or aux accents d'action.
  static const Color metalCobalt = Color(0xFF5C8FE0);
  static const Color metalBronze = Color(0xFFB08159);
  static const Color metalSilver = Color(0xFFC7CDD6);
  static const Color metalCopper = Color(0xFFC17A52);
  static const Color metalGunmetal = Color(0xFF8B98AC);
  static const Color metalEmerald = Color(0xFF5FA98A);
  static const Color metalRoseGold = Color(0xFFD6A79E);
  static const Color metalDeepGold = gold;
}

/// Dégradés métalliques et d'ambiance utilisés dans toute l'application.
class AppGradients {
  const AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.deepSlateDeep, AppColors.deepSlate],
  );

  /// Or brossé : dégradé à bandes multiples simulant le passage de la
  /// lumière sur un métal brossé, plutôt qu'un aplat doré.
  static const LinearGradient goldMetallic = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.goldLight,
      AppColors.gold,
      AppColors.goldDark,
      AppColors.gold,
      AppColors.goldLight,
    ],
    stops: [0.0, 0.3, 0.55, 0.78, 1.0],
  );

  static const LinearGradient goldSheen = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.goldDark, AppColors.goldLight, AppColors.goldDark],
  );

  /// Or rose : variante plus douce pour des accents ponctuels.
  static const LinearGradient goldRose = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.roseGold, AppColors.gold],
  );

  /// Or vieilli : variante sourde pour les états inactifs/verrouillés.
  static const LinearGradient goldAged = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.agedGold, AppColors.goldDark],
  );

  static const LinearGradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14243A), Color(0xFF0E1929)],
  );

  static const LinearGradient heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF173B63), Color(0xFF0C2340)],
  );

  /// En-tête de travail en bleu nuit, légèrement relevé par rapport au fond.
  static const LinearGradient workspaceHeader = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF101D30), Color(0xFF0B1524)],
  );

  /// Surface de verre fumé des barres de navigation.
  static const LinearGradient smokedGlass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0C1A2B), Color(0xFF070D17)],
  );
}

/// Rayons de bordure standardisés.
class AppRadius {
  const AppRadius._();

  static const double small = 10;
  static const double medium = 16;
  static const double large = 24;
  static const double pill = 999;
}

/// Échelle d'espacement standardisée (grille de 4px). Les intérieurs de
/// cartes utilisent désormais [md]–[lg] plutôt que [sm]–[md] pour une
/// respiration plus haut de gamme.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Espacement des lettres pour la typographie de precision.
class AppLetterSpacing {
  const AppLetterSpacing._();

  static const double display = 1.6;
  static const double headline = 1.0;
  static const double title = 0.3;
  static const double label = 0.4;

  /// Espacement large pour un libellé entièrement en capitales.
  static const double caps = 2.2;
}

/// Rythme d'animation partagé. Les interactions majeures utilisent 300 ms
/// et une courbe de décélération nette, afin que les écrans mobiles et
/// desktop donnent la même impression de continuité.
class AppMotion {
  const AppMotion._();

  static const Duration standard = Duration(milliseconds: 300);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration slow = Duration(milliseconds: 520);
  static const Curve premium = Cubic(0.22, 1.0, 0.36, 1.0);
}

/// Seuils de mise en page utilisés par les composants réutilisables. Les
/// features restent libres de définir leurs propres seuils lorsqu'un écran
/// demande une composition particulière.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 600;
  static const double medium = 1024;
  static const double wide = 1440;
  static const double contentMaxWidth = 1200;
}

/// Ombres bleutées légères pour détacher les surfaces blanches du canevas.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: const Color(0xFF18314D).withValues(alpha: 0.08),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: const Color(0xFF18314D).withValues(alpha: 0.11),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: const Color(0xFF18314D).withValues(alpha: 0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 2),
    ),
  ];

  /// Trois couches pour les surfaces qui doivent sembler « soulevées »
  /// au-dessus du reste de l'écran (nav flottante, modales) : une ombre
  /// ambiante large et sombre, une ombre de contact serrée qui ancre la
  /// surface, et une lueur or très douce qui la distingue du fond.
  static List<BoxShadow> floating = [
    BoxShadow(
      color: const Color(0xFF18314D).withValues(alpha: 0.12),
      blurRadius: 36,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: const Color(0xFF18314D).withValues(alpha: 0.07),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 0),
    ),
  ];

  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.35),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> goldGlowSoft = [
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.45),
      blurRadius: 14,
      offset: const Offset(0, 0),
    ),
  ];
}

/// Configuration centrale du thème visuel de JurisIA.
class AppTheme {
  const AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.deepSlate,
      canvasColor: AppColors.deepSlate,
      primaryColor: AppColors.cobalt,
      splashColor: AppColors.gold.withValues(alpha: 0.10),
      highlightColor: AppColors.gold.withValues(alpha: 0.06),
      hoverColor: AppColors.gold.withValues(alpha: 0.05),
      focusColor: AppColors.cobalt.withValues(alpha: 0.18),
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.cobalt,
        selectionColor: AppColors.cobalt.withValues(alpha: 0.28),
        selectionHandleColor: AppColors.cobalt,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _LuxuryFadeThroughTransitionsBuilder(),
          TargetPlatform.iOS: _LuxuryFadeThroughTransitionsBuilder(),
          TargetPlatform.macOS: _LuxuryFadeThroughTransitionsBuilder(),
          TargetPlatform.windows: _LuxuryFadeThroughTransitionsBuilder(),
          TargetPlatform.linux: _LuxuryFadeThroughTransitionsBuilder(),
        },
      ),
      colorScheme: const ColorScheme.dark(
        brightness: Brightness.dark,
        primary: AppColors.cobalt,
        onPrimary: Colors.white,
        primaryContainer: AppColors.cobaltDeep,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.cobalt,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFF18304C),
        onSecondaryContainer: AppColors.textPrimary,
        surface: AppColors.deepSlateElevated,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: Color(0xFF1A2A3F),
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.divider,
        outlineVariant: AppColors.glassBorder,
        shadow: Color(0x66000000),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.deepSlateDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.cobaltLight),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.deepSlateElevated,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.6,
        space: AppSpacing.lg,
      ),
      iconTheme: const IconThemeData(color: AppColors.cobalt, size: 22),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cobalt,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.cobalt.withValues(alpha: 0.28),
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cobaltLight,
          side: BorderSide(color: AppColors.cobalt.withValues(alpha: 0.45), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cobaltLight,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.deepSlateElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDisabled),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.cobalt, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.error, width: 0.6),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 72,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? AppColors.cobaltLight : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.cobaltLight : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppColors.cobaltLight, size: 24),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.cobaltLight,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
        indicatorColor: Colors.transparent,
        useIndicator: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF15263B),
        selectedColor: AppColors.cobalt.withValues(alpha: 0.34),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.cobaltLight),
        side: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.8), width: 0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.deepSlateElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.legalBlue,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textOnDark),
        actionTextColor: AppColors.goldLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.cobaltLight,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.cobaltLight,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.cobaltLight,
        linearTrackColor: Color(0xFF263A52),
        circularTrackColor: Color(0xFF263A52),
      ),
      dividerColor: AppColors.divider,
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.cobaltLight,
        textColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.gold : AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.cobalt.withValues(alpha: 0.4)
              : const Color(0xFF263A52);
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.legalBlue,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.glassBorder),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.textOnDark),
      ),
    );
  }

  /// Alias conservé pour les anciens points d'entrée du thème.
  static ThemeData get darkTheme => lightTheme;

  static TextTheme _buildTextTheme(TextTheme base) {
    final serif = base.apply(fontFamily: 'Libre Caslon Display');
    final sans = base.apply(fontFamily: 'Public Sans');

    return sans
        .copyWith(
          displayLarge: serif.displayLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.display,
          ),
          displayMedium: serif.displayMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.display,
          ),
          displaySmall: serif.displaySmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.headline,
          ),
          headlineLarge: serif.headlineLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.headline,
          ),
          headlineMedium: serif.headlineMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.headline,
          ),
          headlineSmall: serif.headlineSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          titleLarge: sans.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.title,
          ),
          titleMedium: sans.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.title,
          ),
          titleSmall: sans.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.title,
          ),
          bodyLarge: sans.bodyLarge?.copyWith(color: AppColors.textPrimary, height: 1.5),
          bodyMedium: sans.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
          bodySmall: sans.bodySmall?.copyWith(color: AppColors.textSecondary),
          labelLarge: sans.labelLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: AppLetterSpacing.label,
          ),
          labelMedium: sans.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
          labelSmall: sans.labelSmall?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.2),
        )
        .apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary);
  }
}

/// Transition de page en fondu enchaîné, plus sobre et plus lente (320ms,
/// `Curves.fastOutSlowIn`) que les transitions plateforme par défaut, pour
/// une navigation fluide et haut de gamme sur toutes les plateformes.
class _LuxuryFadeThroughTransitionsBuilder extends PageTransitionsBuilder {
  const _LuxuryFadeThroughTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.premium);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.02), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
