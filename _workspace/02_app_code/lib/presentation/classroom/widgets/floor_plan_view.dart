import 'package:flutter/material.dart';

import '../../../domain/entities/floor_plan.dart';

/// Red marker colour for the searched room (kept off the theme on purpose —
/// "red = you are looking for this" reads the same in light and dark).
const _dotColor = Color(0xFFE53935);

/// Floor-plan drawing with the searched [room] highlighted: its real outline
/// filled light red with a softly pulsing red border. Rooms without a known
/// shape fall back to the rectangle, and rooms without either (several rooms
/// sharing one region on the drawing) to a small pulsing dot on the label.
/// Sizes itself to the drawing's aspect ratio; everything is positioned in
/// image fractions so it tracks any scale (including inside an
/// [InteractiveViewer]).
class FloorPlanView extends StatelessWidget {
  const FloorPlanView({
    super.key,
    required this.plan,
    required this.room,
    this.strokeWidth = 2,
    this.dotSize = 13,
    this.decodeWidth,
  });

  final FloorPlan plan;
  final PlanRoom room;

  /// Room border width in logical pixels at the widget's rendered size.
  final double strokeWidth;

  /// Fallback dot diameter in logical pixels at the widget's rendered size.
  final double dotSize;

  /// Decode the drawing at this pixel width (thumbnail use) instead of its
  /// full 2400px — a full decode is ~15 MB of texture.
  final int? decodeWidth;

  /// Room shape in unit (0..1) coordinates, or null when only the label
  /// point is known.
  List<Offset>? get _shape {
    final o = room.outline;
    if (o != null) {
      return [for (var i = 0; i + 1 < o.length; i += 2) Offset(o[i], o[i + 1])];
    }
    final r = room.rect;
    if (r != null) {
      return [
        Offset(r[0], r[1]),
        Offset(r[0] + r[2], r[1]),
        Offset(r[0] + r[2], r[1] + r[3]),
        Offset(r[0], r[1] + r[3]),
      ];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final shape = _shape;
    return AspectRatio(
      aspectRatio: plan.aspectRatio,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
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
            if (shape != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: _PulsingRoom(shape: shape, strokeWidth: strokeWidth),
                ),
              )
            else
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

/// Room highlight whose border and fill breathe slowly (static under
/// reduce-motion).
class _PulsingRoom extends StatefulWidget {
  const _PulsingRoom({required this.shape, required this.strokeWidth});

  final List<Offset> shape;
  final double strokeWidth;

  @override
  State<_PulsingRoom> createState() => _PulsingRoomState();
}

class _PulsingRoomState extends State<_PulsingRoom>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => CustomPaint(
        painter: _RoomPainter(
          shape: widget.shape,
          strokeWidth: widget.strokeWidth,
          t: reduceMotion ? 1 : Curves.easeInOut.transform(_ctrl.value),
        ),
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  const _RoomPainter({
    required this.shape,
    required this.strokeWidth,
    required this.t,
  });

  final List<Offset> shape;
  final double strokeWidth;

  /// Pulse phase 0..1.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addPolygon(
        [for (final p in shape) Offset(p.dx * size.width, p.dy * size.height)],
        true,
      );
    canvas.drawPath(
      path,
      Paint()..color = _dotColor.withValues(alpha: 0.14 + 0.10 * t),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..color = _dotColor.withValues(alpha: 0.45 + 0.55 * t),
    );
  }

  @override
  bool shouldRepaint(_RoomPainter old) =>
      old.t != t || old.shape != shape || old.strokeWidth != strokeWidth;
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
