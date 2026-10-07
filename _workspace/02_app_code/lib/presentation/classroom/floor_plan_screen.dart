import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../domain/entities/floor_plan.dart';
import '../../l10n/gen/app_localizations.dart';
import 'widgets/floor_plan_view.dart';

/// Full-screen floor plan (pinch-zoom / pan / double-tap) opened from the
/// room card in the map peek sheet. Starts zoomed in and centred on the red
/// dot; later viewport changes (rotation, split screen) keep the user's zoom
/// and the plan point under the centre instead of resetting (L-5).
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

  /// Double-tap zoom level; a second double-tap returns to the fitted plan
  /// (L-33).
  static const _doubleTapScale = 2.5;

  final _ctrl = TransformationController();
  Size? _viewport;
  Offset? _doubleTapScene;

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

  /// Top-left of the fitted plan inside [viewport].
  Offset _fitOffset(Size viewport, Size fit) => Offset(
      (viewport.width - fit.width) / 2, (viewport.height - fit.height) / 2);

  /// Transform that shows plan point [u] (unit fractions) at the centre of
  /// [viewport] at [scale].
  Matrix4 _centreOn(Size viewport, Offset u, double scale) {
    final fit = _fitted(viewport);
    final point =
        _fitOffset(viewport, fit) + Offset(u.dx * fit.width, u.dy * fit.height);
    final t = viewport.center(Offset.zero) - point * scale;
    return Matrix4.identity()
      ..translateByDouble(t.dx, t.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  /// Zoom so the dot sits in the middle of the viewport.
  Matrix4 _focusOnRoom(Size viewport) {
    final room = widget.location.room;
    return _centreOn(viewport, Offset(room.x, room.y), _initialScale);
  }

  /// Transform for [next] that keeps the plan point currently centred in
  /// [prev] (under [m]) centred, at the same zoom.
  Matrix4 _carryOver(Size prev, Size next, Matrix4 m) {
    final scale = m.getMaxScaleOnAxis();
    final inverse = Matrix4.tryInvert(m);
    if (inverse == null || scale <= 0) return _focusOnRoom(next);
    final centreScene =
        MatrixUtils.transformPoint(inverse, prev.center(Offset.zero));
    final fit = _fitted(prev);
    final o = _fitOffset(prev, fit);
    final u = Offset(
        (centreScene.dx - o.dx) / fit.width, (centreScene.dy - o.dy) / fit.height);
    return _centreOn(next, u, scale);
  }

  /// Called from the layout builder: applies the room focus on the first
  /// layout only, and carries the current view over on size changes. The
  /// controller write notifies the viewer (setState), so it is deferred to
  /// after the frame rather than done mid-layout (L-28).
  void _onViewport(Size viewport) {
    final prev = _viewport;
    if (prev == viewport) return;
    _viewport = viewport;
    final next = prev == null
        ? _focusOnRoom(viewport)
        : _carryOver(prev, viewport, _ctrl.value);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.value = next;
    });
  }

  /// Zoom to [scale] keeping the scene point [scene] fixed on screen.
  Matrix4 _zoomAt(Offset scene, double scale) {
    final onScreen = MatrixUtils.transformPoint(_ctrl.value, scene);
    final t = onScreen - scene * scale;
    return Matrix4.identity()
      ..translateByDouble(t.dx, t.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _toggleZoom() {
    final scene = _doubleTapScene;
    if (scene == null) return;
    final zoomedIn = _ctrl.value.getMaxScaleOnAxis() > 1.01;
    _ctrl.value =
        zoomedIn ? Matrix4.identity() : _zoomAt(scene, _doubleTapScale);
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
            onPressed: () {
              final viewport = _viewport;
              if (viewport != null) _ctrl.value = _focusOnRoom(viewport);
            },
          ),
        ],
      ),
      // Drawings are white-background artwork; keep them on white in dark
      // mode so walls and labels keep their contrast.
      backgroundColor: Colors.white,
      body: LayoutBuilder(builder: (context, c) {
        final viewport = Size(c.maxWidth, c.maxHeight);
        _onViewport(viewport);
        final fit = _fitted(viewport);
        return InteractiveViewer(
          transformationController: _ctrl,
          minScale: 1,
          maxScale: 8,
          boundaryMargin: EdgeInsets.all(viewport.shortestSide / 2),
          child: Semantics(
            hint: l.floorplan_doubleTapZoom,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              // localPosition is in the child's (scene) space, which is what
              // the zoom maths wants.
              onDoubleTapDown: (d) => _doubleTapScene = d.localPosition,
              onDoubleTap: _toggleZoom,
              child: SizedBox(
                width: viewport.width,
                height: viewport.height,
                child: Center(
                  child: SizedBox(
                    width: fit.width,
                    height: fit.height,
                    // Thin base border / small dot — they scale up with the
                    // zoom.
                    child: FloorPlanView(
                      plan: loc.plan,
                      room: loc.room,
                      strokeWidth: 1.2,
                      dotSize: 7,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
