// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';

// Balloon Widget
class Balloon extends StatelessWidget {
  final String text;
  final Color color;
  final EdgeInsetsGeometry padding;

  const Balloon({
    Key? key,
    required this.text,
    this.color = Colors.blue,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BalloonPainter(color: color),
      child: Padding(
        padding: padding,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Balloon Shape
class BalloonPainter extends CustomPainter {
  final Color color;

  BalloonPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()..color = color;

    Path path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(10)))
      ..moveTo(size.width - 30, size.height)
      ..lineTo(size.width - 15, size.height + 10)
      ..lineTo(size.width - 20, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
