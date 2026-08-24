import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palette officielle de la charte graphique JurisIA — « Glassmorphism
/// sombre juridique ». Trois couleurs porteuses : le Bleu Nuit en fond, le
/// Bleu Juridique pour les surfaces de verre, et l'Or Élégant réservé aux
/// accents, utilisé avec parcimonie. Le Bleu Cobalt est l'unique accent
/// secondaire, réservé au focus et au curseur de saisie.
class AppColors {
  const AppColors._();

  static const Color nightBlue = Color(0xFF0B1F3A);
  static const Color nightBlueDeep = Color(0xFF071527);
  static const Color legalBlue = Color(0xFF163B68);
  static const Color legalBlueLight = Color(0xFF1F4C82);
  static const Color legalBlueDark = Color(0xFF0F2C4E);

  static const Color gold = Color(0xFFC9A227);
  static const Color goldLight = Color(0xFFE9D48A);
  static const Color goldDark = Color(0xFF8A6A15);
  static const Color roseGold = Color(0xFFD9A98A);
  static const Color agedGold = Color(0xFF7C6122);

  /// Bleu cobalt vif : unique accent secondaire, réservé au focus de
  /// saisie et au curseur, pour une touche de précision sans diluer l'or.
  static const Color cobalt = Color(0xFF2E6FF2);

  static const Color textPrimary = Color(0xFFF4F1E9);
  static const Color textSecondary = Color(0xFFB7C3D6);
  static const Color textDisabled = Color(0xFF6C7A91);

  static const Color glassFill = Color(0x33163B68);
  static const Color glassBorder = Color(0x33C9A227);
  static const Color glassHighlight = Color(0x1AFFFFFF);

  /// Surface « verre fumé » des barres de navigation.
  static const Color smokedGlass = Color(0xCC071527);

  static const Color divider = Color(0x33B7C3D6);

  static const Color success = Color(0xFF3FA772);
  static const Color warning = Color(0xFFE0A93E);
  static const Color error = Color(0xFFC85450);
  static const Color info = Color(0xFF4C8BC9);

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
  static const Color metalDeepGold = Color(0xFFC9A227);
}

/// Dégradés métalliques et d'ambiance utilisés dans toute l'application.
class AppGradients {
  const AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.nightBlueDeep, AppColors.nightBlue],
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
    colors: [Color(0x40244B7D), Color(0x22163B68)],
  );

  static const LinearGradient heroCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.legalBlueLight, AppColors.legalBlueDark],
  );

  /// Surface de verre fumé des barres de navigation.
  static const LinearGradient smokedGlass = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xE60F2C4E), Color(0xF2071527)],
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

/// Ombres portées cohérentes avec l'ambiance nocturne et dorée.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.nightBlueDeep.withValues(alpha: 0.45),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> cardElevated = [
    BoxShadow(
      color: AppColors.nightBlueDeep.withValues(alpha: 0.55),
      blurRadius: 32,
      offset: const Offset(0, 18),
    ),
    BoxShadow(
      color: AppColors.gold.withValues(alpha: 0.08),
      blurRadius: 18,
      offset: const Offset(0, 2),
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

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildTextTheme(base.textTheme);

    return base.copyWith(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.nightBlue,
      canvasColor: AppColors.nightBlue,
      primaryColor: AppColors.gold,
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
        primary: AppColors.gold,
        onPrimary: AppColors.nightBlueDeep,
        primaryContainer: AppColors.goldDark,
        onPrimaryContainer: AppColors.textPrimary,
        secondary: AppColors.cobalt,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.legalBlue,
        onSecondaryContainer: AppColors.textPrimary,
        surface: AppColors.legalBlue,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.legalBlueDark,
        error: AppColors.error,
        onError: AppColors.textPrimary,
        outline: AppColors.divider,
        outlineVariant: AppColors.glassBorder,
        shadow: AppColors.nightBlueDeep,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.gold),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.legalBlue.withValues(alpha: 0.42),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35), width: 0.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 0.6,
        space: AppSpacing.lg,
      ),
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 22),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.nightBlueDeep,
          disabledBackgroundColor: AppColors.goldDark.withValues(alpha: 0.3),
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: AppLetterSpacing.label,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.7), width: 1),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldLight,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.legalBlueDark.withValues(alpha: 0.5),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textDisabled),
        labelStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.6),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.glassBorder, width: 0.6),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          borderSide: const BorderSide(color: AppColors.cobalt, width: 1),
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
            color: selected ? AppColors.gold : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.gold : AppColors.textSecondary,
            size: 24,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: const IconThemeData(color: AppColors.gold, size: 24),
        unselectedIconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.gold,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: AppColors.textSecondary,
        ),
        indicatorColor: Colors.transparent,
        useIndicator: true,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.legalBlueDark.withValues(alpha: 0.6),
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
        labelStyle: textTheme.labelMedium?.copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: AppColors.gold),
        side: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.8), width: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.legalBlue,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35), width: 0.5),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.legalBlueDark,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35), width: 0.5),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.gold,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.legalBlueDark,
        circularTrackColor: AppColors.legalBlueDark,
      ),
      dividerColor: AppColors.divider,
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.gold,
        textColor: AppColors.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? AppColors.gold : AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? AppColors.gold.withValues(alpha: 0.4)
              : AppColors.legalBlueDark;
        }),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.nightBlueDeep,
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(color: AppColors.glassBorder),
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    final serif = GoogleFonts.cinzelTextTheme(base);
    final sans = GoogleFonts.plusJakartaSansTextTheme(base);

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
          labelMedium: sans.labelMedium?.copyWith(color: AppColors.textSecondary, letterSpacing: 0.2),
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
    final curved = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
