import 'package:equatable/equatable.dart';

/// État d'un quota mensuel : ce qui est consommé, ce qui est autorisé.
///
/// [limit] `null` = illimité. Sert aux jauges d'usage de l'écran
/// « Mon abonnement » et à la décision de la porte d'accès (voir
/// [EntitlementsController.tryConsume]).
class QuotaState extends Equatable {
  const QuotaState({required this.limit, required this.used});

  /// Quota illimité déjà consommé [used] fois (pour l'affichage).
  const QuotaState.unlimited({int used = 0}) : this(limit: null, used: used);

  /// Plafond mensuel, ou `null` si illimité.
  final int? limit;

  /// Nombre d'unités déjà consommées ce mois-ci.
  final int used;

  bool get isUnlimited => limit == null;

  bool get isExhausted => limit != null && used >= limit!;

  /// Unités restantes, ou `null` si illimité.
  int? get remaining => limit == null ? null : (limit! - used).clamp(0, limit!);

  /// Progression 0..1 pour la jauge, ou `null` si illimité.
  double? get fraction {
    final max = limit;
    if (max == null || max == 0) return null;
    return (used / max).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [limit, used];
}
