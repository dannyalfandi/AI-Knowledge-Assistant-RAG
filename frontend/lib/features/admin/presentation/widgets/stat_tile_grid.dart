import 'package:flutter/material.dart';

/// Lays stat tiles out in as many equal columns as the width allows, down to
/// one on a phone. A fixed cross-axis count would either crowd a narrow screen
/// or strand the tiles in a column on a wide one.
class StatTileGrid extends StatelessWidget {
  const StatTileGrid({super.key, required this.tiles, this.minTileWidth = 220});

  final List<Widget> tiles;
  final double minTileWidth;

  static const _spacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minTileWidth).floor().clamp(
          1,
          tiles.length,
        );
        final tileWidth =
            (constraints.maxWidth - _spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: _spacing,
          runSpacing: _spacing,
          children: [
            for (final tile in tiles) SizedBox(width: tileWidth, child: tile),
          ],
        );
      },
    );
  }
}
