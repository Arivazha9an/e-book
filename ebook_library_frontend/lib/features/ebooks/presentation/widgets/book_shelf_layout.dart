import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/entities/ebook.dart';
import 'realistic_book_tile.dart';

class BookshelfLayout extends StatelessWidget {
  const BookshelfLayout({
    super.key,
    required this.books,
    required this.busyIds,
    required this.onTap,
    required this.onLongPress,
  });

  final List<Ebook> books;
  final Set<int> busyIds;
  final ValueChanged<Ebook> onTap;
  final ValueChanged<Ebook> onLongPress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: books
            .map(
              (book) => _NaturalBook(
                ebook: book,
                isBusy: busyIds.contains(book.id),
                onTap: () => onTap(book),
                onLongPress: () => onLongPress(book),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NaturalBook extends StatelessWidget {
  const _NaturalBook({
    required this.ebook,
    required this.onTap,
    required this.onLongPress,
    required this.isBusy,
  });

  final Ebook ebook;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final random = Random(ebook.id);

    final height = 175.0 + random.nextInt(40);

    final width = 82.0 + random.nextInt(18);

    final rotation = ((random.nextDouble() * 4) - 2) * pi / 180;

    final spacing = 2 + random.nextDouble() * 4;

    final translateY = random.nextDouble() * 6;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing),
      child: Transform.translate(
        offset: Offset(0, translateY),
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..rotateZ(rotation),
          child: SizedBox(
            width: width,
            height: height,
            child: RealisticBookTile(
              ebook: ebook,
              isBusy: isBusy,
              onTap: onTap,
              onLongPress: onLongPress,
            ),
          ),
        ),
      ),
    );
  }
}
