import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Rappels locaux liés à l'examen blanc : programme une notification
/// ~24h avant la fin du verrou de 7 jours consécutif à un échec, pour inciter
/// l'étudiant à reconsulter le cours avant de retenter. Notifications
/// locales uniquement (pas de Firebase) — un backend de push distant
/// rouvrirait le même mur payant Apple Developer déjà rencontré pour
/// Sign in with Apple.
///
/// Repli gracieux : si l'initialisation échoue (permission refusée,
/// plateforme non supportée), l'app continue sans rappels plutôt que de
/// planter — le suivi normal du verrou en base reste la source de vérité.
class NotificationService {
  const NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static bool get isReady => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz_data.initializeTimeZones();

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      );

      await _plugin.initialize(settings);
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      _initialized = true;
    } catch (error) {
      // ignore: avoid_print
      print('Notifications locales indisponibles (rappels désactivés) : $error');
    }
  }

  /// Programme le rappel de fin de verrou pour un niveau, ou ne fait rien si
  /// le délai est déjà écoulé ou les notifications indisponibles.
  static Future<void> scheduleMockExamRetryReminder({
    required String levelId,
    required String levelLabel,
    required DateTime lockedUntil,
  }) async {
    if (!_initialized) return;

    final reminderTime = lockedUntil.subtract(const Duration(hours: 24));
    if (reminderTime.isBefore(DateTime.now())) return;

    try {
      await _plugin.zonedSchedule(
        levelId.hashCode,
        'Votre examen blanc redevient bientôt accessible',
        'Reconsultez le cours de $levelLabel dès maintenant pour être prêt à retenter demain.',
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mock_exam_reminders',
            'Rappels d\'examen blanc',
            channelDescription: 'Rappels avant la fin du verrou de réécriture d\'un examen blanc',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        // Inexact plutôt qu'exact : évite d'exiger la permission spéciale
        // « Alarmes et rappels » (SCHEDULE_EXACT_ALARM, Android 12+) pour un
        // simple rappel à ~24h près, sans contrainte de précision.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (error) {
      // ignore: avoid_print
      print("Échec de la programmation du rappel d'examen blanc ($levelId) : $error");
    }
  }

  /// Annule un rappel programmé (résultat déjà réussi entre-temps, par
  /// exemple).
  static Future<void> cancelMockExamRetryReminder(String levelId) async {
    if (!_initialized) return;
    await _plugin.cancel(levelId.hashCode);
  }
}
