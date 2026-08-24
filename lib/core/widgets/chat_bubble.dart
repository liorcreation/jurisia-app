import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'glass_container.dart';

/// Bulle de message de chat en verre fumé sombre, partagée par l'assistant
/// juridique (Section 1) et le tuteur de module (Section 3) : bordure or
/// ultra-fine, et un reflet de réfraction qui glisse sur la surface à
/// l'apparition du message.
class ChatBubble extends StatefulWidget {
  const ChatBubble({super.key, required this.isUser, required this.child, this.footer});

  final bool isUser;
  final Widget child;

  /// Contenu optionnel affiché sous la bulle, hors du verre (ex. puce
  /// d'orientation vers un professionnel).
  final Widget? footer;

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _entranceController, curve: Curves.fastOutSlowIn);

    return Align(
      alignment: widget.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: widget.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              FadeTransition(
                opacity: CurvedAnimation(parent: _entranceController, curve: const Interval(0, 0.6)),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
                  child: GlassContainer(
                    borderRadius: AppRadius.large,
                    gradient: widget.isUser ? AppGradients.heroCard : AppGradients.glassCard,
                    borderColor: widget.isUser ? AppColors.gold.withValues(alpha: 0.5) : AppColors.glassBorder,
                    child: Stack(
                      children: [
                        widget.child,
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _entranceController,
                            builder: (context, _) => CustomPaint(
                              painter: _RefractionSweepPainter(progress: _entranceController.value),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (widget.footer != null) ...[
                const SizedBox(height: AppSpacing.xs),
                widget.footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Bulle d'erreur de chat, partagée par les mêmes deux assistants.
class ChatErrorBubble extends StatelessWidget {
  const ChatErrorBubble({super.key, required this.message, required this.onRetry, required this.onDismiss});

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: GlassContainer(
        borderColor: AppColors.error.withValues(alpha: 0.6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onDismiss, child: const Text('Ignorer')),
                if (onRetry != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Reflet diagonal qui glisse une fois sur la bulle à son apparition,
/// simulant une réfraction de la lumière sur le verre.
class _RefractionSweepPainter extends CustomPainter {
  const _RefractionSweepPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final band = -0.4 + progress * 2.0;
    final gradient = LinearGradient(
      begin: Alignment(band - 0.5, -1),
      end: Alignment(band, 1),
      colors: [
        Colors.transparent,
        AppColors.goldLight.withValues(alpha: 0.14),
        Colors.transparent,
      ],
      stops: const [0.3, 0.5, 0.7],
    );

    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  @override
  bool shouldRepaint(covariant _RefractionSweepPainter oldDelegate) => oldDelegate.progress != progress;
}
