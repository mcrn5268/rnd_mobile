import 'package:flutter/rendering.dart';

class MySliverGridDelegate extends SliverGridDelegate {
  final int crossAxisCount;
  final double desiredItemWidth;
  final double desiredItemHeight;

  MySliverGridDelegate({
    required this.crossAxisCount,
    required this.desiredItemWidth,
    required this.desiredItemHeight,
  });

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const crossAxisSpacing = 10;
    const mainAxisSpacing = 10;
    final crossAxisWidth = desiredItemWidth;
    final mainAxisHeight = desiredItemHeight;

    final totalGridWidth =
        (crossAxisWidth + crossAxisSpacing) * crossAxisCount - crossAxisSpacing;
    final screenWidth = constraints.crossAxisExtent;
    final padding = (screenWidth - totalGridWidth);

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: mainAxisHeight + mainAxisSpacing,
      crossAxisStride:
          crossAxisWidth + crossAxisSpacing + padding / crossAxisCount,
      childMainAxisExtent: mainAxisHeight,
      childCrossAxisExtent: crossAxisWidth + padding / crossAxisCount,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(MySliverGridDelegate oldDelegate) {
    return oldDelegate.crossAxisCount != crossAxisCount ||
        oldDelegate.desiredItemWidth != desiredItemWidth ||
        oldDelegate.desiredItemHeight != desiredItemHeight;
  }
}
