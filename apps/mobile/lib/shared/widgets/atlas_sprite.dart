import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AtlasSprite extends StatelessWidget {
  const AtlasSprite({
    super.key,
    required this.asset,
    required this.frame,
    this.label,
  });
  final String asset;
  final int frame;
  final String? label;
  static final _cache = <String, Future<ui.Image>>{};
  static Future<ui.Image> _load(String name) =>
      _cache.putIfAbsent(name, () async {
        final data = await rootBundle.load(name);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final decoded = await codec.getNextFrame();
        codec.dispose();
        return decoded.image;
      });
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: FutureBuilder<ui.Image>(
      future: _load(asset),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.expand();
        return SizedBox.expand(
          child: CustomPaint(painter: _SpritePainter(snapshot.data!, frame)),
        );
      },
    ),
  );
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.image, this.frame);
  final ui.Image image;
  final int frame;
  @override
  void paint(Canvas canvas, Size size) {
    final w = image.width / 3, h = image.height / 2;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH((frame % 3) * w, (frame ~/ 3) * h, w, h),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.frame != frame || old.image != image;
}
