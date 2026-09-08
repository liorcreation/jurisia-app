import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../theme/app_theme.dart';

/// Extrait l'identifiant de vidéo d'une URL YouTube (classique, `youtu.be`,
/// ou déjà au format `embed/`), ou `null` si l'URL est illisible.
String? _extractVideoId(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;

  if (uri.host.contains('youtu.be')) {
    return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
  }
  if (uri.pathSegments.contains('embed')) {
    final index = uri.pathSegments.indexOf('embed');
    return index + 1 < uri.pathSegments.length ? uri.pathSegments[index + 1] : null;
  }
  return uri.queryParameters['v'];
}

/// Lecteur vidéo YouTube (non répertorié) encadré au registre visuel de
/// JurisIA : cadre verre et liseré or, cohérent avec [GlassContainer].
/// Fonctionne aussi bien sur web que sur mobile/desktop natif.
class YoutubeEmbedView extends StatefulWidget {
  const YoutubeEmbedView({super.key, required this.videoUrl});

  final String videoUrl;

  @override
  State<YoutubeEmbedView> createState() => _YoutubeEmbedViewState();
}

class _YoutubeEmbedViewState extends State<YoutubeEmbedView> {
  YoutubePlayerController? _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = _extractVideoId(widget.videoUrl);
    final videoId = _videoId;
    if (videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true, strictRelatedVideos: true),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final radius = BorderRadius.circular(AppRadius.medium);

    if (controller == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: AppColors.legalBlueDark.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 0.8),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'Vidéo indisponible (lien non reconnu).',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.35), width: 0.9),
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: YoutubePlayer(controller: controller),
        ),
      ),
    );
  }
}
