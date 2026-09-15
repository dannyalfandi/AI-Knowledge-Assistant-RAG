import 'package:flutter/material.dart';

/// A single magnitude bar on a shared track.
///
/// Every bar on the breakdown uses the same hue on purpose: the bar's job is
/// magnitude, and identity is already carried by the labelled chip beside it.
/// Colouring each row differently would double-encode length as hue and, with
/// this theme's desaturated palette, produce adjacent colours that are not
/// reliably distinguishable anyway.
class ProportionBar extends StatelessWidget {
  const ProportionBar({
    super.key,
    required this.value,
    required this.total,
    this.color,
    this.height = 8,
  });

  final int value;
  final int total;

  /// Defaults to the theme's primary hue.
  final Color? color;

  final double height;

  double get _fraction {
    if (total <= 0) return 0;
    return (value / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = color ?? theme.colorScheme.primary;

    return Semantics(
      label: '$value dari $total',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // The track carries the whole, so a short bar still reads as a
              // fraction of something rather than as a lone stub.
              Positioned.fill(
                child: ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              FractionallySizedBox(
                widthFactor: _fraction,
                child: ColoredBox(color: fill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
