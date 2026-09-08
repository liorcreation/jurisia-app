/// Web : la caméra passe par `camera_web` (getUserMedia du navigateur),
/// disponible quel que soit le système d'exploitation sous-jacent —
/// y compris sur un Mac utilisé via le navigateur, à la différence de
/// l'application native macOS (voir exam_camera_support_io.dart).
bool get isCameraGuardSupportedPlatform => true;
