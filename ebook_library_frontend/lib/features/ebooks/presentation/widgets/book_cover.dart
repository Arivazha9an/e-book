import 'package:flutter/material.dart';

class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.image,
    required this.accent,
    this.borderRadius = 5,
  });

  final Widget image;
  final Color accent;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        /// ----------- PAGE STACK -----------
        Positioned(
          top: 2,
          right: -2,
          bottom: 2,
          child: Container(
            width: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(borderRadius),
                bottomRight: Radius.circular(borderRadius),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey.shade100,
                  Colors.white,
                  Colors.grey.shade300,
                  Colors.grey.shade500,
                ],
              ),
            ),
          ),
        ),

        /// -------- COVER ----------
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,

              /// Left hardcover shadow
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              /// Right hardcover shadow
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.18),
                      ],
                    ),
                  ),
                ),
              ),

              /// Top light
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 2,
                  color: Colors.white.withOpacity(.28),
                ),
              ),

              /// Bottom shadow
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(.25),
                      ],
                    ),
                  ),
                ),
              ),

              /// Gloss
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(.28),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(.08),
                        ],
                        stops: const [
                          .0,
                          .25,
                          .75,
                          1,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Reflection strip
              Positioned(
                left: 12,
                top: -30,
                bottom: -30,
                child: Transform.rotate(
                  angle: -.18,
                  child: Container(
                    width: 14,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              /// Border
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.black.withOpacity(.12),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// Hardcover edge
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 2,
            decoration: BoxDecoration(
              color: accent.withOpacity(.35),
            ),
          ),
        ),
      ],
    );
  }
}
