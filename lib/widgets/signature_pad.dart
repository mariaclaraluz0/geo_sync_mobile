import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    this.controller,
    this.strokeWidth = 3.0,
    this.color = const Color(0xFF0B2A4A),
  });

  final SignaturePadController? controller;
  final double strokeWidth;
  final Color color;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadController {
  SignaturePadState? _state;

  void attach(SignaturePadState state) => _state = state;

  void clear() => _state?._clear();

  Future<Uint8List?> toPng() => _state?.toPng() ?? Future.value(null);
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = <List<Offset>>[];
  final GlobalKey _repaintKey = GlobalKey();

  void _clear() {
    if (!mounted) return;
    setState(() => _strokes.clear());
  }

  Future<Uint8List?> toPng() async {
    final context = _repaintKey.currentContext;
    if (context == null) return null;
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return null;
    final image = await renderObject.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(this);
  }

  @override
  void didUpdateWidget(covariant SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      widget.controller?.attach(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: _repaintKey,
      child: GestureDetector(
        onPanStart: (details) {
          final position = details.localPosition;
          setState(() {
            _strokes.add([position]);
          });
        },
        onPanUpdate: (details) {
          final position = details.localPosition;
          setState(() {
            if (_strokes.isNotEmpty) {
              final stroke = _strokes.last;
              if (stroke.isEmpty || stroke.last != position) {
                stroke.add(position);
              }
            }
          });
        },
        onPanEnd: (_) => setState(() {}),
        child: Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: CustomPaint(
            painter: _SignaturePainter(
              strokes: _strokes,
              color: widget.color,
              strokeWidth: widget.strokeWidth,
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter({
    required this.strokes,
    required this.strokeWidth,
    required this.color,
  });

  final List<List<Offset>> strokes;
  final double strokeWidth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = strokeWidth;

    for (final stroke in strokes) {
      if (stroke.length < 2) {
        canvas.drawPoints(
          ui.PointMode.points,
          stroke,
          paint,
        );
        continue;
      }
      for (var i = 1; i < stroke.length; i++) {
        canvas.drawLine(stroke[i - 1], stroke[i], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.strokes != strokes ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.color != color;
}
