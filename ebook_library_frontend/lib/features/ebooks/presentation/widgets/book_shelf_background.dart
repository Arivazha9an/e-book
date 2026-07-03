import 'dart:math';
import 'package:flutter/material.dart';

class BookshelfBackground extends StatelessWidget {
  const BookshelfBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Wooden wall
        Positioned.fill(
          child: CustomPaint(
            painter: _WoodWallPainter(),
          ),
        ),

        /// Warm top light
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(.18),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Left vignette
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withOpacity(.14),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.18),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Bottom depth
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(.18),
                  ],
                ),
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}

class _WoodWallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xffd7b07e),
          Color(0xffc89862),
          Color(0xffb67b48),
          Color(0xffa56b3e),
        ],
      ).createShader(
        Offset.zero & size,
      );

    canvas.drawRect(
      Offset.zero & size,
      base,
    );

    final random = Random(44);

    /// Vertical wood grain
    for (double x = 0; x < size.width; x += 12) {
      final path = Path();

      path.moveTo(x, 0);

      for (double y = 0; y < size.height; y += 20) {
        path.quadraticBezierTo(
          x + random.nextDouble() * 6 - 3,
          y + 10,
          x,
          y + 20,
        );
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.brown.shade900.withOpacity(.08)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }

    /// Horizontal grain
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()..color = Colors.white.withOpacity(.025),
      );
    }

    /// Wood knots
    final knot = Paint()..color = Colors.brown.shade900.withOpacity(.09);

    for (int i = 0; i < 30; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(dx, dy),
          width: random.nextDouble() * 20 + 8,
          height: random.nextDouble() * 8 + 4,
        ),
        knot,
      );
    }

    /// Fine noise
    final noise = Paint()..color = Colors.white.withOpacity(.02);

    for (int i = 0; i < 3500; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .35,
        noise,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
