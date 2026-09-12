import 'package:flutter/material.dart';

/// Assistant-side bubble with three pulsing dots, shown while `/ask` is in
/// flight. A chat-shaped wait reads as "the assistant is composing an answer",
/// which a generic spinner does not.
class TypingIndicatorBubble extends StatefulWidget {
  const TypingIndicatorBubble({super.key});

  @override
  State<TypingIndicatorBubble> createState() => _TypingIndicatorBubbleState();
}

class _TypingIndicatorBubbleState extends State<TypingIndicatorBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        child: Semantics(
          label: 'Asisten sedang menyiapkan jawaban',
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < 3; index++) ...[
                    if (index > 0) const SizedBox(width: 6),
                    _Dot(
                      color: colors.onSurfaceVariant,
                      progress: _controller.value,
                      index: index,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.color,
    required this.progress,
    required this.index,
  });

  final Color color;
  final double progress;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Each dot runs the same wave a third of a cycle behind the previous one.
    final phase = (progress + index / 3) % 1.0;
    final wave = 1 - (phase * 2 - 1).abs();

    return Opacity(
      opacity: 0.35 + wave * 0.65,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
