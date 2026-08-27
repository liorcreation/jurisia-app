import 'package:flutter/material.dart';

import '../../features/profile/domain/entities/user_profile.dart';
import '../widgets/jurisia_mark.dart';
import '../widgets/shimmer_sweep.dart';
import '../../theme/app_theme.dart';

/// Monogramme profil — disque au dégradé métallique **déterministe** (dérivé
/// de l'id du compte), initiales gravées en serif, marque JurisIA en
/// filigrane, et un anneau or animé d'un lent balayage. Signature visuelle
/// unique de la carte profil.
class ProfileMonogram extends StatelessWidget {
  const ProfileMonogram({super.key, required this.profile, this.size = 40, this.animated = true});

  final UserProfile? profile;
  final double size;
  final bool animated;

  static const List<List<Color>> _metals = [
    [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
    [Color(0xFFDCE3EE), AppColors.metalSilver, AppColors.metalGunmetal],
    [Color(0xFFE7C6A8), AppColors.metalBronze, Color(0xFF7C5836)],
    [Color(0xFF8FC7B0), AppColors.metalEmerald, Color(0xFF3C6E59)],
    [Color(0xFF9FC0F0), AppColors.metalCobalt, Color(0xFF3B5C93)],
    [Color(0xFFE9C9C0), AppColors.metalRoseGold, Color(0xFF9E6F63)],
  ];

  List<Color> get _palette {
    final seed = profile?.id ?? profile?.email ?? '';
    if (seed.isEmpty) return _metals.first;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _metals[hash % _metals.length];
  }

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final initials = profile?.initials ?? '?';

    final disc = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette,
        ),
        boxShadow: [
          BoxShadow(
            color: palette[1].withValues(alpha: 0.35),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.14,
            child: JurisIAMark(
              size: size * 0.92,
              gradient: const LinearGradient(
                colors: [AppColors.nightBlueDeep, AppColors.nightBlueDeep],
              ),
            ),
          ),
          Text(
            initials,
            style: TextStyle(
              fontFamily: 'Libre Caslon Display',
              fontWeight: FontWeight.w700,
              fontSize: size * 0.4,
              height: 1,
              color: AppColors.nightBlueDeep,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );

    final ringed = Container(
      padding: EdgeInsets.all(size * 0.05),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1),
      ),
      child: ClipOval(child: disc),
    );

    if (!animated) return ringed;
    return ClipOval(
      child: ShimmerSweep(duration: const Duration(milliseconds: 3200), child: ringed),
    );
  }
}
