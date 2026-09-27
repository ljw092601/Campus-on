import 'package:flutter/material.dart';

import '../../../domain/entities/floor_plan.dart';

/// Red marker colour for the searched room (kept off the theme on purpose —
/// "red dot = you are looking for this" reads the same in light and dark).
const _dotColor = Color(0xFFE53935);

/// Floor-plan drawing with a pulsing red dot on [room]. Sizes itself to the
/// drawing's aspect ratio; the dot is positioned in image fractions so it
/// tracks any scale (including inside an [InteractiveViewer]).
class FloorPlanView extends StatelessWidget {
  const FloorPlanView({
    super.key,
    required this.plan,
    required this.room,
    this.dotSize = 13,
    this.decodeWidth,
  });

  final FloorPlan plan;
  final PlanRoom room;

  /// Dot diameter in logical pixels at the widget's rendered size.
  final double dotSize;

  /// Decode the drawing at this pixel width (thumbnail use) instead of its
  /// full 2400px — a full decode is ~15 MB of texture.
  final int? decodeWidth;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: plan.aspectRatio,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final rect = room.rect;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                plan.asset,
                fit: BoxFit.contain,
                cacheWidth: decodeWidth,
                filterQuality: FilterQuality.medium,
              ),
            ),
            if (rect != null)
              Positioned(
                left: rect[0] * w,
                top: rect[1] * h,
                width: rect[2] * w,
                height: rect[3] * h,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: _dotColor.withValues(alpha: 0.12),
                      border: Border.all(
                          color: _dotColor.withValues(alpha: 0.8),
                          width: dotSize / 8),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: room.x * w - dotSize * 1.5,
              top: room.y * h - dotSize * 1.5,
              width: dotSize * 3,
              height: dotSize * 3,
              child: IgnorePointer(child: _PulsingDot(size: dotSize)),
            ),
          ],
        );
      }),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.size});
  final double size;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Center(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = reduceMotion ? 0.0 : _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              if (!reduceMotion)
                Container(
                  width: s * (1 + 2 * t),
                  height: s * (1 + 2 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _dotColor.withValues(alpha: 0.35 * (1 - t)),
                  ),
                ),
              Container(
                width: s,
                height: s,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _dotColor,
                  border: Border.all(color: Colors.white, width: s / 6),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
