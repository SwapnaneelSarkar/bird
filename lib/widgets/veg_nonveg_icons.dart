import 'package:flutter/material.dart';

class VegNonVegIcons {
  static Widget vegIcon({
    double size = 16.0,
    Color? color,
    Color? borderColor,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: VegIconPainter(
        color: color ?? const Color(0xFF3CB043),
        borderColor: borderColor ?? Colors.white,
      ),
    );
  }

  static Widget nonVegIcon({
    double size = 16.0,
    Color? color,
    Color? borderColor,
  }) {
    return CustomPaint(
      size: Size(size, size),
      painter: NonVegIconPainter(
        color: color ?? const Color(0xFFE53935),
        borderColor: borderColor ?? Colors.white,
      ),
    );
  }
}

class VegIconPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  VegIconPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15;

    // Draw outer circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, borderPaint);

    // Draw inner square
    final innerSize = size.width * 0.4;
    final innerRect = Rect.fromCenter(
      center: center,
      width: innerSize,
      height: innerSize,
    );
    
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(innerRect, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NonVegIconPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  NonVegIconPainter({
    required this.color,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15;

    // Draw outer circle
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius, borderPaint);

    // Draw inner circle
    final innerRadius = size.width * 0.25;
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, innerRadius, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 