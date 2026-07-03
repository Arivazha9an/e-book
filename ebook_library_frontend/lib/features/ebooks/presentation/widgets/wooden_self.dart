import 'dart:math';
import 'package:flutter/material.dart';

class WoodenShelf extends StatelessWidget {
  const WoodenShelf({
    super.key,
    required this.child,
    this.height = 190,
  });

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 36,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          /// Background shadow
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 26,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    blurRadius: 24,
                    spreadRadius: 4,
                    offset: const Offset(0, 12),
                    color: Colors.black.withOpacity(.45),
                  )
                ],
              ),
            ),
          ),

          /// Books
          Positioned(
            left: 18,
            right: 18,
            bottom: 22,
            child: child,
          ),

          /// Shelf
          const _ShelfBoard(),
        ],
      ),
    );
  }
}

class _ShelfBoard extends StatelessWidget {
  const _ShelfBoard();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          /// Main board
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xffb77b47),
                    Color(0xff996338),
                    Color(0xff7b4b24),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          /// Wood texture
          Positioned.fill(
            child: CustomPaint(
              painter: _WoodPainter(),
            ),
          ),

          /// Top polish
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(.45),
                    Colors.white.withOpacity(.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          /// Bottom bevel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(.45),
                  ],
                ),
              ),
            ),
          ),

          /// Front highlight
          Positioned(
            left: 0,
            right: 0,
            top: 7,
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _WoodPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(42);

    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double y = 2; y < size.height; y += 2.5) {
      paint.color = Colors.brown.shade900.withOpacity(.10);

      final path = Path();

      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 20) {
        path.quadraticBezierTo(
          x + 8,
          y + random.nextDouble() * 2 - 1,
          x + 20,
          y,
        );
      }

      canvas.drawPath(path, paint);
    }

    final knotPaint = Paint()..color = Colors.brown.shade900.withOpacity(.08);

    for (int i = 0; i < 8; i++) {
      final dx = random.nextDouble() * size.width;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx, size.height / 2),
          width: 18,
          height: 8,
        ),
        knotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
