import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/floor_plan.dart';
import '../../l10n/gen/app_localizations.dart';
import 'widgets/floor_plan_view.dart';

/// Full-screen floor plan (pinch-zoom / pan) opened from the room card in the
/// map peek sheet. Starts zoomed in and centred on the red dot.
class FloorPlanScreen extends StatefulWidget {
  const FloorPlanScreen({
    super.key,
    required this.location,
    required this.title,
  });

  final RoomLocation location;

  /// e.g. "S04-0306-1 · 공과대학2호관".
  final String title;

  @override
  State<FloorPlanScreen> createState() => _FloorPlanScreenState();
}

class _FloorPlanScreenState extends State<FloorPlanScreen> {
  static const _initialScale = 2.5;

  final _ctrl = TransformationController();
  Size? _viewport;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Plan size when fitted (contain) into [viewport].
  Size _fitted(Size viewport) {
    final ar = widget.location.plan.aspectRatio;
    return viewport.width / viewport.height > ar
        ? Size(viewport.height * ar, viewport.height)
        : Size(viewport.width, viewport.width / ar);
  }

  /// Zoom so the dot sits in the middle of the viewport.
  Matrix4 _focusOnRoom(Size viewport) {
    final fit = _fitted(viewport);
    final offset = Offset(
        (viewport.width - fit.width) / 2, (viewport.height - fit.height) / 2);
    final room = widget.location.room;
    final dot = offset + Offset(room.x * fit.width, room.y * fit.height);
    final center = viewport.center(Offset.zero);
    final t = center - dot * _initialScale;
    return Matrix4.identity()
      ..translateByDouble(t.dx, t.dy, 0, 1)
      ..scaleByDouble(_initialScale, _initialScale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loc = widget.location;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: l.classroom_plan_recenter,
            icon: const Icon(Symbols.center_focus_strong),
            onPressed: _viewport == null
                ? null
                : () => _ctrl.value = _focusOnRoom(_viewport!),
          ),
        ],
      ),
      // Drawings are white-background artwork; keep them on white in dark
      // mode so walls and labels keep their contrast.
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, c) {
        final viewport = Size(c.maxWidth, c.maxHeight);
        if (_viewport != viewport) {
          _viewport = viewport;
          _ctrl.value = _focusOnRoom(viewport);
        }
        final fit = _fitted(viewport);
        return InteractiveViewer(
          transformationController: _ctrl,
          minScale: 1,
          maxScale: 8,
          boundaryMargin: EdgeInsets.all(viewport.shortestSide / 2),
          child: SizedBox(
            width: viewport.width,
            height: viewport.height,
            child: Center(
              child: SizedBox(
                width: fit.width,
                height: fit.height,
                // Thin base border / small dot — they scale up with the zoom.
                child: FloorPlanView(
                  plan: loc.plan,
                  room: loc.room,
                  strokeWidth: 1.2,
                  dotSize: 7,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
