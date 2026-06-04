import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Renders custom teardrop map-pin bitmaps for use as [BitmapDescriptor]s.
///
/// Each pin is a filled circle with a centred icon and a downward-pointing
/// tail, rendered at 3× pixel density so they look sharp on retina screens.
/// Call [build] once per pin type and cache the result — rendering is async.
class MapMarkerIcons {
  const MapMarkerIcons._();

  /// Logical size of the circular pin body in dp.
  static const double _bodyDp = 40.0;

  /// Height of the teardrop tail as a fraction of [_bodyDp].
  static const double _tailRatio = 0.38;

  /// Pixel ratio used for the off-screen render.
  static const double _px = 3.0;

  static Future<BitmapDescriptor> build(
    Color color,
    IconData icon, {
    double bodyDp = _bodyDp,
  }) async {
    final body = bodyDp * _px;
    final tail = body * _tailRatio;
    final totalH = body + tail;
    final cx = body / 2;
    final cy = body / 2;
    final r = body / 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, body, totalH),
    );

    // ── White border circle ───────────────────────────────────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()..color = Colors.white,
    );

    // ── Coloured fill circle ──────────────────────────────────────────────────
    const borderThickness = 2.5 * _px;
    canvas.drawCircle(
      Offset(cx, cy),
      r - borderThickness,
      Paint()..color = color,
    );

    // ── Teardrop tail ─────────────────────────────────────────────────────────
    // The tail starts at two points near the bottom of the circle and meets at
    // a sharp point below it.
    final tailW = body * 0.22;
    final tailTop = body * 0.72; // where the tail meets the circle
    final tailTip = totalH - 1;

    final tailPath = Path()
      ..moveTo(cx - tailW, tailTop)
      ..lineTo(cx + tailW, tailTop)
      ..lineTo(cx, tailTip)
      ..close();

    canvas.drawPath(tailPath, Paint()..color = color);

    // ── Re-draw a small arc to smooth the circle-tail join ────────────────────
    canvas.drawCircle(
      Offset(cx, cy),
      r - borderThickness,
      Paint()..color = color,
    );

    // ── Icon (Material Icons font via TextPainter) ────────────────────────────
    final iconSize = body * 0.46;
    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: Colors.white,
        ),
      ),
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        cx - iconPainter.width / 2,
        cy - iconPainter.height / 2,
      ),
    );

    // ── Convert to BitmapDescriptor ───────────────────────────────────────────
    final picture = recorder.endRecording();
    final image = await picture.toImage(body.round(), totalH.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: bodyDp,
      height: bodyDp + bodyDp * _tailRatio,
    );
  }
}
