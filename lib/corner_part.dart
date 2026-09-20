import 'package:flutter/material.dart';

class CornerPart extends CustomPainter {
  final Offset topL, topR, bottomL, bottomR;
  CornerPart({required this.topL, required this.topR, required this.bottomL, required this.bottomR});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.blueAccent;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;

    final cropPath = Path();
    cropPath.moveTo(topL.dx, topL.dy);
    cropPath.lineTo(topR.dx, topR.dy);
    cropPath.lineTo(bottomR.dx, bottomR.dy);
    cropPath.lineTo(bottomL.dx, bottomL.dy);
    cropPath.close();
    canvas.drawPath(cropPath, paint);
  }

  @override
  bool shouldRepaint(CornerPart cornerpart) => true;
}