import 'dart:math';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_cover.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_lift_animation.dart';
import 'package:ebook_library_frontend/features/ebooks/presentation/widgets/book_spine.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/ebook.dart';

class RealisticBookTile extends StatefulWidget {
  const RealisticBookTile({
    super.key,
    required this.ebook,
    required this.onTap,
    this.onLongPress,
    this.isBusy = false,
  });

  final Ebook ebook;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isBusy;

  @override
  State<RealisticBookTile> createState() => _RealisticBookTileState();
}

class _RealisticBookTileState extends State<RealisticBookTile>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  late Animation<double> scale;
  late Animation<double> rotate;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 170),
    );

    scale = Tween(
      begin: 1.0,
      end: .96,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );

    rotate = Tween<double>(
      begin: 0,
      end: -.04,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Color _generateColor() {
    final random = Random(widget.ebook.id);

    return HSVColor.fromAHSV(
      1,
      random.nextDouble() * 360,
      .45,
      .75,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final spine = _generateColor();

    return BookLiftAnimation(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: controller,
        builder: (_, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0015)
              ..rotateY(rotate.value),
            child: Transform.scale(
              scale: scale.value,
              child: child,
            ),
          );
        },
        child: Hero(
          tag: "book_${widget.ebook.id}",
          child: SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                /// Main shadow
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(
                      left: 8,
                      top: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 18,
                          spreadRadius: 1,
                          offset: const Offset(8, 12),
                          color: Colors.black.withOpacity(.38),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Contact shadow
                Positioned(
                  bottom: -4,
                  left: 10,
                  right: 6,
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 12,
                          spreadRadius: 2,
                          color: Colors.black.withOpacity(.45),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        /// Spine
                        BookSpine(
                          title: widget.ebook.title,
                          baseColor: spine,
                          width: 12,
                        ),

                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              color: Colors.grey.shade200,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(.6),
                                  offset: const Offset(-1, 0),
                                ),
                              ],
                            ),
                            child: BookCover(
                              accent: spine,
                              image: widget.ebook.coverUrl != null
                                  ? Image.network(
                                      widget.ebook.coverUrl!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: spine,
                                      alignment: Alignment.center,
                                      child: RepaintBoundary(
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Text(
                                            widget.ebook.title,
                                            textAlign: TextAlign.center,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),

                        /// Right edge thickness
                        Container(
                          width: 3,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.grey.shade300,
                                Colors.grey.shade500,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
