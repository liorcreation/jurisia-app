import 'dart:io';

/// Natif : caméra prise en charge sur Android, iOS et Windows
/// (`camera_windows`, non endorsé mais ajouté explicitement — voir
/// pubspec.yaml). Exclut délibérément macOS, faute d'implémentation
/// caméra Flutter fiable et vérifiable dans cet environnement.
bool get isCameraGuardSupportedPlatform => Platform.isAndroid || Platform.isIOS || Platform.isWindows;
