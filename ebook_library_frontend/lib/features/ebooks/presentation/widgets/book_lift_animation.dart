import 'package:flutter/material.dart';

class BookLiftAnimation extends StatefulWidget {
  const BookLiftAnimation({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<BookLiftAnimation> createState() => _BookLiftAnimationState();
}

class _BookLiftAnimationState extends State<BookLiftAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double> _lift;
  late final Animation<double> _rotateX;
  late final Animation<double> _rotateY;
  late final Animation<double> _scale;
  late final Animation<double> _shadow;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _lift = Tween(begin: 0.0, end: -24.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _rotateX = Tween(begin: 0.0, end: -.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _rotateY = Tween(begin: 0.0, end: -.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scale = Tween(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _shadow = Tween(begin: .25, end: .55).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  Future<void> _animate() async {
    await _controller.forward();

    widget.onTap();

    await Future.delayed(const Duration(milliseconds: 100));

    if (mounted) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _animate,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, child) {
          return Transform.translate(
            offset: Offset(0, _lift.value),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateX(_rotateX.value)
                ..rotateY(_rotateY.value),
              child: Transform.scale(
                scale: _scale.value,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(_shadow.value),
                        blurRadius: 30,
                        spreadRadius: 6,
                        offset: const Offset(0, 22),
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
            ),
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
