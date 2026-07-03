import 'dart:math';
import 'package:flutter/material.dart';

class BookSpine extends StatelessWidget {
  const BookSpine({
    super.key,
    required this.title,
    required this.baseColor,
    this.width = 12,
  });

  final String title;
  final Color baseColor;
  final double width;

  Color _light(Color c, [double amount = .18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  Color _dark(Color c, [double amount = .18]) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            /// Main cloth gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _dark(baseColor, .30),
                    baseColor,
                    _light(baseColor, .10),
                    _dark(baseColor, .20),
                  ],
                  stops: const [.0, .25, .55, 1],
                ),
              ),
            ),

            /// Cloth texture
            CustomPaint(
              painter: _SpineTexturePainter(
                color: Colors.white.withOpacity(.04),
              ),
            ),

            /// Left bevel
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 1.2,
                color: Colors.white.withOpacity(.25),
              ),
            ),

            /// Right shadow
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 1.8,
                color: Colors.black.withOpacity(.18),
              ),
            ),

            /// Gold decorative bands
            Positioned(
              top: 12,
              left: 2,
              right: 2,
              child: Container(
                height: 1,
                color: const Color(0xffe6c76f),
              ),
            ),

            Positioned(
              bottom: 12,
              left: 2,
              right: 2,
              child: Container(
                height: 1,
                color: const Color(0xffe6c76f),
              ),
            ),

            /// Vertical title
            Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: width < 14 ? 7 : 8,
                      letterSpacing: .8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xfff7dd8d),
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 2,
                          offset: Offset(1, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Top shine
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                height: 1,
                color: Colors.white.withOpacity(.30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpineTexturePainter extends CustomPainter {
  const _SpineTexturePainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final random = Random(12);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    for (int i = 0; i < 120; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;

      canvas.drawCircle(
        Offset(dx, dy),
        .25,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
