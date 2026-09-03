import 'package:flutter/material.dart';

class ComicPanel extends StatelessWidget {
  const ComicPanel({
    required this.child,
    super.key,
    this.color,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderRadius = 6,
    this.shadowOffset = const Offset(4, 4),
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    return Padding(
      padding: margin,
      child: Padding(
        padding: EdgeInsets.only(
          right: shadowOffset.dx.abs(),
          bottom: shadowOffset.dy.abs(),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              left: shadowOffset.dx,
              top: shadowOffset.dy,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: radius,
                ),
              ),
            ),
            Material(
              color: color ?? Theme.of(context).colorScheme.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: radius,
                side: const BorderSide(color: Color(0xFF111111), width: 2.5),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ],
        ),
      ),
    );
  }
}
